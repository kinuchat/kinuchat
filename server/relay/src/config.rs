/// Server configuration
#[derive(Debug, Clone)]
pub struct Config {
    /// Listen address (e.g., "0.0.0.0:3001")
    pub listen_addr: String,

    /// Redis connection URL
    pub redis_url: String,

    /// Maximum message TTL in hours
    pub max_ttl_hours: u32,

    /// Default message TTL in hours
    pub default_ttl_hours: u32,

    /// Maximum payload size in bytes
    pub max_payload_bytes: usize,

    /// Rate limit: messages per minute per key hash
    pub rate_limit_per_minute: u32,

    /// Maximum concurrent WebSocket connections
    pub max_ws_connections: usize,
}

impl Config {
    /// Load configuration from environment variables
    pub fn from_env() -> Self {
        Self {
            listen_addr: std::env::var("LISTEN_ADDR")
                .unwrap_or_else(|_| "0.0.0.0:3001".to_string()),

            redis_url: std::env::var("REDIS_URL")
                .unwrap_or_else(|_| "redis://127.0.0.1:6379".to_string()),

            max_ttl_hours: std::env::var("MAX_TTL_HOURS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(24),

            default_ttl_hours: std::env::var("DEFAULT_TTL_HOURS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(4),

            max_payload_bytes: std::env::var("MAX_PAYLOAD_BYTES")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(65536), // 64KB

            rate_limit_per_minute: std::env::var("RATE_LIMIT_PER_MINUTE")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(60),

            max_ws_connections: std::env::var("MAX_WS_CONNECTIONS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(10000),
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self::from_env()
    }
}
