use std::collections::HashMap;
use std::sync::Arc;

use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use webauthn_rs::prelude::*;

use crate::{
    crypto,
    db::{AccountDb, DeviceDb},
    models::*,
    AppState,
};

// In-memory session storage (should use Redis in production)
lazy_static::lazy_static! {
    static ref REGISTRATION_SESSIONS: std::sync::RwLock<HashMap<String, serde_json::Value>> = std::sync::RwLock::new(HashMap::new());
    static ref AUTH_SESSIONS: std::sync::RwLock<HashMap<String, serde_json::Value>> = std::sync::RwLock::new(HashMap::new());
}

/// Start passkey registration
pub async fn start_registration(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
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

    // Create WebAuthn user
    let user_id = account.id_as_uuid();

    // Exclude existing credentials if any
    let exclude_credentials: Vec<CredentialID> = if let Some(ref cred_id) = account.passkey_credential_id {
        if let Ok(decoded) = BASE64.decode(cred_id) {
            vec![CredentialID::from(decoded)]
        } else {
            vec![]
        }
    } else {
        vec![]
    };

    // Start registration
    let (ccr, reg_state) = match state.webauthn.start_passkey_registration(
        user_id,
        &account.handle,
        &account.display_name,
        Some(exclude_credentials),
    ) {
        Ok(result) => result,
        Err(e) => {
            tracing::error!("WebAuthn registration start failed: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to start passkey registration", "WEBAUTHN_ERROR")),
            )
                .into_response();
        }
    };

    // Store session (serialize to JSON for simplicity)
    let session_id = uuid::Uuid::new_v4().to_string();
    {
        let mut sessions = REGISTRATION_SESSIONS.write().unwrap();
        if let Ok(state_json) = serde_json::to_value(&reg_state) {
            sessions.insert(session_id.clone(), state_json);
        }
    }

    let options = serde_json::to_value(&ccr).unwrap_or_default();

    Json(PasskeyRegisterStartResponse {
        options,
        session_id,
    })
    .into_response()
}

/// Finish passkey registration
pub async fn finish_registration(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Json(req): Json<PasskeyRegisterFinishRequest>,
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

    // Get registration session
    let reg_state_json = {
        let mut sessions = REGISTRATION_SESSIONS.write().unwrap();
        sessions.remove(&req.session_id)
    };

    let reg_state: PasskeyRegistration = match reg_state_json {
        Some(json) => match serde_json::from_value(json) {
            Ok(state) => state,
            Err(e) => {
                tracing::error!("Failed to deserialize registration state: {:?}", e);
                return (
                    StatusCode::BAD_REQUEST,
                    Json(ApiError::new("Invalid session state", "INVALID_SESSION")),
                )
                    .into_response();
            }
        },
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid or expired session", "INVALID_SESSION")),
            )
                .into_response();
        }
    };

    // Parse credential response
    let reg_response: RegisterPublicKeyCredential = match serde_json::from_value(req.credential) {
        Ok(cred) => cred,
        Err(e) => {
            tracing::error!("Failed to parse credential: {:?}", e);
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid credential format", "INVALID_CREDENTIAL")),
            )
                .into_response();
        }
    };

    // Finish registration
    let passkey = match state.webauthn.finish_passkey_registration(&reg_response, &reg_state) {
        Ok(passkey) => passkey,
        Err(e) => {
            tracing::error!("WebAuthn registration finish failed: {:?}", e);
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Failed to verify passkey registration", "WEBAUTHN_ERROR")),
            )
                .into_response();
        }
    };

    // Store passkey in database
    let credential_id = BASE64.encode(passkey.cred_id());
    let public_key = serde_json::to_vec(&passkey).unwrap_or_default();

    if let Err(e) = AccountDb::update_passkey(&state.db, account_id, &credential_id, &public_key).await {
        tracing::error!("Database error storing passkey: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to store passkey", "DB_ERROR")),
        )
            .into_response();
    }

    // Return updated account
    match AccountDb::find_by_id(&state.db, account_id).await {
        Ok(Some(account)) => Json(AccountResponse::from(&account)).into_response(),
        _ => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to retrieve account", "DB_ERROR")),
        )
            .into_response(),
    }
}

/// Start passkey authentication
pub async fn start_authentication(
    State(state): State<Arc<AppState>>,
    Json(req): Json<PasskeyAuthStartRequest>,
) -> impl IntoResponse {
    // Find account
    let account = match AccountDb::find_by_handle(&state.db, &req.handle).await {
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

    // Check if account has passkey
    let passkey_data = match (&account.passkey_credential_id, &account.passkey_public_key) {
        (Some(_), Some(data)) => data,
        _ => {
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("No passkey registered", "NO_PASSKEY")),
            )
                .into_response();
        }
    };

    // Deserialize passkey
    let passkey: Passkey = match serde_json::from_slice(passkey_data) {
        Ok(pk) => pk,
        Err(e) => {
            tracing::error!("Failed to deserialize passkey: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Invalid passkey data", "PASSKEY_ERROR")),
            )
                .into_response();
        }
    };

    // Start authentication
    let (rcr, auth_state) = match state.webauthn.start_passkey_authentication(&[passkey]) {
        Ok(result) => result,
        Err(e) => {
            tracing::error!("WebAuthn authentication start failed: {:?}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to start authentication", "WEBAUTHN_ERROR")),
            )
                .into_response();
        }
    };

    // Store session
    let session_id = uuid::Uuid::new_v4().to_string();
    {
        let mut sessions = AUTH_SESSIONS.write().unwrap();
        if let Ok(state_json) = serde_json::to_value(&auth_state) {
            sessions.insert(session_id.clone(), state_json);
        }
    }

    let options = serde_json::to_value(&rcr).unwrap_or_default();

    Json(PasskeyAuthStartResponse {
        options,
        session_id,
    })
    .into_response()
}

/// Finish passkey authentication
pub async fn finish_authentication(
    State(state): State<Arc<AppState>>,
    Json(req): Json<PasskeyAuthFinishRequest>,
) -> impl IntoResponse {
    // Get authentication session
    let auth_state_json = {
        let mut sessions = AUTH_SESSIONS.write().unwrap();
        sessions.remove(&req.session_id)
    };

    let auth_state: PasskeyAuthentication = match auth_state_json {
        Some(json) => match serde_json::from_value(json) {
            Ok(state) => state,
            Err(e) => {
                tracing::error!("Failed to deserialize auth state: {:?}", e);
                return (
                    StatusCode::BAD_REQUEST,
                    Json(ApiError::new("Invalid session state", "INVALID_SESSION")),
                )
                    .into_response();
            }
        },
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid or expired session", "INVALID_SESSION")),
            )
                .into_response();
        }
    };

    // Parse credential response
    let auth_response: PublicKeyCredential = match serde_json::from_value(req.credential) {
        Ok(cred) => cred,
        Err(e) => {
            tracing::error!("Failed to parse credential: {:?}", e);
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid credential format", "INVALID_CREDENTIAL")),
            )
                .into_response();
        }
    };

    // Finish authentication
    let _auth_result = match state.webauthn.finish_passkey_authentication(&auth_response, &auth_state) {
        Ok(result) => result,
        Err(e) => {
            tracing::error!("WebAuthn authentication finish failed: {:?}", e);
            return (
                StatusCode::UNAUTHORIZED,
                Json(ApiError::new("Passkey authentication failed", "AUTH_FAILED")),
            )
                .into_response();
        }
    };

    // Find account by credential ID - the id field is already base64url encoded in PublicKeyCredential
    let credential_id = auth_response.id.clone();

    // We need to find the account - in production, store credential_id -> account_id mapping
    // For now, we'll search (inefficient but works for MVP)
    let account = match sqlx::query_as::<_, crate::models::Account>(
        "SELECT * FROM accounts WHERE passkey_credential_id = ?",
    )
    .bind(&credential_id)
    .fetch_optional(&state.db)
    .await
    {
        Ok(Some(account)) => account,
        Ok(None) => {
            return (
                StatusCode::UNAUTHORIZED,
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

    // Create device record for passkey auth
    let device_id = match DeviceDb::create(&state.db, account.id_as_uuid(), "Passkey Device", "Passkey").await {
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
        matrix: None, // Passkey auth doesn't provide password for Matrix login
    })
    .into_response()
}
