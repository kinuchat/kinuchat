use std::sync::Arc;

use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};

use crate::{
    crypto,
    db::DeviceDb,
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

/// List all devices for the current account
pub async fn list_devices(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Get current device ID from token if available
    let current_device_id = headers
        .get("X-Device-ID")
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());

    // Get devices
    let devices = match DeviceDb::list_for_account(&state.db, account_id).await {
        Ok(devices) => devices,
        Err(e) => {
            tracing::error!("Database error: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to get devices", "DB_ERROR")),
            )
                .into_response();
        }
    };

    let device_responses: Vec<DeviceInfoResponse> = devices
        .iter()
        .map(|d| DeviceInfoResponse::from_device(d, current_device_id.as_deref()))
        .collect();

    Json(serde_json::json!({
        "devices": device_responses
    })).into_response()
}

/// Revoke a specific device
pub async fn revoke_device(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
    Path(device_id): Path<String>,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Parse device ID
    let device_uuid = match uuid::Uuid::parse_str(&device_id) {
        Ok(id) => id,
        Err(_) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new("Invalid device ID", "INVALID_DEVICE_ID")),
            )
                .into_response();
        }
    };

    // Verify device belongs to account
    let devices = match DeviceDb::list_for_account(&state.db, account_id).await {
        Ok(devices) => devices,
        Err(e) => {
            tracing::error!("Database error: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Database error", "DB_ERROR")),
            )
                .into_response();
        }
    };

    let device_exists = devices.iter().any(|d| d.id == device_id);
    if !device_exists {
        return (
            StatusCode::NOT_FOUND,
            Json(ApiError::new("Device not found", "DEVICE_NOT_FOUND")),
        )
            .into_response();
    }

    // Delete device
    if let Err(e) = DeviceDb::delete(&state.db, device_uuid).await {
        tracing::error!("Database error: {}", e);
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiError::new("Failed to revoke device", "DB_ERROR")),
        )
            .into_response();
    }

    Json(serde_json::json!({"success": true})).into_response()
}

/// Revoke all other devices (except current)
pub async fn revoke_all_devices(
    State(state): State<Arc<AppState>>,
    headers: axum::http::HeaderMap,
) -> impl IntoResponse {
    let account_id = match extract_account_id_from_header(&headers, &state.jwt_secret) {
        Ok(id) => id,
        Err(e) => return e.into_response(),
    };

    // Get current device ID from header
    let current_device_id = headers
        .get("X-Device-ID")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| uuid::Uuid::parse_str(s).ok());

    let current_device_id = match current_device_id {
        Some(id) => id,
        None => {
            // Reject if no X-Device-ID header - we need to know which device to keep
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiError::new(
                    "X-Device-ID header required to revoke other devices",
                    "DEVICE_ID_REQUIRED",
                )),
            )
                .into_response();
        }
    };

    // Delete all devices except current
    match DeviceDb::delete_all_except(&state.db, account_id, current_device_id).await {
        Ok(count) => {
            Json(serde_json::json!({
                "success": true,
                "revoked": count
            })).into_response()
        }
        Err(e) => {
            tracing::error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiError::new("Failed to revoke devices", "DB_ERROR")),
            )
                .into_response()
        }
    }
}
