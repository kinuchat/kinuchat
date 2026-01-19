use rand::Rng;
use sha2::{Digest, Sha256};
use thiserror::Error;
use totp_rs::{Algorithm, Secret, TOTP};

#[derive(Error, Debug)]
pub enum TotpError {
    #[error("Failed to generate TOTP secret")]
    SecretGenerationFailed,
    #[error("Failed to create TOTP instance")]
    TotpCreationFailed,
    #[error("Invalid TOTP code")]
    InvalidCode,
    #[error("QR code generation failed")]
    QrCodeFailed,
}

/// TOTP configuration
pub struct TotpConfig {
    pub secret: Vec<u8>,
    pub issuer: String,
    pub account_name: String,
}

impl TotpConfig {
    /// Generate a new TOTP configuration with random secret
    pub fn new(account_name: &str) -> Result<Self, TotpError> {
        let secret = Secret::generate_secret();
        Ok(Self {
            secret: secret.to_bytes().map_err(|_| TotpError::SecretGenerationFailed)?,
            issuer: "MeshLink".to_string(),
            account_name: account_name.to_string(),
        })
    }

    /// Create TOTP from existing secret
    pub fn from_secret(secret: Vec<u8>, account_name: &str) -> Self {
        Self {
            secret,
            issuer: "MeshLink".to_string(),
            account_name: account_name.to_string(),
        }
    }

    /// Get the TOTP instance
    fn totp(&self) -> Result<TOTP, TotpError> {
        TOTP::new(
            Algorithm::SHA1,
            6,
            1,
            30,
            self.secret.clone(),
            Some(self.issuer.clone()),
            self.account_name.clone(),
        )
        .map_err(|_| TotpError::TotpCreationFailed)
    }

    /// Generate current TOTP code
    pub fn generate_code(&self) -> Result<String, TotpError> {
        let totp = self.totp()?;
        Ok(totp.generate_current().map_err(|_| TotpError::TotpCreationFailed)?)
    }

    /// Verify a TOTP code
    pub fn verify_code(&self, code: &str) -> Result<bool, TotpError> {
        let totp = self.totp()?;
        Ok(totp.check_current(code).map_err(|_| TotpError::InvalidCode)?)
    }

    /// Get the secret as base32 string (for manual entry)
    pub fn secret_base32(&self) -> String {
        base32::encode(base32::Alphabet::Rfc4648 { padding: false }, &self.secret)
    }

    /// Get the otpauth:// URL for QR codes
    pub fn otpauth_url(&self) -> Result<String, TotpError> {
        let totp = self.totp()?;
        Ok(totp.get_url())
    }

    /// Generate QR code as base64-encoded PNG
    pub fn qr_code_base64(&self) -> Result<String, TotpError> {
        let totp = self.totp()?;
        // Generate QR code using qrcode crate would be needed here
        // For now, return the URL which clients can use to generate their own QR
        // In production, use qrcode crate to generate PNG
        let url = totp.get_url();
        // Return URL encoded as base64 placeholder
        Ok(base64::Engine::encode(&base64::engine::general_purpose::STANDARD, url.as_bytes()))
    }
}

/// Generate backup codes (one-time use codes)
pub fn generate_backup_codes(count: usize) -> Vec<String> {
    let mut rng = rand::thread_rng();
    (0..count)
        .map(|_| {
            let code: u64 = rng.gen_range(100_000_000..1_000_000_000);
            format!("{:09}", code)
        })
        .collect()
}

/// Hash backup codes for storage
pub fn hash_backup_codes(codes: &[String]) -> Vec<String> {
    codes
        .iter()
        .map(|code| {
            let mut hasher = Sha256::new();
            hasher.update(code.as_bytes());
            hex::encode(hasher.finalize())
        })
        .collect()
}

/// Verify a backup code against hashed codes
pub fn verify_backup_code(code: &str, hashed_codes: &[String]) -> Option<usize> {
    let mut hasher = Sha256::new();
    hasher.update(code.as_bytes());
    let code_hash = hex::encode(hasher.finalize());

    hashed_codes.iter().position(|h| h == &code_hash)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_totp_generation_and_verification() {
        let config = TotpConfig::new("test@example.com").expect("Should create config");
        let code = config.generate_code().expect("Should generate code");

        assert_eq!(code.len(), 6);
        assert!(config.verify_code(&code).expect("Should verify"));
    }

    #[test]
    fn test_backup_codes() {
        let codes = generate_backup_codes(10);
        assert_eq!(codes.len(), 10);

        let hashed = hash_backup_codes(&codes);
        assert_eq!(hashed.len(), 10);

        // Verify first code
        let index = verify_backup_code(&codes[0], &hashed);
        assert_eq!(index, Some(0));

        // Invalid code should return None
        let invalid = verify_backup_code("000000000", &hashed);
        assert_eq!(invalid, None);
    }
}
