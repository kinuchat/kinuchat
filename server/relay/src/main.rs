use std::sync::Arc;

use axum::{
    routing::{get, post},
    Router,
};
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod config;
mod models;
mod routes;
mod storage;

use config::Config;
use storage::RedisStorage;

/// Application state shared across all routes
#[derive(Clone)]
pub struct AppState {
    pub storage: RedisStorage,
    pub config: Arc<Config>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Load environment variables from .env file
    dotenvy::dotenv().ok();

    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "kinu_relay=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = Config::from_env();
    tracing::info!(
        listen_addr = %config.listen_addr,
        redis_url = %config.redis_url,
        max_ttl_hours = config.max_ttl_hours,
        rate_limit = config.rate_limit_per_minute,
        "Kinu Relay Server starting"
    );

    // Connect to Redis
    let storage = RedisStorage::new(&config.redis_url).await?;
    tracing::info!("Connected to Redis");

    // Verify Redis connection
    storage.ping().await?;
    tracing::info!("Redis ping successful");

    let state = AppState {
        storage,
        config: Arc::new(config.clone()),
    };

    // Build router
    let app = Router::new()
        // Health check
        .route("/health", get(health_check))
        // Relay routes
        .route("/relay/upload", post(routes::upload))
        .route("/relay/poll", get(routes::poll))
        .route("/relay/ack", post(routes::ack))
        .route("/relay/pending", get(routes::pending_count))
        .route("/relay/ws", get(routes::ws_handler))
        // Middleware
        .layer(TraceLayer::new_for_http())
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
        .with_state(state);

    // Start server
    let listener = tokio::net::TcpListener::bind(&config.listen_addr).await?;
    tracing::info!("Kinu Relay Server listening on {}", config.listen_addr);

    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> &'static str {
    "OK"
}
