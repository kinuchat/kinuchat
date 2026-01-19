use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use validator::Validate;

/// Account record stored in database
/// Note: Uses String types for SQLite compatibility
#[derive(Debug, Clone, FromRow)]
pub struct Account {
    pub id: String,  // UUID as string for SQLite
    pub handle: String,
    pub display_name: String,

    // Passkey (WebAuthn)
    pub passkey_credential_id: Option<String>,
    pub passkey_public_key: Option<Vec<u8>>,

    // Password fallback (Argon2id hash)
    pub password_hash: Option<String>,

    // Recovery email (encrypted with user's password-derived key)
    pub encrypted_email: Option<Vec<u8>>,
    pub email_nonce: Option<Vec<u8>>,
    pub email_verified: bool,

    // 2FA
    pub totp_secret_encrypted: Option<Vec<u8>>,
    pub totp_secret_nonce: Option<Vec<u8>>,
    pub totp_enabled: bool,
    pub backup_codes_hash: Option<String>,  // JSON string for SQLite

    // Encrypted key backup (for password users)
    pub encrypted_key_backup: Option<Vec<u8>>,
    pub key_backup_nonce: Option<Vec<u8>>,

    // Metadata
    pub created_at: String,  // ISO 8601 string for SQLite
    pub last_login_at: Option<String>,
}

impl Account {
    pub fn id_as_uuid(&self) -> Uuid {
        Uuid::parse_str(&self.id).unwrap_or_default()
    }

    pub fn created_at_datetime(&self) -> DateTime<Utc> {
        DateTime::parse_from_rfc3339(&self.created_at)
            .map(|dt| dt.with_timezone(&Utc))
            .unwrap_or_else(|_| Utc::now())
    }

    pub fn backup_codes(&self) -> Option<Vec<String>> {
        self.backup_codes_hash
            .as_ref()
            .and_then(|s| serde_json::from_str(s).ok())
    }
}

/// Device info for tracking logged-in devices
#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct Device {
    pub id: String,
    pub account_id: String,
    pub name: String,
    pub platform: String,
    pub last_seen_at: String,
    pub created_at: String,
}

/// Passkey registration session (temporary, stored in memory)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PasskeyRegistrationSession {
    pub account_id: Uuid,
    pub challenge: String,
    pub user_verification: String,
    pub created_at: DateTime<Utc>,
}

/// Passkey authentication session
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PasskeyAuthSession {
    pub challenge: String,
    pub handle: String,
    pub created_at: DateTime<Utc>,
}

/// Recovery token for email-based recovery
#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct RecoveryToken {
    pub id: String,
    pub account_id: String,
    pub token_hash: String,
    pub expires_at: String,
    pub used: bool,
    pub created_at: String,
}

// ============ Request/Response DTOs ============

/// Registration request
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct RegisterRequest {
    #[validate(length(min = 3, max = 20), custom(function = "validate_handle"))]
    pub handle: String,
    #[validate(length(min = 1, max = 50))]
    pub display_name: String,
    #[validate(length(min = 8, max = 128))]
    pub password: Option<String>,
    #[validate(email)]
    pub email: Option<String>,
    /// Device name (e.g., "John's iPhone 15")
    pub device_name: Option<String>,
    /// Device platform (e.g., "iOS", "Android")
    pub device_platform: Option<String>,
}

/// Validate handle format
fn validate_handle(handle: &str) -> Result<(), validator::ValidationError> {
    if HANDLE_REGEX.is_match(handle) {
        Ok(())
    } else {
        Err(validator::ValidationError::new("invalid_handle"))
    }
}

/// Handle regex pattern
pub static HANDLE_REGEX: std::sync::LazyLock<regex::Regex> =
    std::sync::LazyLock::new(|| regex::Regex::new(r"^[a-zA-Z][a-zA-Z0-9_]{2,19}$").unwrap());

/// Login request (password-based)
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct LoginRequest {
    #[validate(length(min = 3, max = 20))]
    pub handle: String,
    #[validate(length(min = 1, max = 128))]
    pub password: String,
    pub totp_code: Option<String>,
    /// Device name (e.g., "John's iPhone 15")
    pub device_name: Option<String>,
    /// Device platform (e.g., "iOS", "Android")
    pub device_platform: Option<String>,
}

/// Handle availability check
#[derive(Debug, Deserialize)]
pub struct CheckHandleRequest {
    pub handle: String,
}

#[derive(Debug, Serialize)]
pub struct CheckHandleResponse {
    pub available: bool,
    pub handle: String,
}

/// Account response (public-safe data)
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AccountResponse {
    pub id: String,
    pub handle: String,
    pub display_name: String,
    pub has_passkey: bool,
    pub has_password: bool,
    pub has_email: bool,
    pub email_verified: bool,
    pub totp_enabled: bool,
    pub created_at: String,
}

impl From<&Account> for AccountResponse {
    fn from(account: &Account) -> Self {
        Self {
            id: account.id.clone(),
            handle: account.handle.clone(),
            display_name: account.display_name.clone(),
            has_passkey: account.passkey_credential_id.is_some(),
            has_password: account.password_hash.is_some(),
            has_email: account.encrypted_email.is_some(),
            email_verified: account.email_verified,
            totp_enabled: account.totp_enabled,
            created_at: account.created_at.clone(),
        }
    }
}

/// Auth token response
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub token: String,
    pub account: AccountResponse,
    /// Device ID for this session (used for device management)
    pub device_id: String,
    /// Matrix credentials for cloud messaging (auto-created on registration)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub matrix: Option<MatrixCredentials>,
}

/// Matrix server credentials
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MatrixCredentials {
    /// Full Matrix user ID (e.g., @handle:kinu.chat)
    pub user_id: String,
    /// Matrix access token
    pub access_token: String,
    /// Device ID
    pub device_id: String,
    /// Homeserver URL
    pub homeserver_url: String,
}

/// Update account request
#[derive(Debug, Deserialize, Validate)]
pub struct UpdateAccountRequest {
    #[validate(length(min = 1, max = 50))]
    pub display_name: Option<String>,
}

/// Passkey registration start request
#[derive(Debug, Deserialize)]
pub struct PasskeyRegisterStartRequest {
    pub handle: String,
}

/// Passkey registration start response
#[derive(Debug, Serialize)]
pub struct PasskeyRegisterStartResponse {
    pub options: serde_json::Value,
    pub session_id: String,
}

/// Passkey registration finish request
#[derive(Debug, Deserialize)]
pub struct PasskeyRegisterFinishRequest {
    pub session_id: String,
    pub credential: serde_json::Value,
}

/// Passkey auth start request
#[derive(Debug, Deserialize)]
pub struct PasskeyAuthStartRequest {
    pub handle: String,
}

/// Passkey auth start response
#[derive(Debug, Serialize)]
pub struct PasskeyAuthStartResponse {
    pub options: serde_json::Value,
    pub session_id: String,
}

/// Passkey auth finish request
#[derive(Debug, Deserialize)]
pub struct PasskeyAuthFinishRequest {
    pub session_id: String,
    pub credential: serde_json::Value,
}

/// Recovery request
#[derive(Debug, Deserialize, Validate)]
pub struct RecoveryRequest {
    #[validate(length(min = 3, max = 20))]
    pub handle: String,
}

/// Recovery verify request
#[derive(Debug, Deserialize)]
pub struct RecoveryVerifyRequest {
    pub token: String,
}

/// Recovery reset request
#[derive(Debug, Deserialize, Validate)]
pub struct RecoveryResetRequest {
    pub token: String,
    #[validate(length(min = 8, max = 128))]
    pub new_password: Option<String>,
}

/// TOTP setup response
#[derive(Debug, Serialize)]
pub struct TotpSetupResponse {
    pub secret: String,
    pub otpauth_url: String,
    pub qr_code_base64: String,
}

/// TOTP verify request
#[derive(Debug, Deserialize)]
pub struct TotpVerifyRequest {
    pub code: String,
}

/// Backup codes response
#[derive(Debug, Serialize)]
pub struct BackupCodesResponse {
    pub codes: Vec<String>,
}

/// Change password request
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct ChangePasswordRequest {
    pub current_password: String,
    #[validate(length(min = 8, max = 128))]
    pub new_password: String,
}

/// Update email request
#[derive(Debug, Deserialize, Validate)]
#[serde(rename_all = "camelCase")]
pub struct UpdateEmailRequest {
    #[validate(email)]
    pub email: String,
    pub password: String,
}

/// Verify email request
#[derive(Debug, Deserialize)]
pub struct VerifyEmailRequest {
    pub token: String,
}

/// Delete account request
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeleteAccountRequest {
    pub password: String,
}

/// Device info for API response
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceInfoResponse {
    pub id: String,
    pub name: String,
    #[serde(rename = "type")]
    pub device_type: String,
    pub last_active_at: chrono::DateTime<chrono::Utc>,
    pub is_current: bool,
    pub location: Option<String>,
}

impl DeviceInfoResponse {
    pub fn from_device(device: &Device, current_device_id: Option<&str>) -> Self {
        let last_active = chrono::DateTime::parse_from_rfc3339(&device.last_seen_at)
            .map(|dt| dt.with_timezone(&chrono::Utc))
            .unwrap_or_else(|_| chrono::Utc::now());

        Self {
            id: device.id.clone(),
            name: device.name.clone(),
            device_type: device.platform.clone(),
            last_active_at: last_active,
            is_current: current_device_id.map(|id| id == device.id).unwrap_or(false),
            location: None, // Could be added later with IP geolocation
        }
    }
}

/// Data export response for GDPR compliance
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DataExportResponse {
    pub exported_at: chrono::DateTime<chrono::Utc>,
    pub account: AccountExportData,
    pub devices: Vec<DeviceExportData>,
    pub security: SecurityExportData,
}

/// Account data for export
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AccountExportData {
    pub id: String,
    pub handle: String,
    pub display_name: String,
    pub has_email: bool,
    pub email_verified: bool,
    pub created_at: String,
}

/// Device data for export
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceExportData {
    pub id: String,
    pub name: String,
    pub platform: String,
    pub first_seen: String,
    pub last_active: String,
}

/// Security settings for export
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SecurityExportData {
    pub has_passkey: bool,
    pub has_password: bool,
    pub totp_enabled: bool,
    pub backup_codes_remaining: usize,
}

/// Generic API error response
#[derive(Debug, Serialize)]
pub struct ApiError {
    pub error: String,
    pub code: String,
}

impl ApiError {
    pub fn new(error: impl Into<String>, code: impl Into<String>) -> Self {
        Self {
            error: error.into(),
            code: code.into(),
        }
    }
}
