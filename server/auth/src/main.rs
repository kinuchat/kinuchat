use std::sync::Arc;

use axum::{
    routing::{delete, get, post},
    Router,
};
use sqlx::sqlite::SqlitePoolOptions;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use webauthn_rs::prelude::*;

mod crypto;
mod db;
mod email;
mod matrix;
mod models;
mod routes;

use email::{EmailConfig, EmailService};
use matrix::{MatrixConfig, MatrixService};
use routes::{accounts, devices, passkey, recovery, totp};

/// Application state shared across all routes
pub struct AppState {
    pub db: sqlx::SqlitePool,
    pub webauthn: Webauthn,
    pub jwt_secret: String,
    pub email_encryption_key: [u8; 32],
    pub matrix_service: MatrixService,
    pub matrix_config: MatrixConfig,
    pub email_service: Option<EmailService>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Load environment variables from .env file
    dotenvy::dotenv().ok();

    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "meshlink_auth=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Database connection (SQLite for local dev)
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:./kinu_auth.db?mode=rwc".to_string());

    let db = SqlitePoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    // Create tables if they don't exist
    init_database(&db).await?;

    // WebAuthn configuration
    let rp_id = std::env::var("WEBAUTHN_RP_ID").unwrap_or_else(|_| "meshlink.app".to_string());
    let rp_origin = std::env::var("WEBAUTHN_RP_ORIGIN")
        .unwrap_or_else(|_| "https://meshlink.app".to_string());
    let rp_origin = Url::parse(&rp_origin)?;

    let webauthn = WebauthnBuilder::new(&rp_id, &rp_origin)?
        .rp_name("MeshLink")
        .build()?;

    // JWT secret
    let jwt_secret =
        std::env::var("JWT_SECRET").unwrap_or_else(|_| "development-secret-change-in-prod".to_string());

    // Email encryption key (derived from environment variable)
    let email_key_str = std::env::var("EMAIL_ENCRYPTION_KEY")
        .unwrap_or_else(|_| "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef".to_string());
    let email_encryption_key = hex_to_key(&email_key_str)?;

    // Matrix server configuration
    let matrix_config = MatrixConfig::from_env();
    tracing::info!(
        "Matrix integration enabled: {} (server: {})",
        matrix_config.homeserver_url,
        matrix_config.server_name
    );
    let matrix_service = MatrixService::new(matrix_config.clone());

    // Email service configuration (optional)
    let email_service = match EmailConfig::from_env() {
        Some(config) => {
            match EmailService::new(config) {
                Ok(service) => {
                    tracing::info!("Email service configured and ready");
                    Some(service)
                }
                Err(e) => {
                    tracing::warn!("Failed to initialize email service: {}. Email features will be disabled.", e);
                    None
                }
            }
        }
        None => {
            tracing::info!("Email service not configured (SMTP_HOST not set). Email features disabled.");
            None
        }
    };

    let state = Arc::new(AppState {
        db,
        webauthn,
        jwt_secret,
        email_encryption_key,
        matrix_service,
        matrix_config,
        email_service,
    });

    // Build router
    let app = Router::new()
        // Health check
        .route("/health", get(health_check))
        // Account routes
        .route("/api/v1/accounts/register", post(accounts::register))
        .route("/api/v1/accounts/login", post(accounts::login))
        .route("/api/v1/accounts/check-handle", get(accounts::check_handle))
        .route("/api/v1/accounts/me", get(accounts::get_current_account))
        .route("/api/v1/accounts/me", post(accounts::update_account))
        .route("/api/v1/accounts/me", delete(accounts::delete_account))
        .route("/api/v1/accounts/change-password", post(accounts::change_password))
        .route("/api/v1/accounts/update-email", post(accounts::update_email))
        .route("/api/v1/accounts/resend-verification", post(accounts::resend_verification))
        .route("/api/v1/accounts/verify-email", post(accounts::verify_email))
        .route("/api/v1/accounts/export", get(accounts::export_data))
        .route("/api/v1/accounts/email", delete(accounts::remove_email))
        // Device routes
        .route("/api/v1/devices", get(devices::list_devices))
        .route("/api/v1/devices/{id}", delete(devices::revoke_device))
        .route("/api/v1/devices/revoke-all", post(devices::revoke_all_devices))
        // Passkey routes
        .route(
            "/api/v1/passkey/register/start",
            post(passkey::start_registration),
        )
        .route(
            "/api/v1/passkey/register/finish",
            post(passkey::finish_registration),
        )
        .route(
            "/api/v1/passkey/authenticate/start",
            post(passkey::start_authentication),
        )
        .route(
            "/api/v1/passkey/authenticate/finish",
            post(passkey::finish_authentication),
        )
        // Recovery routes
        .route("/api/v1/recovery/request", post(recovery::request_recovery))
        .route("/api/v1/recovery/verify", post(recovery::verify_recovery))
        .route("/api/v1/recovery/reset", post(recovery::reset_account))
        // TOTP routes
        .route("/api/v1/2fa/setup", post(totp::setup_totp))
        .route("/api/v1/2fa/verify", post(totp::verify_totp))
        .route("/api/v1/2fa/disable", post(totp::disable_totp))
        .route("/api/v1/2fa/backup-codes", get(totp::get_backup_codes))
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
    let addr = std::env::var("LISTEN_ADDR").unwrap_or_else(|_| "0.0.0.0:3000".to_string());
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!("Kinu Auth Service listening on {}", addr);

    axum::serve(listener, app).await?;

    Ok(())
}

async fn health_check() -> &'static str {
    "OK"
}

/// Initialize SQLite database with tables
async fn init_database(pool: &sqlx::SqlitePool) -> anyhow::Result<()> {
    sqlx::query(r#"
        CREATE TABLE IF NOT EXISTS accounts (
            id TEXT PRIMARY KEY,
            handle TEXT NOT NULL UNIQUE,
            display_name TEXT NOT NULL,
            passkey_credential_id TEXT,
            passkey_public_key BLOB,
            password_hash TEXT,
            encrypted_email BLOB,
            email_nonce BLOB,
            email_verified INTEGER NOT NULL DEFAULT 0,
            totp_secret_encrypted BLOB,
            totp_secret_nonce BLOB,
            totp_enabled INTEGER NOT NULL DEFAULT 0,
            backup_codes_hash TEXT,
            encrypted_key_backup BLOB,
            key_backup_nonce BLOB,
            created_at TEXT NOT NULL,
            last_login_at TEXT
        )
    "#)
    .execute(pool)
    .await?;

    sqlx::query(r#"
        CREATE TABLE IF NOT EXISTS recovery_tokens (
            id TEXT PRIMARY KEY,
            account_id TEXT NOT NULL,
            token_hash TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            used INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        )
    "#)
    .execute(pool)
    .await?;

    sqlx::query(r#"
        CREATE TABLE IF NOT EXISTS devices (
            id TEXT PRIMARY KEY,
            account_id TEXT NOT NULL,
            name TEXT NOT NULL,
            platform TEXT NOT NULL,
            last_seen_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        )
    "#)
    .execute(pool)
    .await?;

    sqlx::query(r#"
        CREATE TABLE IF NOT EXISTS email_verification_tokens (
            id TEXT PRIMARY KEY,
            account_id TEXT NOT NULL,
            token_hash TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        )
    "#)
    .execute(pool)
    .await?;

    // Create indexes
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_accounts_handle ON accounts(handle)")
        .execute(pool)
        .await?;
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_devices_account ON devices(account_id)")
        .execute(pool)
        .await?;
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_recovery_account ON recovery_tokens(account_id)")
        .execute(pool)
        .await?;
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_email_verification_account ON email_verification_tokens(account_id)")
        .execute(pool)
        .await?;

    Ok(())
}

fn hex_to_key(hex: &str) -> anyhow::Result<[u8; 32]> {
    let bytes = hex::decode(hex)?;
    if bytes.len() != 32 {
        anyhow::bail!("Email encryption key must be 32 bytes (64 hex chars)");
    }
    let mut key = [0u8; 32];
    key.copy_from_slice(&bytes);
    Ok(key)
}
