use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use validator::Validate;

use crate::models::{AckRequest, AckResponse, PollQuery, PollResponse};
use crate::AppState;

/// GET /relay/poll - Poll for pending messages
pub async fn poll(
    State(state): State<AppState>,
    Query(query): Query<PollQuery>,
) -> impl IntoResponse {
    // Validate query parameters
    if let Err(errors) = query.validate() {
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({
                "error": "Validation failed",
                "details": errors.to_string()
            })),
        )
            .into_response();
    }

    // Poll for messages
    match state
        .storage
        .poll_messages(&query.key_hash, query.limit, query.after.as_deref())
        .await
    {
        Ok((messages, has_more)) => {
            let next_cursor = if has_more {
                messages.last().map(|m| m.id.clone())
            } else {
                None
            };

            let response = PollResponse {
                messages,
                has_more,
                next_cursor,
            };

            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!(error = %e, key_hash = %query.key_hash, "Failed to poll messages");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "Failed to poll messages"})),
            )
                .into_response()
        }
    }
}

/// POST /relay/ack - Acknowledge receipt of messages (delete them)
pub async fn ack(
    State(state): State<AppState>,
    Json(request): Json<AckRequest>,
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

    // Delete acknowledged messages
    match state
        .storage
        .delete_messages(&request.key_hash, &request.message_ids)
        .await
    {
        Ok(deleted) => {
            let response = AckResponse { deleted };
            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!(
                error = %e,
                key_hash = %request.key_hash,
                count = request.message_ids.len(),
                "Failed to acknowledge messages"
            );
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "Failed to acknowledge messages"})),
            )
                .into_response()
        }
    }
}

/// GET /relay/pending - Get count of pending messages
pub async fn pending_count(
    State(state): State<AppState>,
    Query(params): Query<PendingQuery>,
) -> impl IntoResponse {
    if params.key_hash.is_empty() || params.key_hash.len() > 64 {
        return (
            StatusCode::BAD_REQUEST,
            Json(serde_json::json!({"error": "Invalid key_hash"})),
        )
            .into_response();
    }

    match state.storage.get_pending_count(&params.key_hash).await {
        Ok(count) => {
            (StatusCode::OK, Json(serde_json::json!({"count": count}))).into_response()
        }
        Err(e) => {
            tracing::error!(error = %e, "Failed to get pending count");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({"error": "Failed to get pending count"})),
            )
                .into_response()
        }
    }
}

#[derive(Debug, serde::Deserialize)]
pub struct PendingQuery {
    pub key_hash: String,
}
