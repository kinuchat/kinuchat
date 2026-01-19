use serde::{Deserialize, Serialize};
use validator::Validate;

/// Priority levels for relay messages
#[derive(Debug, Clone, Copy, Serialize, Deserialize, Default, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Priority {
    #[default]
    Normal,
    Urgent,
    Emergency,
}

/// Relay envelope format for encrypted messages
#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct RelayEnvelope {
    /// SHA256 hash of recipient's X25519 public key (base64)
    #[validate(length(min = 1, max = 64))]
    pub recipient_key_hash: String,

    /// Noise-encrypted packet payload (base64)
    #[validate(length(min = 1, max = 65536))] // 64KB max payload
    pub encrypted_payload: String,

    /// Time-to-live in hours (default 4, max 24)
    #[validate(range(min = 1, max = 24))]
    #[serde(default = "default_ttl")]
    pub ttl_hours: u32,

    /// Message priority
    #[serde(default)]
    pub priority: Priority,

    /// Deduplication nonce (base64, typically random 16 bytes)
    #[validate(length(min = 1, max = 32))]
    pub nonce: String,

    /// Unix timestamp in milliseconds when message was created
    pub created_at: i64,
}

fn default_ttl() -> u32 {
    4
}

/// Stored envelope with server-assigned ID
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredEnvelope {
    /// Server-assigned unique ID
    pub id: String,

    /// The original envelope
    #[serde(flatten)]
    pub envelope: RelayEnvelope,

    /// Unix timestamp when stored on server
    pub stored_at: i64,
}

/// Upload request
#[derive(Debug, Deserialize, Validate)]
pub struct UploadRequest {
    #[validate(nested)]
    pub envelope: RelayEnvelope,
}

/// Upload response
#[derive(Debug, Serialize)]
pub struct UploadResponse {
    pub id: String,
    pub expires_at: i64,
}

/// Poll request query parameters
#[derive(Debug, Deserialize, Validate)]
pub struct PollQuery {
    /// Recipient's key hash to poll for
    #[validate(length(min = 1, max = 64))]
    pub key_hash: String,

    /// Maximum number of messages to return (default 10, max 50)
    #[validate(range(min = 1, max = 50))]
    #[serde(default = "default_limit")]
    pub limit: u32,

    /// Optional cursor for pagination (message ID)
    pub after: Option<String>,
}

fn default_limit() -> u32 {
    10
}

/// Poll response
#[derive(Debug, Serialize)]
pub struct PollResponse {
    pub messages: Vec<StoredEnvelope>,
    pub has_more: bool,
    pub next_cursor: Option<String>,
}

/// Acknowledge messages request
#[derive(Debug, Deserialize, Validate)]
pub struct AckRequest {
    /// Message IDs to acknowledge/delete
    #[validate(length(min = 1, max = 50))]
    pub message_ids: Vec<String>,

    /// Key hash of the recipient (for verification)
    #[validate(length(min = 1, max = 64))]
    pub key_hash: String,
}

/// Acknowledge response
#[derive(Debug, Serialize)]
pub struct AckResponse {
    pub deleted: usize,
}

/// WebSocket message types
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum WsMessage {
    /// Client subscribes to receive messages for a key hash
    Subscribe { key_hash: String },

    /// Server confirms subscription
    Subscribed { key_hash: String },

    /// Server pushes a new message
    NewMessage { envelope: StoredEnvelope },

    /// Client acknowledges receipt of messages
    Ack { message_ids: Vec<String> },

    /// Server confirms acknowledgment
    Acked { deleted: usize },

    /// Ping/pong for keepalive
    Ping,
    Pong,

    /// Error message
    Error { message: String },
}

/// Rate limit info
#[derive(Debug, Clone, Serialize)]
pub struct RateLimitInfo {
    pub remaining: u32,
    pub reset_at: i64,
}
