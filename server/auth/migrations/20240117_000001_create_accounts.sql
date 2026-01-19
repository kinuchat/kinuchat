-- Create accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY,
    handle VARCHAR(20) NOT NULL UNIQUE,
    display_name VARCHAR(50) NOT NULL,

    -- Passkey (WebAuthn)
    passkey_credential_id TEXT,
    passkey_public_key BYTEA,

    -- Password fallback (Argon2id hash)
    password_hash TEXT,

    -- Recovery email (encrypted with server key)
    encrypted_email BYTEA,
    email_nonce BYTEA,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,

    -- 2FA (TOTP)
    totp_secret_encrypted BYTEA,
    totp_secret_nonce BYTEA,
    totp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    backup_codes_hash TEXT[],

    -- Encrypted key backup (for password users)
    encrypted_key_backup BYTEA,
    key_backup_nonce BYTEA,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

-- Index for handle lookups
CREATE INDEX IF NOT EXISTS idx_accounts_handle ON accounts(handle);

-- Index for passkey lookups
CREATE INDEX IF NOT EXISTS idx_accounts_passkey_credential ON accounts(passkey_credential_id) WHERE passkey_credential_id IS NOT NULL;

-- Create devices table
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    platform VARCHAR(50) NOT NULL,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for device lookups by account
CREATE INDEX IF NOT EXISTS idx_devices_account ON devices(account_id);

-- Create recovery tokens table
CREATE TABLE IF NOT EXISTS recovery_tokens (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for token lookups
CREATE INDEX IF NOT EXISTS idx_recovery_tokens_hash ON recovery_tokens(token_hash) WHERE used = FALSE;

-- Index for cleanup of expired tokens
CREATE INDEX IF NOT EXISTS idx_recovery_tokens_expires ON recovery_tokens(expires_at);

-- Reserved handles (prevent registration of these)
CREATE TABLE IF NOT EXISTS reserved_handles (
    handle VARCHAR(20) PRIMARY KEY
);

-- Insert reserved handles
INSERT INTO reserved_handles (handle) VALUES
    ('admin'),
    ('administrator'),
    ('meshlink'),
    ('support'),
    ('help'),
    ('system'),
    ('official'),
    ('security'),
    ('root'),
    ('mod'),
    ('moderator')
ON CONFLICT (handle) DO NOTHING;
