use chrono::{DateTime, Duration, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::Account;

/// Database operations for accounts
pub struct AccountDb;

impl AccountDb {
    /// Create a new account
    pub async fn create(
        pool: &SqlitePool,
        handle: &str,
        display_name: &str,
        password_hash: Option<&str>,
        encrypted_email: Option<&[u8]>,
        email_nonce: Option<&[u8]>,
    ) -> sqlx::Result<Account> {
        let id = Uuid::new_v4();
        let now = Utc::now();
        let id_str = id.to_string();
        let handle_lower = handle.to_lowercase();

        sqlx::query(
            r#"
            INSERT INTO accounts (id, handle, display_name, password_hash, encrypted_email, email_nonce, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(&id_str)
        .bind(&handle_lower)
        .bind(display_name)
        .bind(password_hash)
        .bind(encrypted_email)
        .bind(email_nonce)
        .bind(now.to_rfc3339())
        .execute(pool)
        .await?;

        // Fetch the created account
        Self::find_by_id(pool, id).await?.ok_or(sqlx::Error::RowNotFound)
    }

    /// Find account by handle
    pub async fn find_by_handle(pool: &SqlitePool, handle: &str) -> sqlx::Result<Option<Account>> {
        sqlx::query_as::<_, Account>("SELECT * FROM accounts WHERE handle = ?")
            .bind(handle.to_lowercase())
            .fetch_optional(pool)
            .await
    }

    /// Find account by ID
    pub async fn find_by_id(pool: &SqlitePool, id: Uuid) -> sqlx::Result<Option<Account>> {
        sqlx::query_as::<_, Account>("SELECT * FROM accounts WHERE id = ?")
            .bind(id.to_string())
            .fetch_optional(pool)
            .await
    }

    /// Check if handle is available
    pub async fn handle_available(pool: &SqlitePool, handle: &str) -> sqlx::Result<bool> {
        let result: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM accounts WHERE handle = ?",
        )
        .bind(handle.to_lowercase())
        .fetch_one(pool)
        .await?;

        Ok(result.0 == 0)
    }

    /// Update last login timestamp
    pub async fn update_last_login(pool: &SqlitePool, id: Uuid) -> sqlx::Result<()> {
        sqlx::query("UPDATE accounts SET last_login_at = ? WHERE id = ?")
            .bind(Utc::now().to_rfc3339())
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }

    /// Update display name
    pub async fn update_display_name(
        pool: &SqlitePool,
        id: Uuid,
        display_name: &str,
    ) -> sqlx::Result<Account> {
        sqlx::query("UPDATE accounts SET display_name = ? WHERE id = ?")
            .bind(display_name)
            .bind(id.to_string())
            .execute(pool)
            .await?;

        Self::find_by_id(pool, id).await?.ok_or(sqlx::Error::RowNotFound)
    }

    /// Update passkey credentials
    pub async fn update_passkey(
        pool: &SqlitePool,
        id: Uuid,
        credential_id: &str,
        public_key: &[u8],
    ) -> sqlx::Result<()> {
        sqlx::query(
            "UPDATE accounts SET passkey_credential_id = ?, passkey_public_key = ? WHERE id = ?",
        )
        .bind(credential_id)
        .bind(public_key)
        .bind(id.to_string())
        .execute(pool)
        .await?;
        Ok(())
    }

    /// Update password hash
    pub async fn update_password(pool: &SqlitePool, id: Uuid, password_hash: &str) -> sqlx::Result<()> {
        sqlx::query("UPDATE accounts SET password_hash = ? WHERE id = ?")
            .bind(password_hash)
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }

    /// Update TOTP settings
    pub async fn update_totp(
        pool: &SqlitePool,
        id: Uuid,
        secret_encrypted: Option<&[u8]>,
        secret_nonce: Option<&[u8]>,
        enabled: bool,
        backup_codes_hash: Option<Vec<String>>,
    ) -> sqlx::Result<()> {
        // Store backup codes as JSON string for SQLite
        let backup_codes_json = backup_codes_hash.map(|codes| serde_json::to_string(&codes).unwrap_or_default());

        sqlx::query(
            r#"
            UPDATE accounts
            SET totp_secret_encrypted = ?,
                totp_secret_nonce = ?,
                totp_enabled = ?,
                backup_codes_hash = ?
            WHERE id = ?
            "#,
        )
        .bind(secret_encrypted)
        .bind(secret_nonce)
        .bind(enabled)
        .bind(backup_codes_json)
        .bind(id.to_string())
        .execute(pool)
        .await?;
        Ok(())
    }

    /// Update email verification status
    pub async fn update_email_verified(pool: &SqlitePool, id: Uuid, verified: bool) -> sqlx::Result<()> {
        sqlx::query("UPDATE accounts SET email_verified = ? WHERE id = ?")
            .bind(verified)
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }

    /// Update encrypted key backup
    pub async fn update_key_backup(
        pool: &SqlitePool,
        id: Uuid,
        encrypted_backup: &[u8],
        backup_nonce: &[u8],
    ) -> sqlx::Result<()> {
        sqlx::query(
            "UPDATE accounts SET encrypted_key_backup = ?, key_backup_nonce = ? WHERE id = ?",
        )
        .bind(encrypted_backup)
        .bind(backup_nonce)
        .bind(id.to_string())
        .execute(pool)
        .await?;
        Ok(())
    }

    /// Remove a used backup code
    pub async fn remove_backup_code(pool: &SqlitePool, id: Uuid, code_index: usize) -> sqlx::Result<()> {
        // Get current backup codes
        let account = Self::find_by_id(pool, id).await?.ok_or(sqlx::Error::RowNotFound)?;

        // Parse backup codes from JSON string
        if let Some(mut codes) = account.backup_codes() {
            if code_index < codes.len() {
                codes.remove(code_index);
                let codes_json = serde_json::to_string(&codes).unwrap_or_default();
                sqlx::query("UPDATE accounts SET backup_codes_hash = ? WHERE id = ?")
                    .bind(codes_json)
                    .bind(id.to_string())
                    .execute(pool)
                    .await?;
            }
        }
        Ok(())
    }

    /// Delete account
    pub async fn delete(pool: &SqlitePool, id: Uuid) -> sqlx::Result<()> {
        sqlx::query("DELETE FROM accounts WHERE id = ?")
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }
}

/// Database operations for recovery tokens
pub struct RecoveryTokenDb;

impl RecoveryTokenDb {
    /// Create a recovery token
    pub async fn create(
        pool: &SqlitePool,
        account_id: Uuid,
        token_hash: &str,
        expires_in_hours: i64,
    ) -> sqlx::Result<Uuid> {
        let id = Uuid::new_v4();
        let expires_at = Utc::now() + Duration::hours(expires_in_hours);

        sqlx::query(
            r#"
            INSERT INTO recovery_tokens (id, account_id, token_hash, expires_at, created_at, used)
            VALUES (?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(id.to_string())
        .bind(account_id.to_string())
        .bind(token_hash)
        .bind(expires_at.to_rfc3339())
        .bind(Utc::now().to_rfc3339())
        .bind(false)
        .execute(pool)
        .await?;

        Ok(id)
    }

    /// Find valid recovery token by hash
    pub async fn find_valid_by_hash(
        pool: &SqlitePool,
        token_hash: &str,
    ) -> sqlx::Result<Option<(Uuid, Uuid)>> {
        let result: Option<(String, String)> = sqlx::query_as(
            r#"
            SELECT id, account_id
            FROM recovery_tokens
            WHERE token_hash = ?
              AND expires_at > ?
              AND used = 0
            "#,
        )
        .bind(token_hash)
        .bind(Utc::now().to_rfc3339())
        .fetch_optional(pool)
        .await?;

        Ok(result.map(|(id, account_id)| {
            (
                Uuid::parse_str(&id).unwrap_or_default(),
                Uuid::parse_str(&account_id).unwrap_or_default(),
            )
        }))
    }

    /// Mark token as used
    pub async fn mark_used(pool: &SqlitePool, id: Uuid) -> sqlx::Result<()> {
        sqlx::query("UPDATE recovery_tokens SET used = 1 WHERE id = ?")
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }

    /// Delete expired tokens (cleanup)
    pub async fn delete_expired(pool: &SqlitePool) -> sqlx::Result<u64> {
        let result = sqlx::query("DELETE FROM recovery_tokens WHERE expires_at < ?")
            .bind(Utc::now().to_rfc3339())
            .execute(pool)
            .await?;
        Ok(result.rows_affected())
    }
}

/// Database operations for devices
pub struct DeviceDb;

impl DeviceDb {
    /// Register a new device
    pub async fn create(
        pool: &SqlitePool,
        account_id: Uuid,
        name: &str,
        platform: &str,
    ) -> sqlx::Result<Uuid> {
        let id = Uuid::new_v4();
        let now = Utc::now();

        sqlx::query(
            r#"
            INSERT INTO devices (id, account_id, name, platform, last_seen_at, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(id.to_string())
        .bind(account_id.to_string())
        .bind(name)
        .bind(platform)
        .bind(now.to_rfc3339())
        .bind(now.to_rfc3339())
        .execute(pool)
        .await?;

        Ok(id)
    }

    /// Update device last seen
    pub async fn update_last_seen(pool: &SqlitePool, id: Uuid) -> sqlx::Result<()> {
        sqlx::query("UPDATE devices SET last_seen_at = ? WHERE id = ?")
            .bind(Utc::now().to_rfc3339())
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }

    /// List devices for account
    pub async fn list_for_account(
        pool: &SqlitePool,
        account_id: Uuid,
    ) -> sqlx::Result<Vec<crate::models::Device>> {
        sqlx::query_as("SELECT * FROM devices WHERE account_id = ? ORDER BY last_seen_at DESC")
            .bind(account_id.to_string())
            .fetch_all(pool)
            .await
    }

    /// Delete device
    pub async fn delete(pool: &SqlitePool, id: Uuid) -> sqlx::Result<()> {
        sqlx::query("DELETE FROM devices WHERE id = ?")
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }

    /// Delete all devices for account except one
    pub async fn delete_all_except(pool: &SqlitePool, account_id: Uuid, keep_id: Uuid) -> sqlx::Result<u64> {
        let result = sqlx::query("DELETE FROM devices WHERE account_id = ? AND id != ?")
            .bind(account_id.to_string())
            .bind(keep_id.to_string())
            .execute(pool)
            .await?;
        Ok(result.rows_affected())
    }
}

/// Database operations for email verification tokens
pub struct EmailVerificationTokenDb;

impl EmailVerificationTokenDb {
    /// Create an email verification token
    pub async fn create(
        pool: &SqlitePool,
        account_id: Uuid,
        token_hash: &str,
        expires_in_hours: i64,
    ) -> sqlx::Result<Uuid> {
        let id = Uuid::new_v4();
        let expires_at = Utc::now() + Duration::hours(expires_in_hours);

        // Delete any existing tokens for this account first
        sqlx::query("DELETE FROM email_verification_tokens WHERE account_id = ?")
            .bind(account_id.to_string())
            .execute(pool)
            .await?;

        sqlx::query(
            r#"
            INSERT INTO email_verification_tokens (id, account_id, token_hash, expires_at, created_at)
            VALUES (?, ?, ?, ?, ?)
            "#,
        )
        .bind(id.to_string())
        .bind(account_id.to_string())
        .bind(token_hash)
        .bind(expires_at.to_rfc3339())
        .bind(Utc::now().to_rfc3339())
        .execute(pool)
        .await?;

        Ok(id)
    }

    /// Find valid email verification token by hash
    pub async fn find_valid_by_hash(
        pool: &SqlitePool,
        token_hash: &str,
    ) -> sqlx::Result<Option<(Uuid, Uuid)>> {
        let result: Option<(String, String)> = sqlx::query_as(
            r#"
            SELECT id, account_id
            FROM email_verification_tokens
            WHERE token_hash = ?
              AND expires_at > ?
            "#,
        )
        .bind(token_hash)
        .bind(Utc::now().to_rfc3339())
        .fetch_optional(pool)
        .await?;

        Ok(result.map(|(id, account_id)| {
            (
                Uuid::parse_str(&id).unwrap_or_default(),
                Uuid::parse_str(&account_id).unwrap_or_default(),
            )
        }))
    }

    /// Delete token after use
    pub async fn delete(pool: &SqlitePool, id: Uuid) -> sqlx::Result<()> {
        sqlx::query("DELETE FROM email_verification_tokens WHERE id = ?")
            .bind(id.to_string())
            .execute(pool)
            .await?;
        Ok(())
    }

    /// Delete expired tokens (cleanup)
    pub async fn delete_expired(pool: &SqlitePool) -> sqlx::Result<u64> {
        let result = sqlx::query("DELETE FROM email_verification_tokens WHERE expires_at < ?")
            .bind(Utc::now().to_rfc3339())
            .execute(pool)
            .await?;
        Ok(result.rows_affected())
    }
}
