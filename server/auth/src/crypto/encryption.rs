use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use rand::RngCore;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum EncryptionError {
    #[error("Encryption failed")]
    EncryptionFailed,
    #[error("Decryption failed")]
    DecryptionFailed,
    #[error("Invalid key length")]
    InvalidKeyLength,
    #[error("Invalid nonce length")]
    InvalidNonceLength,
}

/// Encrypt data using AES-256-GCM
pub fn encrypt(data: &[u8], key: &[u8; 32]) -> Result<(Vec<u8>, [u8; 12]), EncryptionError> {
    let cipher = Aes256Gcm::new(key.into());

    // Generate random nonce
    let mut nonce_bytes = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, data)
        .map_err(|_| EncryptionError::EncryptionFailed)?;

    Ok((ciphertext, nonce_bytes))
}

/// Decrypt data using AES-256-GCM
pub fn decrypt(
    ciphertext: &[u8],
    key: &[u8; 32],
    nonce: &[u8; 12],
) -> Result<Vec<u8>, EncryptionError> {
    let cipher = Aes256Gcm::new(key.into());
    let nonce = Nonce::from_slice(nonce);

    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|_| EncryptionError::DecryptionFailed)
}

/// Encrypt email address with the server's email encryption key
pub fn encrypt_email(email: &str, key: &[u8; 32]) -> Result<(Vec<u8>, [u8; 12]), EncryptionError> {
    encrypt(email.as_bytes(), key)
}

/// Decrypt email address
pub fn decrypt_email(
    ciphertext: &[u8],
    key: &[u8; 32],
    nonce: &[u8; 12],
) -> Result<String, EncryptionError> {
    let plaintext = decrypt(ciphertext, key, nonce)?;
    String::from_utf8(plaintext).map_err(|_| EncryptionError::DecryptionFailed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt() {
        let key = [0u8; 32];
        let data = b"Hello, World!";

        let (ciphertext, nonce) = encrypt(data, &key).expect("Encryption should succeed");
        let decrypted = decrypt(&ciphertext, &key, &nonce).expect("Decryption should succeed");

        assert_eq!(data.to_vec(), decrypted);
    }

    #[test]
    fn test_encrypt_email() {
        let key = [1u8; 32];
        let email = "test@example.com";

        let (ciphertext, nonce) = encrypt_email(email, &key).expect("Encryption should succeed");
        let decrypted = decrypt_email(&ciphertext, &key, &nonce).expect("Decryption should succeed");

        assert_eq!(email, decrypted);
    }
}
