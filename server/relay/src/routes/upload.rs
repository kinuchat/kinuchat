use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use validator::Validate;

use crate::models::{RateLimitInfo, UploadRequest, UploadResponse};
use crate::AppState;

/// POST /relay/upload - Upload an encrypted message for relay
pub async fn upload(
    State(state): State<AppState>,
    Json(request): Json<UploadRequest>,
) -> impl IntoResponse {
    // Validate request
    if let Err(errors) = request.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({
                "error": "Validation failed",
                "details": errors.to_string()
            })),
        )
            .into_response();
    }

    let envelope = request.envelope;

    // Check payload size
    if envelope.encrypted_payload.len() > state.config.max_payload_bytes {
        return (
            StatusCode::PAYLOAD_TOO_LARGE,
            Json(serde_json::json!({
                "error": "Payload too large",
                "max_bytes": state.config.max_payload_bytes
            })),
        )
            .into_response();
    }

    // Check rate limit
    let (allowed, remaining, reset_at) = match state
        .storage
        .check_rate_limit(&envelope.recipient_key_hash, state.config.rate_limit_per_minute)
        .await
    {
        Ok(result) => result,
        Err(e) => {
            tracing::error!(error = %e, "Rate limit check failed");
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "Internal server error"})),
            )
                .into_response();
        }
    };

    if !allowed {
        let rate_info = RateLimitInfo {
            remaining: 0,
            reset_at,
        };
        return (
            StatusCode::TOO_MANY_REQUESTS,
            Json(serde_json::json!({
                "error": "Rate limit exceeded",
                "rate_limit": rate_info
            })),
        )
            .into_response();
    }

    // Clamp TTL to configured maximum
    let mut envelope = envelope;
    if envelope.ttl_hours > state.config.max_ttl_hours {
        envelope.ttl_hours = state.config.max_ttl_hours;
    }

    // Store message
    match state.storage.store_message(envelope).await {
        Ok((id, expires_at)) => {
            let response = UploadResponse { id, expires_at };

            // TODO: Notify WebSocket subscribers
            // This would be done via a channel to the WebSocket handler

            (StatusCode::CREATED, Json(serde_json::json!(response))).into_response()
        }
        Err(e) => {
            let msg = e.to_string();
            if msg.contains("Duplicate nonce") {
                return (
                    StatusCode::CONFLICT,
                    Json(serde_json::json!({"error": msg})),
                )
                    .into_response();
            }

            tracing::error!(error = %e, "Failed to store message");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "Failed to store message"})),
            )
                .into_response()
        }
    }
}
