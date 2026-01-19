//! Matrix server integration for automatic account creation
//! Uses Dendrite's Synapse-compatible admin API

use hmac::{Hmac, Mac};
use sha1::Sha1;
use serde::{Deserialize, Serialize};

type HmacSha1 = Hmac<Sha1>;

/// Configuration for Matrix server connection
#[derive(Clone)]
pub struct MatrixConfig {
    /// Matrix homeserver URL (e.g., http://localhost:8008)
    pub homeserver_url: String,
    /// Server name for Matrix IDs (e.g., localhost, kinu.chat)
    pub server_name: String,
    /// Shared secret for admin registration API
    pub registration_secret: String,
}

impl MatrixConfig {
    pub fn from_env() -> Self {
        Self {
            homeserver_url: std::env::var("MATRIX_HOMESERVER_URL")
                .unwrap_or_else(|_| "http://localhost:8008".to_string()),
            server_name: std::env::var("MATRIX_SERVER_NAME")
                .unwrap_or_else(|_| "localhost".to_string()),
            registration_secret: std::env::var("MATRIX_REGISTRATION_SECRET")
                .unwrap_or_else(|_| "kinu-dev-secret-change-in-prod".to_string()),
        }
    }

    /// Convert a handle to a Matrix user ID
    pub fn handle_to_matrix_id(&self, handle: &str) -> String {
        format!("@{}:{}", handle.to_lowercase(), self.server_name)
    }
}

/// Matrix service for account management
pub struct MatrixService {
    config: MatrixConfig,
    client: reqwest::Client,
}

impl MatrixService {
    pub fn new(config: MatrixConfig) -> Self {
        Self {
            config,
            client: reqwest::Client::new(),
        }
    }

    /// Register a new Matrix account using the admin API
    /// This uses the Synapse-compatible /_synapse/admin/v1/register endpoint
    pub async fn register_account(
        &self,
        username: &str,
        password: &str,
    ) -> Result<MatrixRegistrationResponse, MatrixError> {
        let url = format!(
            "{}/_synapse/admin/v1/register",
            self.config.homeserver_url
        );

        // Step 1: Get a nonce from the server
        let nonce_response: NonceResponse = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| MatrixError::NetworkError(e.to_string()))?
            .json()
            .await
            .map_err(|e| MatrixError::ParseError(e.to_string()))?;

        // Step 2: Generate HMAC for the registration request
        // The HMAC is computed over: nonce + "\x00" + username + "\x00" + password + "\x00" + "notadmin"
        let mac = self.generate_registration_mac(
            &nonce_response.nonce,
            username,
            password,
            false, // not admin
        )?;

        // Step 3: Submit the registration
        let request = AdminRegisterRequest {
            nonce: nonce_response.nonce,
            username: username.to_string(),
            password: password.to_string(),
            displayname: None, // Will use username
            admin: false,
            mac,
        };

        let response = self
            .client
            .post(&url)
            .json(&request)
            .send()
            .await
            .map_err(|e| MatrixError::NetworkError(e.to_string()))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();

            // Check if user already exists
            if error_text.contains("User ID already taken") || error_text.contains("already exists") {
                return Err(MatrixError::UserExists);
            }

            return Err(MatrixError::RegistrationFailed(format!(
                "Status {}: {}",
                status, error_text
            )));
        }

        response
            .json()
            .await
            .map_err(|e| MatrixError::ParseError(e.to_string()))
    }

    /// Delete/deactivate a Matrix account using the admin API
    /// Note: Dendrite may not fully support deactivation, so we log errors but don't fail
    pub async fn delete_account(&self, username: &str) -> Result<(), MatrixError> {
        let user_id = format!("@{}:{}", username.to_lowercase(), self.config.server_name);
        let url = format!(
            "{}/_synapse/admin/v1/deactivate/{}",
            self.config.homeserver_url,
            urlencoding::encode(&user_id)
        );

        // Deactivation request requires erase flag
        let request = serde_json::json!({
            "erase": true
        });

        let response = self
            .client
            .post(&url)
            .header("Authorization", format!("Bearer {}", self.config.registration_secret))
            .json(&request)
            .send()
            .await
            .map_err(|e| MatrixError::NetworkError(e.to_string()))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            tracing::warn!(
                "Matrix account deactivation failed for {}: {} - {}",
                user_id, status, error_text
            );
            // Don't fail - account deletion in Kinu is still valid
        }

        Ok(())
    }

    /// Generate HMAC for admin registration
    fn generate_registration_mac(
        &self,
        nonce: &str,
        username: &str,
        password: &str,
        admin: bool,
    ) -> Result<String, MatrixError> {
        let admin_str = if admin { "admin" } else { "notadmin" };

        // Build the string to sign: nonce\0username\0password\0admin
        let message = format!(
            "{}\x00{}\x00{}\x00{}",
            nonce, username, password, admin_str
        );

        let mut mac = HmacSha1::new_from_slice(self.config.registration_secret.as_bytes())
            .map_err(|e| MatrixError::CryptoError(e.to_string()))?;

        mac.update(message.as_bytes());
        let result = mac.finalize();

        Ok(hex::encode(result.into_bytes()))
    }
}

#[derive(Debug, Deserialize)]
struct NonceResponse {
    nonce: String,
}

#[derive(Debug, Serialize)]
struct AdminRegisterRequest {
    nonce: String,
    username: String,
    password: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    displayname: Option<String>,
    admin: bool,
    mac: String,
}

#[derive(Debug, Deserialize)]
pub struct MatrixRegistrationResponse {
    pub access_token: String,
    pub user_id: String,
    pub device_id: String,
    pub home_server: Option<String>,
}

#[derive(Debug, thiserror::Error)]
pub enum MatrixError {
    #[error("Network error: {0}")]
    NetworkError(String),

    #[error("Parse error: {0}")]
    ParseError(String),

    #[error("Registration failed: {0}")]
    RegistrationFailed(String),

    #[error("User already exists")]
    UserExists,

    #[error("Crypto error: {0}")]
    CryptoError(String),
}
