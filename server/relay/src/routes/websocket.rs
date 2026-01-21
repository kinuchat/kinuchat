use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        State,
    },
    response::IntoResponse,
};
use futures_util::{SinkExt, StreamExt};
use std::time::Duration;
use tokio::time::interval;

use crate::models::WsMessage;
use crate::AppState;

/// WebSocket connection handler
pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state))
}

async fn handle_socket(socket: WebSocket, state: AppState) {
    let (mut sender, mut receiver) = socket.split();

    // Track subscribed key hashes for this connection
    let mut subscribed_key_hash: Option<String> = None;

    // Ping interval for keepalive
    let mut ping_interval = interval(Duration::from_secs(30));

    // Poll interval for checking new messages
    let mut poll_interval = interval(Duration::from_secs(2));

    loop {
        tokio::select! {
            // Handle incoming messages from client
            Some(msg) = receiver.next() => {
                match msg {
                    Ok(Message::Text(text)) => {
                        match serde_json::from_str::<WsMessage>(&text) {
                            Ok(ws_msg) => {
                                match ws_msg {
                                    WsMessage::Subscribe { key_hash } => {
                                        // Validate key hash
                                        if key_hash.is_empty() || key_hash.len() > 64 {
                                            let error = WsMessage::Error {
                                                message: "Invalid key_hash".to_string(),
                                            };
                                            let _ = sender.send(Message::Text(
                                                serde_json::to_string(&error).unwrap().into()
                                            )).await;
                                            continue;
                                        }

                                        subscribed_key_hash = Some(key_hash.clone());
                                        tracing::debug!(key_hash = %key_hash, "WebSocket subscribed");

                                        let response = WsMessage::Subscribed { key_hash };
                                        let _ = sender.send(Message::Text(
                                            serde_json::to_string(&response).unwrap().into()
                                        )).await;
                                    }

                                    WsMessage::Ack { message_ids } => {
                                        if let Some(ref key_hash) = subscribed_key_hash {
                                            match state.storage.delete_messages(key_hash, &message_ids).await {
                                                Ok(deleted) => {
                                                    let response = WsMessage::Acked { deleted };
                                                    let _ = sender.send(Message::Text(
                                                        serde_json::to_string(&response).unwrap().into()
                                                    )).await;
                                                }
                                                Err(e) => {
                                                    tracing::error!(error = %e, "WebSocket ack failed");
                                                    let error = WsMessage::Error {
                                                        message: "Failed to acknowledge messages".to_string(),
                                                    };
                                                    let _ = sender.send(Message::Text(
                                                        serde_json::to_string(&error).unwrap().into()
                                                    )).await;
                                                }
                                            }
                                        } else {
                                            let error = WsMessage::Error {
                                                message: "Not subscribed".to_string(),
                                            };
                                            let _ = sender.send(Message::Text(
                                                serde_json::to_string(&error).unwrap().into()
                                            )).await;
                                        }
                                    }

                                    WsMessage::Ping => {
                                        let response = WsMessage::Pong;
                                        let _ = sender.send(Message::Text(
                                            serde_json::to_string(&response).unwrap().into()
                                        )).await;
                                    }

                                    _ => {
                                        // Ignore other message types from client
                                    }
                                }
                            }
                            Err(e) => {
                                tracing::warn!(error = %e, "Failed to parse WebSocket message");
                                let error = WsMessage::Error {
                                    message: "Invalid message format".to_string(),
                                };
                                let _ = sender.send(Message::Text(
                                    serde_json::to_string(&error).unwrap().into()
                                )).await;
                            }
                        }
                    }
                    Ok(Message::Binary(_)) => {
                        // Binary messages not supported
                        let error = WsMessage::Error {
                            message: "Binary messages not supported".to_string(),
                        };
                        let _ = sender.send(Message::Text(
                            serde_json::to_string(&error).unwrap().into()
                        )).await;
                    }
                    Ok(Message::Ping(data)) => {
                        let _ = sender.send(Message::Pong(data)).await;
                    }
                    Ok(Message::Close(_)) => {
                        tracing::debug!("WebSocket closed by client");
                        break;
                    }
                    Err(e) => {
                        tracing::debug!(error = %e, "WebSocket error");
                        break;
                    }
                    _ => {}
                }
            }

            // Poll for new messages periodically
            _ = poll_interval.tick() => {
                if let Some(ref key_hash) = subscribed_key_hash {
                    // Poll for new messages
                    match state.storage.poll_messages(key_hash, 10, None).await {
                        Ok((messages, _)) => {
                            for envelope in messages {
                                let msg = WsMessage::NewMessage { envelope };
                                if sender.send(Message::Text(
                                    serde_json::to_string(&msg).unwrap().into()
                                )).await.is_err() {
                                    // Connection closed
                                    break;
                                }
                            }
                        }
                        Err(e) => {
                            tracing::error!(error = %e, "Failed to poll messages for WebSocket");
                        }
                    }
                }
            }

            // Send ping for keepalive
            _ = ping_interval.tick() => {
                if sender.send(Message::Ping(vec![].into())).await.is_err() {
                    // Connection closed
                    break;
                }
            }
        }
    }

    if let Some(key_hash) = subscribed_key_hash {
        tracing::debug!(key_hash = %key_hash, "WebSocket disconnected");
    }
}
