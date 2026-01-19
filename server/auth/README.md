# Kinu Auth Server

A Rust authentication server for the Kinu messaging app, built with Axum.

## Features

- **Passkey/WebAuthn** - Passwordless authentication using platform authenticators
- **Password Authentication** - Traditional login with Argon2id password hashing
- **Two-Factor Authentication** - TOTP-based 2FA with backup codes
- **Device Management** - Track logged-in devices, revoke sessions
- **Email Verification** - SMTP-based email verification
- **Account Recovery** - Email-based password recovery
- **Data Export** - GDPR-compliant data export
- **Matrix Integration** - Auto-creates Matrix accounts on registration

## Tech Stack

- **Framework**: Axum 0.8
- **Database**: SQLite (via SQLx)
- **Auth**: JWT tokens, WebAuthn, Argon2id
- **Email**: Lettre SMTP client
- **Crypto**: AES-256-GCM for email encryption at rest

## Quick Start

### Prerequisites

- Rust 1.75+
- SQLite

### Development Setup

```bash
# Clone and enter directory
cd server/auth

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env

# Run the server
cargo run
```

The server will start at `http://localhost:3000`.

### Health Check

```bash
curl http://localhost:3000/health
# Returns: OK
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | No | `sqlite:./kinu_auth.db?mode=rwc` | SQLite database path |
| `LISTEN_ADDR` | No | `0.0.0.0:3000` | Server listen address |
| `JWT_SECRET` | **Yes*** | `development-secret...` | JWT signing secret (32+ chars) |
| `EMAIL_ENCRYPTION_KEY` | **Yes*** | Dev key | 32-byte hex key for email encryption |
| `WEBAUTHN_RP_ID` | No | `meshlink.app` | WebAuthn relying party ID (your domain) |
| `WEBAUTHN_RP_ORIGIN` | No | `https://meshlink.app` | WebAuthn origin URL |
| `MATRIX_HOMESERVER_URL` | No | `http://localhost:8008` | Matrix server URL |
| `MATRIX_SERVER_NAME` | No | `localhost` | Matrix server name |
| `MATRIX_REGISTRATION_SECRET` | No | - | Dendrite registration shared secret |
| `SMTP_HOST` | No | - | SMTP server hostname |
| `SMTP_PORT` | No | `587` | SMTP server port |
| `SMTP_USERNAME` | No | - | SMTP username |
| `SMTP_PASSWORD` | No | - | SMTP password |
| `SMTP_FROM_ADDRESS` | No | SMTP_USERNAME | From email address |
| `SMTP_FROM_NAME` | No | `Kinu` | From display name |
| `APP_URL` | No | `https://kinuchat.com` | App URL for email links |

*Required in production - defaults are only for development.

### Example .env

```env
DATABASE_URL=sqlite:./kinu_auth.db?mode=rwc
LISTEN_ADDR=0.0.0.0:3000
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
EMAIL_ENCRYPTION_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# WebAuthn (use your domain)
WEBAUTHN_RP_ID=kinuchat.com
WEBAUTHN_RP_ORIGIN=https://kinuchat.com

# Matrix integration
MATRIX_HOMESERVER_URL=https://matrix.kinuchat.com
MATRIX_SERVER_NAME=kinuchat.com
MATRIX_REGISTRATION_SECRET=your-dendrite-shared-secret

# Email (optional - for verification/recovery)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=noreply@kinuchat.com
SMTP_PASSWORD=your-smtp-password
SMTP_FROM_ADDRESS=noreply@kinuchat.com
SMTP_FROM_NAME=Kinu
APP_URL=https://kinuchat.com
```

## API Reference

All endpoints return JSON. Errors follow the format:
```json
{
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

### Authentication

Most endpoints require a JWT token in the `Authorization` header:
```
Authorization: Bearer <token>
```

Device tracking requires the `X-Device-ID` header:
```
X-Device-ID: <device-uuid>
```

---

### Account Endpoints

#### `POST /api/v1/accounts/register`

Create a new account.

**Request:**
```json
{
  "handle": "username",
  "displayName": "Display Name",
  "password": "securepassword123",
  "email": "user@example.com",
  "deviceName": "iPhone 15 Pro",
  "devicePlatform": "iOS"
}
```

**Response:** `201 Created`
```json
{
  "token": "jwt-token",
  "account": {
    "id": "uuid",
    "handle": "username",
    "displayName": "Display Name",
    "hasPasskey": false,
    "hasPassword": true,
    "hasEmail": true,
    "emailVerified": false,
    "totpEnabled": false,
    "createdAt": "2024-01-01T00:00:00Z"
  },
  "deviceId": "device-uuid",
  "matrix": {
    "userId": "@username:kinuchat.com",
    "accessToken": "",
    "deviceId": "",
    "homeserverUrl": "https://matrix.kinuchat.com"
  }
}
```

#### `POST /api/v1/accounts/login`

Login with password.

**Request:**
```json
{
  "handle": "username",
  "password": "securepassword123",
  "totpCode": "123456",
  "deviceName": "iPhone 15 Pro",
  "devicePlatform": "iOS"
}
```

**Response:** `200 OK` - Same as register response

#### `GET /api/v1/accounts/check-handle?handle=username`

Check if a handle is available.

**Response:**
```json
{
  "available": true,
  "handle": "username"
}
```

#### `GET /api/v1/accounts/me`

Get current account info. **Requires auth.**

**Response:**
```json
{
  "id": "uuid",
  "handle": "username",
  "displayName": "Display Name",
  "hasPasskey": false,
  "hasPassword": true,
  "hasEmail": true,
  "emailVerified": true,
  "totpEnabled": false,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

#### `POST /api/v1/accounts/me`

Update account. **Requires auth.**

**Request:**
```json
{
  "display_name": "New Display Name"
}
```

#### `DELETE /api/v1/accounts/me`

Delete account. **Requires auth.**

**Request:**
```json
{
  "password": "currentpassword"
}
```

#### `POST /api/v1/accounts/change-password`

Change password. **Requires auth.**

**Request:**
```json
{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword123"
}
```

#### `POST /api/v1/accounts/update-email`

Update recovery email. **Requires auth.**

**Request:**
```json
{
  "email": "newemail@example.com",
  "password": "currentpassword"
}
```

#### `POST /api/v1/accounts/resend-verification`

Resend email verification. **Requires auth.**

#### `POST /api/v1/accounts/verify-email`

Verify email with token.

**Request:**
```json
{
  "token": "verification-token"
}
```

#### `DELETE /api/v1/accounts/email`

Remove recovery email. **Requires auth.**

#### `GET /api/v1/accounts/export`

Export user data (GDPR). **Requires auth.**

**Response:**
```json
{
  "exportedAt": "2024-01-01T00:00:00Z",
  "account": {
    "id": "uuid",
    "handle": "username",
    "displayName": "Display Name",
    "hasEmail": true,
    "emailVerified": true,
    "createdAt": "2024-01-01T00:00:00Z"
  },
  "devices": [
    {
      "id": "device-uuid",
      "name": "iPhone 15 Pro",
      "platform": "iOS",
      "firstSeen": "2024-01-01T00:00:00Z",
      "lastActive": "2024-01-02T00:00:00Z"
    }
  ],
  "security": {
    "hasPasskey": false,
    "hasPassword": true,
    "totpEnabled": true,
    "backupCodesRemaining": 8
  }
}
```

---

### Device Endpoints

#### `GET /api/v1/devices`

List all devices. **Requires auth + X-Device-ID.**

**Response:**
```json
{
  "devices": [
    {
      "id": "device-uuid",
      "name": "iPhone 15 Pro",
      "type": "iOS",
      "lastActiveAt": "2024-01-02T00:00:00Z",
      "isCurrent": true,
      "location": null
    }
  ]
}
```

#### `DELETE /api/v1/devices/{id}`

Revoke a specific device. **Requires auth + X-Device-ID.**

#### `POST /api/v1/devices/revoke-all`

Revoke all other devices. **Requires auth + X-Device-ID.**

---

### Passkey Endpoints

#### `POST /api/v1/passkey/register/start`

Start passkey registration. **Requires auth.**

**Request:**
```json
{
  "handle": "username"
}
```

**Response:**
```json
{
  "options": { /* WebAuthn creation options */ },
  "sessionId": "session-uuid"
}
```

#### `POST /api/v1/passkey/register/finish`

Complete passkey registration. **Requires auth.**

**Request:**
```json
{
  "sessionId": "session-uuid",
  "credential": { /* WebAuthn credential response */ }
}
```

#### `POST /api/v1/passkey/authenticate/start`

Start passkey authentication.

**Request:**
```json
{
  "handle": "username"
}
```

#### `POST /api/v1/passkey/authenticate/finish`

Complete passkey authentication.

**Request:**
```json
{
  "sessionId": "session-uuid",
  "credential": { /* WebAuthn credential response */ }
}
```

---

### 2FA (TOTP) Endpoints

#### `POST /api/v1/2fa/setup`

Generate TOTP secret and QR code. **Requires auth.**

**Response:**
```json
{
  "secret": "BASE32SECRET",
  "otpauth_url": "otpauth://totp/Kinu:username?...",
  "qr_code_base64": "data:image/png;base64,..."
}
```

#### `POST /api/v1/2fa/verify`

Verify TOTP code and enable 2FA. **Requires auth.**

**Request:**
```json
{
  "code": "123456"
}
```

**Response:**
```json
{
  "backup_codes": ["code1", "code2", "..."]
}
```

#### `POST /api/v1/2fa/disable`

Disable 2FA. **Requires auth.**

**Request:**
```json
{
  "code": "123456"
}
```

#### `GET /api/v1/2fa/backup-codes`

Generate new backup codes. **Requires auth.**

**Response:**
```json
{
  "codes": ["code1", "code2", "..."]
}
```

---

### Recovery Endpoints

#### `POST /api/v1/recovery/request`

Request account recovery email.

**Request:**
```json
{
  "handle": "username"
}
```

**Response:** Always returns success (prevents enumeration)
```json
{
  "message": "If an account exists with a verified email, a recovery link has been sent."
}
```

#### `POST /api/v1/recovery/verify`

Verify recovery token validity.

**Request:**
```json
{
  "token": "recovery-token"
}
```

**Response:**
```json
{
  "valid": true,
  "handle": "username",
  "has_passkey": false
}
```

#### `POST /api/v1/recovery/reset`

Reset account with recovery token.

**Request:**
```json
{
  "token": "recovery-token",
  "new_password": "newpassword123"
}
```

**Response:** Same as login response

---

## Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Request validation failed |
| `HANDLE_TAKEN` | Handle already in use |
| `INVALID_CREDENTIALS` | Wrong username/password |
| `2FA_REQUIRED` | 2FA code required for login |
| `INVALID_2FA` | Invalid 2FA code |
| `UNAUTHORIZED` | Missing or invalid auth token |
| `NOT_FOUND` | Resource not found |
| `DB_ERROR` | Database error |
| `HASH_ERROR` | Password hashing error |
| `TOKEN_ERROR` | Token generation error |
| `INVALID_TOKEN` | Invalid or expired token |
| `DEVICE_ID_REQUIRED` | X-Device-ID header required |

## Database Schema

The server auto-creates these tables on startup:

- `accounts` - User accounts
- `devices` - Logged-in devices
- `recovery_tokens` - Password recovery tokens
- `email_verification_tokens` - Email verification tokens

## Deployment

### Fly.io

```bash
# Create app
fly apps create kinu-auth

# Set secrets
fly secrets set JWT_SECRET="$(openssl rand -base64 32)"
fly secrets set EMAIL_ENCRYPTION_KEY="$(openssl rand -hex 32)"

# Deploy
fly deploy
```

See the main project's deployment guide for full instructions.

## Security Considerations

- **JWT_SECRET** must be cryptographically random (32+ bytes)
- **EMAIL_ENCRYPTION_KEY** must be 32 bytes hex (64 chars)
- Emails are encrypted at rest with AES-256-GCM
- Passwords are hashed with Argon2id
- TOTP secrets are encrypted at rest
- Recovery tokens are hashed before storage
- Rate limiting should be added for production

## Development

```bash
# Run with hot reload
cargo watch -x run

# Run tests
cargo test

# Check for issues
cargo clippy

# Format code
cargo fmt
```
