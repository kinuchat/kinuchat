use std::sync::Arc;

use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use validator::Validate;

use rand::Rng;
use sha2::{Digest, Sha256};

use crate::{
    crypto::{self, encryption},
    db::{AccountDb, DeviceDb, EmailVerificationTokenDb},
    matrix::MatrixError,
    models::*,
    AppState,
};

/// Register a new account
pub async fn register(
    State(state): State<Arc<AppState>>,
    Json(req): Json<RegisterRequest>,
) -> impl IntoResponse {
    // Validate request
    if let Err(e) = req.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new(format!("Validation error: {}", e), "VALIDATION_ERROR")),
        )
            .into_response();
    }

    // Check handle availability
    match AccountDb::handle_available(&state.db, &req.handle).await {
        Ok(false) => {
            return (
                StatusCode::CONFLICT,
                Json(ApiError::new("Handle already taken", "HANDLE_TAKEN")),
            )
                .into_response();
        }
        Err(e) => {
            tracing::error!("Database error checking handle: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Database error", "DB_ERROR")),
            )
                .into_response();
        }
        Ok(true) => {}
    }

    // Hash password if provided
    let password_hash = match &req.password {
        Some(password) => match crypto::hash_password(password) {
            Ok(hash) => Some(hash),
            Err(e) => {
                tracing::error!("Password hashing error: {}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to process password", "HASH_ERROR")),
                )
                    .into_response();
            }
        },
        None => None,
    };

    // Encrypt email if provided
    let (encrypted_email, email_nonce) = match &req.email {
        Some(email) => match encryption::encrypt_email(email, &state.email_encryption_key) {
            Ok((ciphertext, nonce)) => (Some(ciphertext), Some(nonce.to_vec())),
            Err(e) => {
                tracing::error!("Email encryption error: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to process email", "ENCRYPTION_ERROR")),
                )
                    .into_response();
            }
        },
        None => (None, None),
    };

    // Create account
    let account = match AccountDb::create(
        &state.db,
        &req.handle,
        &req.display_name,
        password_hash.as_deref(),
        encrypted_email.as_deref(),
        email_nonce.as_deref(),
    )
    .await
    {
        Ok(account) => account,
        Err(e) => {
            tracing::error!("Database error creating account: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to create account", "DB_ERROR")),
            )
                .into_response();
        }
    };

    // Generate access token
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

    // Create device record
    let device_name = req.device_name.as_deref().unwrap_or("Unknown Device");
    let device_platform = req.device_platform.as_deref().unwrap_or("Unknown");
    let device_id = match DeviceDb::create(&state.db, account.id_as_uuid(), device_name, device_platform).await {
        Ok(id) => id,
        Err(e) => {
            tracing::error!("Failed to create device record: {}", e);
            // Don't fail registration, just use a generated ID
            uuid::Uuid::new_v4()
        }
    };

    // Create Matrix account with same credentials
    // This happens async - if it fails, we log but don't fail the registration
    let matrix_credentials = if let Some(password) = &req.password {
        match state
            .matrix_service
            .register_account(&account.handle, password)
            .await
        {
            Ok(matrix_response) => {
                tracing::info!(
                    "Created Matrix account for @{}: {}",
                    account.handle,
                    matrix_response.user_id
                );
                Some(MatrixCredentials {
                    user_id: matrix_response.user_id,
                    access_token: matrix_response.access_token,
                    device_id: matrix_response.device_id,
                    homeserver_url: state.matrix_config.homeserver_url.clone(),
                })
            }
            Err(MatrixError::UserExists) => {
                // User already exists in Matrix, that's fine
                tracing::warn!(
                    "Matrix user already exists for @{}, skipping creation",
                    account.handle
                );
                None
            }
            Err(e) => {
                tracing::error!("Failed to create Matrix account for @{}: {:?}", account.handle, e);
                None
            }
        }
    } else {
        // No password provided (passkey-only), skip Matrix account creation for now
        None
    };

    (
        StatusCode::CREATED,
        Json(AuthResponse {
            token,
            account: AccountResponse::from(&account),
            device_id: device_id.to_string(),
            matrix: matrix_credentials,
        }),
    )
        .into_response()
}

/// Login with password
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(req): Json<LoginRequest>,
) -> impl IntoResponse {
    // Validate request
    if let Err(e) = req.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new(format!("Validation error: {}", e), "VALIDATION_ERROR")),
        )
            .into_response();
    }

    // Find account
    let account = match AccountDb::find_by_handle(&state.db, &req.handle).await {
        Ok(Some(account)) => account,
        Ok(None) => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Invalid credentials", "INVALID_CREDENTIALS")),
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

    // Check password
    let password_hash = match &account.password_hash {
        Some(hash) => hash,
        None => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Password login not enabled", "NO_PASSWORD")),
            )
                .into_response();
        }
    };

    match crypto::verify_password(&req.password, password_hash) {
        Ok(true) => {}
        Ok(false) => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Invalid credentials", "INVALID_CREDENTIALS")),
            )
                .into_response();
        }
        Err(e) => {
            tracing::error!("Password verification error: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Authentication error", "AUTH_ERROR")),
            )
                .into_response();
        }
    }

    // Check 2FA if enabled
    if account.totp_enabled {
        match &req.totp_code {
            Some(code) => {
                // Verify TOTP code
                if let (Some(encrypted_secret), Some(nonce)) =
                    (&account.totp_secret_encrypted, &account.totp_secret_nonce)
                {
                    let nonce_arr: [u8; 12] = nonce
                        .as_slice()
                        .try_into()
                        .map_err(|_| {
                            (
                                StatusCode::INTERNAL_SERVER_ERROR,
                                Json(ApiError::new("Invalid TOTP configuration", "TOTP_ERROR")),
                            )
                        })
                        .unwrap();

                    let secret = match encryption::decrypt(
                        encrypted_secret,
                        &state.email_encryption_key, // Using same key for TOTP encryption
                        &nonce_arr,
                    ) {
                        Ok(s) => s,
                        Err(_) => {
                            return (
                                StatusCode::INTERNAL_SERVER_ERROR,
                                Json(ApiError::new("TOTP decryption failed", "TOTP_ERROR")),
                            )
                                .into_response();
                        }
                    };

                    let totp_config = crate::crypto::TotpConfig::from_secret(secret, &account.handle);
                    match totp_config.verify_code(code) {
                        Ok(true) => {}
                        Ok(false) => {
                            // Try backup codes (parse from JSON string)
                            if let Some(backup_codes) = account.backup_codes() {
                                if let Some(index) = crate::crypto::verify_backup_code(code, &backup_codes) {
                                    // Remove used backup code
                                    let _ = AccountDb::remove_backup_code(&state.db, account.id_as_uuid(), index).await;
                                } else {
                                    return (
                                        StatusCode::UNAUTHORIZED,
                                        Json(ApiError::new("Invalid 2FA code", "INVALID_2FA")),
                                    )
                                        .into_response();
                                }
                            } else {
                                return (
                                    StatusCode::UNAUTHORIZED,
                                    Json(ApiError::new("Invalid 2FA code", "INVALID_2FA")),
                                )
                                    .into_response();
                            }
                        }
                        Err(_) => {
                            return (
                                StatusCode::INTERNAL_SERVER_ERROR,
                                Json(ApiError::new("TOTP verification error", "TOTP_ERROR")),
                            )
                                .into_response();
                        }
                    }
                }
            }
            None => {
                return (
                    StatusCode::UNAUTHORIZED,
                    Json(ApiError::new("2FA code required", "2FA_REQUIRED")),
                )
                    .into_response();
            }
        }
    }

    // Update last login
    let _ = AccountDb::update_last_login(&state.db, account.id_as_uuid()).await;

    // Generate access token
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

    // Create device record
    let device_name = req.device_name.as_deref().unwrap_or("Unknown Device");
    let device_platform = req.device_platform.as_deref().unwrap_or("Unknown");
    let device_id = match DeviceDb::create(&state.db, account.id_as_uuid(), device_name, device_platform).await {
        Ok(id) => id,
        Err(e) => {
            tracing::error!("Failed to create device record: {}", e);
            // Don't fail login, just use a generated ID
            uuid::Uuid::new_v4()
        }
    };

    // For login, we return Matrix config so the app can log in with same credentials
    // The Matrix user ID is derived from the handle
    let matrix_user_id = state.matrix_config.handle_to_matrix_id(&account.handle);

    Json(AuthResponse {
        token,
        account: AccountResponse::from(&account),
        device_id: device_id.to_string(),
        // Return Matrix info for the app to log in with same password
        matrix: Some(MatrixCredentials {
            user_id: matrix_user_id,
            access_token: String::new(), // App will login separately
            device_id: String::new(),
            homeserver_url: state.matrix_config.homeserver_url.clone(),
        }),
    })
    .into_response()
}

/// Check handle availability
pub async fn check_handle(
    State(state): State<Arc<AppState>>,
    Query(req): Query<CheckHandleRequest>,
) -> impl IntoResponse {
    // Validate handle format
    if !HANDLE_REGEX.is_match(&req.handle) {
        return Json(CheckHandleResponse {
            available: false,
            handle: req.handle,
        });
    }

    let available = AccountDb::handle_available(&state.db, &req.handle)
        .await
        .unwrap_or(false);

    Json(CheckHandleResponse {
        available,
        handle: req.handle,
    })
}

/// Get current account (requires auth)
pub async fn get_current_account(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    // Extract token from Authorization header
    let token = match headers.get("Authorization") {
        Some(value) => {
            let value = value.to_str().unwrap_or("");
            if value.starts_with("Bearer ") {
                &value[7..]
            } else {
                return (
                    StatusCode::UNAUTHORIZED,
                    Json(ApiError::new("Invalid authorization header", "UNAUTHORIZED")),
                )
                    .into_response();
            }
        }
        None => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Missing authorization header", "UNAUTHORIZED")),
            )
                .into_response();
        }
    };

    // Validate token and get account ID
    let account_id = match crypto::extract_account_id(token, &state.jwt_secret) {
        Ok(id) => id,
        Err(_) => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Invalid or expired token", "UNAUTHORIZED")),
            )
                .into_response();
        }
    };

    // Get account
    match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => Json(AccountResponse::from(&account)).into_response(),
        Ok(None) => (
            StatusCode::NOT_FOUND,
            Json(ApiError::new("Account not found", "NOT_FOUND")),
        )
            .into_response(),
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

/// Update current account
pub async fn update_account(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<UpdateAccountRequest>,
) -> impl IntoResponse {
    // Extract and validate token
    let token = match headers.get("Authorization") {
        Some(value) => {
            let value = value.to_str().unwrap_or("");
            if value.starts_with("Bearer ") {
                &value[7..]
            } else {
                return (
                    StatusCode::UNAUTHORIZED,
                    Json(ApiError::new("Invalid authorization header", "UNAUTHORIZED")),
                )
                    .into_response();
            }
        }
        None => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Missing authorization header", "UNAUTHORIZED")),
            )
                .into_response();
        }
    };

    let account_id = match crypto::extract_account_id(token, &state.jwt_secret) {
        Ok(id) => id,
        Err(_) => {
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Invalid or expired token", "UNAUTHORIZED")),
            )
                .into_response();
        }
    };

    // Validate request
    if let Err(e) = req.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new(format!("Validation error: {}", e), "VALIDATION_ERROR")),
        )
            .into_response();
    }

    // Update display name if provided
    if let Some(display_name) = req.display_name {
        match AccountDb::update_display_name(&state.db, account_id, &display_name).await {
            Ok(account) => {
                return Json(AccountResponse::from(&account)).into_response();
            }
            Err(e) => {
                tracing::error!("Database error: {}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Database error", "DB_ERROR")),
                )
                    .into_response();
            }
        }
    }

    // If no updates were provided, return current account
    match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => Json(AccountResponse::from(&account)).into_response(),
        Ok(None) => (
            StatusCode::NOT_FOUND,
            Json(ApiError::new("Account not found", "NOT_FOUND")),
        )
            .into_response(),
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

/// Change password
pub async fn change_password(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<ChangePasswordRequest>,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Validate request
    if let Err(e) = req.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new(format!("Validation error: {}", e), "VALIDATION_ERROR")),
        )
            .into_response();
    }

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

    // Verify current password (if account has a password)
    if let Some(current_hash) = &account.password_hash {
        match crypto::verify_password(&req.current_password, current_hash) {
            Ok(true) => {}
            Ok(false) => {
                return (
                    StatusCode::UNAUTHORIZED,
                    Json(ApiError::new("Current password is incorrect", "INVALID_PASSWORD")),
                )
                    .into_response();
            }
            Err(e) => {
                tracing::error!("Password verification error: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Authentication error", "AUTH_ERROR")),
                )
                    .into_response();
            }
        }
    }

    // Hash new password
    let new_hash = match crypto::hash_password(&req.new_password) {
        Ok(hash) => hash,
        Err(e) => {
            tracing::error!("Password hashing error: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to process password", "HASH_ERROR")),
            )
                .into_response();
        }
    };

    // Update password
    if let Err(e) = AccountDb::update_password(&state.db, account_id, &new_hash).await {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to update password", "DB_ERROR")),
        )
            .into_response();
    }

    Json(serde_json::json!({"success": true})).into_response()
}

/// Update email
pub async fn update_email(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<UpdateEmailRequest>,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Validate request
    if let Err(e) = req.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new(format!("Validation error: {}", e), "VALIDATION_ERROR")),
        )
            .into_response();
    }

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

    // Verify password
    if let Some(password_hash) = &account.password_hash {
        match crypto::verify_password(&req.password, password_hash) {
            Ok(true) => {}
            Ok(false) => {
                return (
                    StatusCode::UNAUTHORIZED,
                    Json(ApiError::new("Password is incorrect", "INVALID_PASSWORD")),
                )
                    .into_response();
            }
            Err(e) => {
                tracing::error!("Password verification error: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Authentication error", "AUTH_ERROR")),
                )
                    .into_response();
            }
        }
    } else {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("Password is required to update email", "PASSWORD_REQUIRED")),
        )
            .into_response();
    }

    // Encrypt email
    let (encrypted_email, nonce) = match encryption::encrypt_email(&req.email, &state.email_encryption_key) {
        Ok(result) => result,
        Err(e) => {
            tracing::error!("Email encryption error: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to process email", "ENCRYPTION_ERROR")),
            )
                .into_response();
        }
    };

    // Update email in database
    if let Err(e) = sqlx::query(
        "UPDATE accounts SET encrypted_email = ?, email_nonce = ?, email_verified = 0 WHERE id = ?"
    )
    .bind(&encrypted_email)
    .bind(nonce.to_vec())
    .bind(account_id.to_string())
    .execute(&state.db)
    .await
    {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to update email", "DB_ERROR")),
        )
            .into_response();
    }

    // Send verification email
    if let Err(e) = send_verification_email(&state, account_id, &req.email, &account.handle).await {
        tracing::error!("Failed to send verification email: {}", e);
        // Don't fail the request, email was still updated
    }

    Json(serde_json::json!({
        "success": true,
        "message": "Email updated. Please check your inbox to verify."
    })).into_response()
}

/// Resend verification email
pub async fn resend_verification(
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

    // Check if email exists
    if account.encrypted_email.is_none() {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("No email to verify", "NO_EMAIL")),
        )
            .into_response();
    }

    // Check if already verified
    if account.email_verified {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("Email already verified", "ALREADY_VERIFIED")),
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
                if let Err(e) = send_verification_email(&state, account_id, &email, &account.handle).await {
                    tracing::error!("Failed to send verification email: {}", e);
                    return (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(ApiError::new("Failed to send verification email", "EMAIL_ERROR")),
                    )
                        .into_response();
                }
            }
            Err(e) => {
                tracing::error!("Failed to decrypt email: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to process email", "EMAIL_ERROR")),
                )
                    .into_response();
            }
        }
    }

    Json(serde_json::json!({
        "success": true,
        "message": "Verification email sent"
    })).into_response()
}

/// Remove email
pub async fn remove_email(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Update email in database
    if let Err(e) = sqlx::query(
        "UPDATE accounts SET encrypted_email = NULL, email_nonce = NULL, email_verified = 0 WHERE id = ?"
    )
    .bind(account_id.to_string())
    .execute(&state.db)
    .await
    {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to remove email", "DB_ERROR")),
        )
            .into_response();
    }

    Json(serde_json::json!({"success": true})).into_response()
}

/// Delete account
pub async fn delete_account(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<DeleteAccountRequest>,
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

    // Verify password
    if let Some(password_hash) = &account.password_hash {
        match crypto::verify_password(&req.password, password_hash) {
            Ok(true) => {}
            Ok(false) => {
                return (
                    StatusCode::UNAUTHORIZED,
                    Json(ApiError::new("Password is incorrect", "INVALID_PASSWORD")),
                )
                    .into_response();
            }
            Err(e) => {
                tracing::error!("Password verification error: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Authentication error", "AUTH_ERROR")),
                )
                    .into_response();
            }
        }
    } else {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiError::new("Password is required to delete account", "PASSWORD_REQUIRED")),
        )
            .into_response();
    }

    // Delete Matrix account (best effort, don't fail if it doesn't work)
    if let Err(e) = state.matrix_service.delete_account(&account.handle).await {
        tracing::warn!("Failed to delete Matrix account for @{}: {:?}", account.handle, e);
    }

    // Delete account from database
    if let Err(e) = AccountDb::delete(&state.db, account_id).await {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to delete account", "DB_ERROR")),
        )
            .into_response();
    }

    Json(serde_json::json!({"success": true})).into_response()
}

/// Verify email with token
pub async fn verify_email(
    State(state): State<Arc<AppState>>,
    Json(req): Json<VerifyEmailRequest>,
) -> impl IntoResponse {
    // Hash the provided token
    let mut hasher = Sha256::new();
    hasher.update(req.token.as_bytes());
    let token_hash = hex::encode(hasher.finalize());

    // Find valid token
    match EmailVerificationTokenDb::find_valid_by_hash(&state.db, &token_hash).await {
        Ok(Some((token_id, account_id))) => {
            // Mark email as verified
            if let Err(e) = AccountDb::update_email_verified(&state.db, account_id, true).await {
                tracing::error!("Failed to update email verification status: {}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiError::new("Failed to verify email", "DB_ERROR")),
                )
                    .into_response();
            }

            // Delete the used token
            if let Err(e) = EmailVerificationTokenDb::delete(&state.db, token_id).await {
                tracing::error!("Failed to delete verification token: {}", e);
            }

            Json(serde_json::json!({
                "success": true,
                "message": "Email verified successfully"
            }))
            .into_response()
        }
        Ok(None) => {
            (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid or expired verification token", "INVALID_TOKEN")),
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

/// Export user data (GDPR compliance)
pub async fn export_data(
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

    // Get devices
    let devices = match DeviceDb::list_for_account(&state.db, account_id).await {
        Ok(devices) => devices,
        Err(e) => {
            tracing::error!("Database error fetching devices: {}", e);
            Vec::new()
        }
    };

    // Build export data
    let account_data = AccountExportData {
        id: account.id.clone(),
        handle: account.handle.clone(),
        display_name: account.display_name.clone(),
        has_email: account.encrypted_email.is_some(),
        email_verified: account.email_verified,
        created_at: account.created_at.clone(),
    };

    let device_data: Vec<DeviceExportData> = devices
        .iter()
        .map(|d| DeviceExportData {
            id: d.id.clone(),
            name: d.name.clone(),
            platform: d.platform.clone(),
            first_seen: d.created_at.clone(),
            last_active: d.last_seen_at.clone(),
        })
        .collect();

    let backup_codes_count = account.backup_codes().map(|c| c.len()).unwrap_or(0);

    let security_data = SecurityExportData {
        has_passkey: account.passkey_credential_id.is_some(),
        has_password: account.password_hash.is_some(),
        totp_enabled: account.totp_enabled,
        backup_codes_remaining: backup_codes_count,
    };

    let export = DataExportResponse {
        exported_at: chrono::Utc::now(),
        account: account_data,
        devices: device_data,
        security: security_data,
    };

    Json(export).into_response()
}

/// Helper function to send verification email
async fn send_verification_email(
    state: &AppState,
    account_id: uuid::Uuid,
    email: &str,
    handle: &str,
) -> Result<(), String> {
    // Generate verification token
    let token: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(64)
        .map(char::from)
        .collect();

    // Hash token for storage
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    let token_hash = hex::encode(hasher.finalize());

    // Store verification token (expires in 24 hours)
    if let Err(e) = EmailVerificationTokenDb::create(&state.db, account_id, &token_hash, 24).await {
        tracing::error!("Failed to create verification token: {}", e);
        return Err(format!("Failed to create verification token: {}", e));
    }

    // Send verification email if email service is configured
    if let Some(email_service) = &state.email_service {
        match email_service.send_verification_email(email, handle, &token).await {
            Ok(_) => {
                tracing::info!("Verification email sent to {} for handle {}", email, handle);
                Ok(())
            }
            Err(e) => {
                tracing::error!("Failed to send verification email: {}", e);
                Err(format!("Failed to send verification email: {}", e))
            }
        }
    } else {
        // Email service not configured - log for debugging
        tracing::warn!(
            "Email service not configured. Verification token for {}: {}",
            handle,
            token
        );

        // In development mode, include the token in logs
        #[cfg(debug_assertions)]
        tracing::info!("DEV: Verification token for {}: {}", handle, token);

        Ok(())
    }
}
