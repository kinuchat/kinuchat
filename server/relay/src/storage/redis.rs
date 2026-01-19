use redis::aio::MultiplexedConnection;
use redis::AsyncCommands;
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::models::{RelayEnvelope, StoredEnvelope};

/// Redis key prefixes
const MSG_PREFIX: &str = "relay:msg:";
const QUEUE_PREFIX: &str = "relay:queue:";
const RATE_PREFIX: &str = "relay:rate:";
const NONCE_PREFIX: &str = "relay:nonce:";

/// Redis storage layer for relay messages
#[derive(Clone)]
pub struct RedisStorage {
    conn: Arc<RwLock<MultiplexedConnection>>,
}

impl RedisStorage {
    /// Create a new Redis storage connection
    pub async fn new(redis_url: &str) -> anyhow::Result<Self> {
        let client = redis::Client::open(redis_url)?;
        let conn = client.get_multiplexed_async_connection().await?;
        Ok(Self {
            conn: Arc::new(RwLock::new(conn)),
        })
    }

    /// Store a message envelope
    ///
    /// Returns the message ID and expiration timestamp
    pub async fn store_message(
        &self,
        envelope: RelayEnvelope,
    ) -> anyhow::Result<(String, i64)> {
        let mut conn = self.conn.write().await;

        // Check for duplicate nonce (prevent replay attacks)
        let nonce_key = format!("{}{}", NONCE_PREFIX, envelope.nonce);
        let exists: bool = conn.exists(&nonce_key).await?;
        if exists {
            anyhow::bail!("Duplicate nonce - message already submitted");
        }

        // Generate unique message ID
        let msg_id = uuid::Uuid::new_v4().to_string();

        // Calculate expiration
        let ttl_seconds = (envelope.ttl_hours as i64) * 3600;
        let stored_at = chrono::Utc::now().timestamp_millis();
        let expires_at = stored_at + (ttl_seconds * 1000);

        // Create stored envelope
        let stored = StoredEnvelope {
            id: msg_id.clone(),
            envelope: envelope.clone(),
            stored_at,
        };

        // Store the message JSON
        let msg_key = format!("{}{}", MSG_PREFIX, msg_id);
        let json = serde_json::to_string(&stored)?;
        conn.set_ex::<_, _, ()>(&msg_key, &json, ttl_seconds as u64).await?;

        // Add to recipient's queue (sorted set by timestamp)
        let queue_key = format!("{}{}", QUEUE_PREFIX, envelope.recipient_key_hash);
        conn.zadd::<_, _, _, ()>(&queue_key, &msg_id, stored_at as f64).await?;

        // Set queue expiration (extend on each new message)
        conn.expire::<_, ()>(&queue_key, ttl_seconds).await?;

        // Mark nonce as used (same TTL as message)
        conn.set_ex::<_, _, ()>(&nonce_key, "1", ttl_seconds as u64).await?;

        tracing::debug!(
            msg_id = %msg_id,
            recipient = %envelope.recipient_key_hash,
            ttl_hours = envelope.ttl_hours,
            "Stored relay message"
        );

        Ok((msg_id, expires_at))
    }

    /// Poll for messages for a recipient
    pub async fn poll_messages(
        &self,
        key_hash: &str,
        limit: u32,
        after: Option<&str>,
    ) -> anyhow::Result<(Vec<StoredEnvelope>, bool)> {
        let mut conn = self.conn.write().await;
        let queue_key = format!("{}{}", QUEUE_PREFIX, key_hash);

        // Get starting score (timestamp) if cursor provided
        let min_score = if let Some(after_id) = after {
            // Get the score of the cursor message
            let score: Option<f64> = conn.zscore(&queue_key, after_id).await?;
            match score {
                Some(s) => format!("({}", s), // Exclusive of the cursor
                None => "-inf".to_string(),
            }
        } else {
            "-inf".to_string()
        };

        // Get message IDs from sorted set (oldest first)
        let msg_ids: Vec<String> = conn
            .zrangebyscore_limit(&queue_key, &min_score, "+inf", 0, (limit + 1) as isize)
            .await?;

        let has_more = msg_ids.len() > limit as usize;
        let msg_ids: Vec<String> = msg_ids.into_iter().take(limit as usize).collect();

        // Fetch each message
        let mut messages = Vec::with_capacity(msg_ids.len());
        for msg_id in &msg_ids {
            let msg_key = format!("{}{}", MSG_PREFIX, msg_id);
            let json: Option<String> = conn.get(&msg_key).await?;
            if let Some(json) = json {
                match serde_json::from_str::<StoredEnvelope>(&json) {
                    Ok(envelope) => messages.push(envelope),
                    Err(e) => {
                        tracing::warn!(msg_id = %msg_id, error = %e, "Failed to parse stored envelope");
                        // Clean up corrupted entry
                        conn.zrem::<_, _, ()>(&queue_key, msg_id).await?;
                    }
                }
            } else {
                // Message expired, remove from queue
                conn.zrem::<_, _, ()>(&queue_key, msg_id).await?;
            }
        }

        Ok((messages, has_more))
    }

    /// Delete messages after acknowledgment
    pub async fn delete_messages(
        &self,
        key_hash: &str,
        message_ids: &[String],
    ) -> anyhow::Result<usize> {
        if message_ids.is_empty() {
            return Ok(0);
        }

        let mut conn = self.conn.write().await;
        let queue_key = format!("{}{}", QUEUE_PREFIX, key_hash);

        let mut deleted = 0;
        for msg_id in message_ids {
            // Remove from queue
            let removed: i32 = conn.zrem(&queue_key, msg_id).await?;
            if removed > 0 {
                deleted += 1;
                // Delete message data
                let msg_key = format!("{}{}", MSG_PREFIX, msg_id);
                conn.del::<_, ()>(&msg_key).await?;
            }
        }

        tracing::debug!(
            recipient = %key_hash,
            deleted = deleted,
            requested = message_ids.len(),
            "Deleted relay messages"
        );

        Ok(deleted)
    }

    /// Check and update rate limit
    ///
    /// Returns (allowed, remaining, reset_at)
    pub async fn check_rate_limit(
        &self,
        key_hash: &str,
        limit: u32,
    ) -> anyhow::Result<(bool, u32, i64)> {
        let mut conn = self.conn.write().await;
        let rate_key = format!("{}{}", RATE_PREFIX, key_hash);

        // Get current count
        let count: Option<u32> = conn.get(&rate_key).await?;
        let current = count.unwrap_or(0);

        // Calculate reset time (next minute boundary)
        let now = chrono::Utc::now();
        let reset_at = (now.timestamp() / 60 + 1) * 60 * 1000; // Next minute in ms

        if current >= limit {
            return Ok((false, 0, reset_at));
        }

        // Increment counter
        let new_count: u32 = conn.incr(&rate_key, 1).await?;

        // Set expiration on first increment
        if new_count == 1 {
            conn.expire::<_, ()>(&rate_key, 60).await?;
        }

        let remaining = limit.saturating_sub(new_count);
        Ok((true, remaining, reset_at))
    }

    /// Get count of pending messages for a recipient
    pub async fn get_pending_count(&self, key_hash: &str) -> anyhow::Result<u64> {
        let mut conn = self.conn.write().await;
        let queue_key = format!("{}{}", QUEUE_PREFIX, key_hash);
        let count: u64 = conn.zcard(&queue_key).await?;
        Ok(count)
    }

    /// Health check - ping Redis
    pub async fn ping(&self) -> anyhow::Result<()> {
        let mut conn = self.conn.write().await;
        redis::cmd("PING").query_async(&mut *conn).await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Integration tests require a running Redis instance
    // Run with: REDIS_URL=redis://localhost:6379 cargo test
}
