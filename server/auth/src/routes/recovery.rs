use std::sync::Arc;

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use rand::Rng;
use sha2::{Digest, Sha256};
use validator::Validate;

use crate::{
    crypto::{self, encryption},
    db::{AccountDb, DeviceDb, RecoveryTokenDb},
    models::*,
    AppState,
};

/// Request account recovery via email
pub async fn request_recovery(
    State(state): State<Arc<AppState>>,
    Json(req): Json<RecoveryRequest>,
) -> impl IntoResponse {
    // Validate request
    if let Err(e) = req.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new(format!("Validation error: {}", e), "VALIDATION_ERROR")),
        )
            .into_response();
    }

    // Always return success to prevent email enumeration
    // But only actually send email if account exists with verified email

    // Find account
    let account = match AccountDb::find_by_handle(&state.db, &req.handle).await {
        Ok(Some(account)) => account,
        Ok(None) => {
            // Return success anyway to prevent enumeration
            return Json(serde_json::json!({
                "message": "If an account exists with a verified email, a recovery link has been sent."
            }))
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

    // Check if account has verified email
    if !account.email_verified || account.encrypted_email.is_none() {
        // Return success anyway to prevent enumeration
        return Json(serde_json::json!({
            "message": "If an account exists with a verified email, a recovery link has been sent."
        }))
        .into_response();
    }

    // Generate recovery token
    let token: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(64)
        .map(char::from)
        .collect();

    // Hash token for storage
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    let token_hash = hex::encode(hasher.finalize());

    // Store recovery token (expires in 1 hour)
    if let Err(e) = RecoveryTokenDb::create(&state.db, account.id_as_uuid(), &token_hash, 1).await {
        tracing::error!("Failed to create recovery token: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to create recovery token", "DB_ERROR")),
        )
            .into_response();
    }

    // Decrypt email for sending
    if let (Some(encrypted_email), Some(email_nonce)) = (&account.encrypted_email, &account.email_nonce) {
        let nonce_arr: [u8; 12] = match email_nonce.as_slice().try_into() {
            Ok(arr) => arr,
            Err(_) => {
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Invalid email configuration", "EMAIL_ERROR")),
                )
                    .into_response();
            }
        };

        match encryption::decrypt_email(encrypted_email, &state.email_encryption_key, &nonce_arr) {
            Ok(email) => {
                // Send recovery email if email service is configured
                if let Some(email_service) = &state.email_service {
                    match email_service.send_recovery_email(&email, &account.handle, &token).await {
                        Ok(_) => {
                            tracing::info!("Recovery email sent to {} for handle {}", email, account.handle);
                        }
                        Err(e) => {
                            tracing::error!("Failed to send recovery email: {}", e);
                            // Don't reveal email sending failure to prevent enumeration
                        }
                    }
                } else {
                    // Email service not configured - log for debugging
                    tracing::warn!(
                        "Email service not configured. Recovery token for {}: {}",
                        account.handle,
                        token
                    );

                    // In development mode, include the token in response
                    #[cfg(debug_assertions)]
                    {
                        return Json(serde_json::json!({
                            "message": "Recovery email sent (dev mode: token included)",
                            "dev_token": token
                        }))
                        .into_response();
                    }
                }
            }
            Err(e) => {
                tracing::error!("Failed to decrypt email: {:?}", e);
            }
        }
    }

    Json(serde_json::json!({
        "message": "If an account exists with a verified email, a recovery link has been sent."
    }))
    .into_response()
}

/// Verify recovery token
pub async fn verify_recovery(
    State(state): State<Arc<AppState>>,
    Json(req): Json<RecoveryVerifyRequest>,
) -> impl IntoResponse {
    // Hash the provided token
    let mut hasher = Sha256::new();
    hasher.update(req.token.as_bytes());
    let token_hash = hex::encode(hasher.finalize());

    // Find valid token
    match RecoveryTokenDb::find_valid_by_hash(&state.db, &token_hash).await {
        Ok(Some((_, account_id))) => {
            // Token is valid - return account info
            match AccountDb::find_by_id(&state.db, account_id).await {
                Ok(Some(account)) => {
                    Json(serde_json::json!({
                        "valid": true,
                        "handle": account.handle,
                        "has_passkey": account.passkey_credential_id.is_some()
                    }))
                    .into_response()
                }
                _ => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to retrieve account", "DB_ERROR")),
                )
                    .into_response(),
            }
        }
        Ok(None) => {
            (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid or expired recovery token", "INVALID_TOKEN")),
            )
                .into_response()
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Database error", "DB_ERROR")),
            )
                .into_response()
        }
    }
}

/// Reset account with recovery token
pub async fn reset_account(
    State(state): State<Arc<AppState>>,
    Json(req): Json<RecoveryResetRequest>,
) -> impl IntoResponse {
    // Validate request
    if let Err(e) = req.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new(format!("Validation error: {}", e), "VALIDATION_ERROR")),
        )
            .into_response();
    }

    // Hash the provided token
    let mut hasher = Sha256::new();
    hasher.update(req.token.as_bytes());
    let token_hash = hex::encode(hasher.finalize());

    // Find and validate token
    let (token_id, account_id) = match RecoveryTokenDb::find_valid_by_hash(&state.db, &token_hash).await {
        Ok(Some(result)) => result,
        Ok(None) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid or expired recovery token", "INVALID_TOKEN")),
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

    // If new password provided, update it
    if let Some(password) = &req.new_password {
        let password_hash = match crypto::hash_password(password) {
            Ok(hash) => hash,
            Err(e) => {
                tracing::error!("Password hashing error: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to process password", "HASH_ERROR")),
                )
                    .into_response();
            }
        };

        if let Err(e) = AccountDb::update_password(&state.db, account_id, &password_hash).await {
            tracing::error!("Database error updating password: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to update password", "DB_ERROR")),
            )
                .into_response();
        }
    }

    // Disable 2FA on recovery (user will need to re-enable)
    if let Err(e) = AccountDb::update_totp(&state.db, account_id, None, None, false, None).await {
        tracing::error!("Failed to disable 2FA: {}", e);
    }

    // Mark token as used
    if let Err(e) = RecoveryTokenDb::mark_used(&state.db, token_id).await {
        tracing::error!("Failed to mark token as used: {}", e);
    }

    // Get updated account and generate new token
    match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => {
            let token = match crypto::create_access_token(&account.id, &account.handle, &state.jwt_secret, 24 * 7) {
                Ok(token) => token,
                Err(e) => {
                    tracing::error!("Token generation error: {:?}", e);
                    return (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(ApiError::new("Failed to generate token", "TOKEN_ERROR")),
                    )
                        .into_response();
                }
            };

            // Create device record for recovery auth
            let device_id = match DeviceDb::create(&state.db, account.id_as_uuid(), "Recovery Device", "Recovery").await {
                Ok(id) => id,
                Err(e) => {
                    tracing::error!("Failed to create device record: {}", e);
                    uuid::Uuid::new_v4()
                }
            };

            Json(AuthResponse {
                token,
                account: AccountResponse::from(&account),
                device_id: device_id.to_string(),
                matrix: None, // Recovery flow doesn't provide Matrix credentials
            })
            .into_response()
        }
        _ => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to retrieve account", "DB_ERROR")),
        )
            .into_response(),
    }
}
