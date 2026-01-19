use std::sync::Arc;

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};

use crate::{
    crypto::{self, encryption, TotpConfig},
    db::AccountDb,
    models::*,
    AppState,
};

/// Helper to extract account ID from authorization header
fn extract_account_id_from_header(
    headers: &axum::http::HeaderMap,
    jwt_secret: &str,
) -> Result<uuid::Uuid, (StatusCode, Json<ApiError>)> {
    let token = headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Missing authorization header", "UNAUTHORIZED")),
            )
        })?;

    crypto::extract_account_id(token, jwt_secret).map_err(|_| {
        (
            StatusCode::UNAUTHORIZED,
            Json(ApiError::new("Invalid or expired token", "UNAUTHORIZED")),
        )
    })
}

/// Set up TOTP for account
pub async fn setup_totp(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Get account
    let account = match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => account,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(ApiError::new("Account not found", "NOT_FOUND")),
            )
                .into_response();
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Database error", "DB_ERROR")),
            )
                .into_response();
        }
    };

    // Check if 2FA already enabled
    if account.totp_enabled {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("2FA is already enabled", "2FA_ALREADY_ENABLED")),
        )
            .into_response();
    }

    // Generate TOTP config
    let totp_config = match TotpConfig::new(&account.handle) {
        Ok(config) => config,
        Err(e) => {
            tracing::error!("TOTP generation error: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to generate TOTP", "TOTP_ERROR")),
            )
                .into_response();
        }
    };

    // Encrypt secret for storage
    let (encrypted_secret, nonce) =
        match encryption::encrypt(&totp_config.secret, &state.email_encryption_key) {
            Ok(result) => result,
            Err(e) => {
                tracing::error!("Encryption error: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to encrypt TOTP secret", "ENCRYPTION_ERROR")),
                )
                    .into_response();
            }
        };

    // Store encrypted secret (but don't enable yet - user must verify first)
    if let Err(e) = AccountDb::update_totp(
        &state.db,
        account_id,
        Some(&encrypted_secret),
        Some(&nonce),
        false, // Not enabled until verified
        None,
    )
    .await
    {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to store TOTP secret", "DB_ERROR")),
        )
            .into_response();
    }

    // Generate QR code
    let qr_code = match totp_config.qr_code_base64() {
        Ok(qr) => qr,
        Err(e) => {
            tracing::error!("QR code generation error: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to generate QR code", "QR_ERROR")),
            )
                .into_response();
        }
    };

    let otpauth_url = totp_config.otpauth_url().unwrap_or_default();

    Json(TotpSetupResponse {
        secret: totp_config.secret_base32(),
        otpauth_url,
        qr_code_base64: qr_code,
    })
    .into_response()
}

/// Verify TOTP code and enable 2FA
pub async fn verify_totp(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<TotpVerifyRequest>,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Get account
    let account = match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => account,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(ApiError::new("Account not found", "NOT_FOUND")),
            )
                .into_response();
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Database error", "DB_ERROR")),
            )
                .into_response();
        }
    };

    // Get encrypted TOTP secret
    let (encrypted_secret, nonce) = match (&account.totp_secret_encrypted, &account.totp_secret_nonce) {
        (Some(secret), Some(nonce)) => (secret, nonce),
        _ => {
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("TOTP not set up", "TOTP_NOT_SETUP")),
            )
                .into_response();
        }
    };

    let nonce_arr: [u8; 12] = match nonce.as_slice().try_into() {
        Ok(arr) => arr,
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Invalid TOTP configuration", "TOTP_ERROR")),
            )
                .into_response();
        }
    };

    // Decrypt secret
    let secret = match encryption::decrypt(encrypted_secret, &state.email_encryption_key, &nonce_arr) {
        Ok(s) => s,
        Err(e) => {
            tracing::error!("Decryption error: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to decrypt TOTP secret", "DECRYPTION_ERROR")),
            )
                .into_response();
        }
    };

    // Verify code
    let totp_config = TotpConfig::from_secret(secret, &account.handle);
    match totp_config.verify_code(&req.code) {
        Ok(true) => {
            // Code verified - enable 2FA and generate backup codes
            let backup_codes = crypto::generate_backup_codes(10);
            let backup_codes_hash = crypto::hash_backup_codes(&backup_codes);

            if let Err(e) = AccountDb::update_totp(
                &state.db,
                account_id,
                Some(encrypted_secret),
                Some(nonce),
                true, // Now enabled
                Some(backup_codes_hash),
            )
            .await
            {
                tracing::error!("Database error: {}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to enable 2FA", "DB_ERROR")),
                )
                    .into_response();
            }

            Json(serde_json::json!({
                "enabled": true,
                "backup_codes": backup_codes
            }))
            .into_response()
        }
        Ok(false) => (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("Invalid verification code", "INVALID_CODE")),
        )
            .into_response(),
        Err(e) => {
            tracing::error!("TOTP verification error: {:?}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("TOTP verification failed", "TOTP_ERROR")),
            )
                .into_response()
        }
    }
}

/// Disable TOTP for account
pub async fn disable_totp(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<TotpVerifyRequest>,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Get account
    let account = match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => account,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(ApiError::new("Account not found", "NOT_FOUND")),
            )
                .into_response();
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Database error", "DB_ERROR")),
            )
                .into_response();
        }
    };

    // Check if 2FA is enabled
    if !account.totp_enabled {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("2FA is not enabled", "2FA_NOT_ENABLED")),
        )
            .into_response();
    }

    // Verify code before disabling
    let (encrypted_secret, nonce) = match (&account.totp_secret_encrypted, &account.totp_secret_nonce) {
        (Some(secret), Some(nonce)) => (secret, nonce),
        _ => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Invalid TOTP configuration", "TOTP_ERROR")),
            )
                .into_response();
        }
    };

    let nonce_arr: [u8; 12] = match nonce.as_slice().try_into() {
        Ok(arr) => arr,
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Invalid TOTP configuration", "TOTP_ERROR")),
            )
                .into_response();
        }
    };

    let secret = match encryption::decrypt(encrypted_secret, &state.email_encryption_key, &nonce_arr) {
        Ok(s) => s,
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to decrypt TOTP secret", "DECRYPTION_ERROR")),
            )
                .into_response();
        }
    };

    let totp_config = TotpConfig::from_secret(secret, &account.handle);

    // Try TOTP code first, then backup codes
    let code_valid = match totp_config.verify_code(&req.code) {
        Ok(true) => true,
        Ok(false) => {
            // Try backup codes (parse from JSON string)
            if let Some(backup_codes) = account.backup_codes() {
                crypto::verify_backup_code(&req.code, &backup_codes).is_some()
            } else {
                false
            }
        }
        Err(_) => false,
    };

    if !code_valid {
        return (
            StatusCode::UNAUTHORIZED,
            Json(ApiError::new("Invalid verification code", "INVALID_CODE")),
        )
            .into_response();
    }

    // Disable 2FA
    if let Err(e) = AccountDb::update_totp(&state.db, account_id, None, None, false, None).await {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to disable 2FA", "DB_ERROR")),
        )
            .into_response();
    }

    Json(serde_json::json!({
        "disabled": true
    }))
    .into_response()
}

/// Get new backup codes (regenerate)
pub async fn get_backup_codes(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Get account
    let account = match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => account,
        Ok(None) => {
            return (
                StatusCode::NOT_FOUND,
                Json(ApiError::new("Account not found", "NOT_FOUND")),
            )
                .into_response();
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Database error", "DB_ERROR")),
            )
                .into_response();
        }
    };

    // Check if 2FA is enabled
    if !account.totp_enabled {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("2FA is not enabled", "2FA_NOT_ENABLED")),
        )
            .into_response();
    }

    // Generate new backup codes
    let backup_codes = crypto::generate_backup_codes(10);
    let backup_codes_hash = crypto::hash_backup_codes(&backup_codes);

    // Update backup codes in database
    if let Err(e) = AccountDb::update_totp(
        &state.db,
        account_id,
        account.totp_secret_encrypted.as_deref(),
        account.totp_secret_nonce.as_deref(),
        true,
        Some(backup_codes_hash),
    )
    .await
    {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to generate backup codes", "DB_ERROR")),
        )
            .into_response();
    }

    Json(BackupCodesResponse { codes: backup_codes }).into_response()
}
