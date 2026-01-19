use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

#[derive(Error, Debug)]
pub enum JwtError {
    #[error("Token creation failed")]
    CreationFailed,
    #[error("Token validation failed")]
    ValidationFailed,
    #[error("Token expired")]
    Expired,
    #[error("Invalid token")]
    Invalid,
}

/// JWT claims for access tokens
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    /// Subject (account ID)
    pub sub: String,
    /// Handle
    pub handle: String,
    /// Expiration time (Unix timestamp)
    pub exp: i64,
    /// Issued at (Unix timestamp)
    pub iat: i64,
    /// Token type
    pub token_type: String,
}

/// Create an access token for an account
pub fn create_access_token(
    account_id: &str,
    handle: &str,
    secret: &str,
    expires_in_hours: i64,
) -> Result<String, JwtError> {
    let now = Utc::now();
    let expiration = now + Duration::hours(expires_in_hours);

    let claims = Claims {
        sub: account_id.to_string(),
        handle: handle.to_string(),
        exp: expiration.timestamp(),
        iat: now.timestamp(),
        token_type: "access".to_string(),
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|_| JwtError::CreationFailed)
}

/// Validate and decode an access token
pub fn validate_access_token(token: &str, secret: &str) -> Result<Claims, JwtError> {
    let validation = Validation::default();

    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    )
    .map(|data| data.claims)
    .map_err(|e| match e.kind() {
        jsonwebtoken::errors::ErrorKind::ExpiredSignature => JwtError::Expired,
        _ => JwtError::Invalid,
    })
}

/// Extract account ID from token (returns UUID)
pub fn extract_account_id(token: &str, secret: &str) -> Result<Uuid, JwtError> {
    let claims = validate_access_token(token, secret)?;
    Uuid::parse_str(&claims.sub).map_err(|_| JwtError::Invalid)
}

/// Extract account ID from token as string
pub fn extract_account_id_str(token: &str, secret: &str) -> Result<String, JwtError> {
    let claims = validate_access_token(token, secret)?;
    Ok(claims.sub)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_and_validate_token() {
        let account_id = Uuid::new_v4().to_string();
        let handle = "testuser";
        let secret = "test-secret-key";

        let token = create_access_token(&account_id, handle, secret, 24)
            .expect("Token creation should succeed");

        let claims = validate_access_token(&token, secret).expect("Validation should succeed");

        assert_eq!(claims.sub, account_id);
        assert_eq!(claims.handle, handle);
        assert_eq!(claims.token_type, "access");
    }

    #[test]
    fn test_invalid_secret_fails() {
        let account_id = Uuid::new_v4().to_string();
        let token = create_access_token(&account_id, "user", "secret1", 24).unwrap();

        let result = validate_access_token(&token, "secret2");
        assert!(result.is_err());
    }
}
