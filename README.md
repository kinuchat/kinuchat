# Kinu

**Hybrid Cloud/Mesh Encrypted Messaging**

Kinu is a privacy-first encrypted messaging application that seamlessly transitions between cloud-based messaging and Bluetooth Low Energy (BLE) mesh networking. When internet connectivity is strong, messages travel through encrypted cloud infrastructure. When connectivity degrades or fails, the app automatically switches to local mesh communication.

## Project Structure

This is a Flutter monorepo managed with [Melos](https://melos.invertase.dev/).

```
kinu/
├── apps/
│   └── mobile/                # Flutter mobile app (iOS/Android)
├── packages/
│   ├── meshlink_core/         # Core business logic (crypto, mesh, transport)
│   └── meshlink_ui/           # Shared UI components and design system
├── server/
│   ├── auth/                  # Rust authentication server
│   └── matrix/                # Dendrite Matrix homeserver
├── web/                       # Landing page (Astro)
├── docs/                      # Documentation
├── melos.yaml                 # Monorepo configuration
└── analysis_options.yaml      # Strict linting rules
```

## Tech Stack

- **Mobile**: Flutter 3.x, Dart 3.x
- **State Management**: Riverpod 2.x
- **Database**: Drift (SQLite) + SQLCipher
- **Crypto**: Ed25519, X25519, Noise Protocol
- **Cloud Messaging**: Matrix (Dendrite homeserver)
- **Mesh Networking**: BLE via flutter_blue_plus
- **Auth Server**: Rust/Axum, SQLite, JWT
- **Backend**: Fly.io deployment

## Features

### Authentication Server
- **Passkey/WebAuthn** support for passwordless login
- **Password authentication** with Argon2id hashing
- **Two-Factor Authentication (TOTP)** with backup codes
- **Device management** - track and revoke logged-in devices
- **Email verification** via SMTP
- **Account recovery** via email
- **Data export** (GDPR compliance)

### Mobile App
- **End-to-end encrypted messaging** via Matrix
- **BLE mesh networking** for offline communication
- **Rally Mode** - location-based ephemeral channels
- **Quiet hours** - scheduled notification muting
- **Multi-device support** with device management
- **Biometric authentication** support

## Getting Started

### Prerequisites

- Flutter SDK 3.x or later
- Dart SDK 3.x or later
- Melos CLI tool
- Rust toolchain (for auth server)

### Installation

1. Install Melos globally:
```bash
dart pub global activate melos
```

2. Bootstrap the monorepo:
```bash
melos bootstrap
```

This will:
- Install dependencies for all packages
- Link local packages together
- Generate necessary files

### Running the Auth Server

```bash
cd server/auth

# Set up environment variables (see server/auth/README.md)
cp .env.example .env

# Run the server
cargo run
```

### Running the Mobile App

```bash
cd apps/mobile
flutter run
```

### Common Commands

```bash
# Run tests across all packages
melos run test

# Analyze all packages
melos run analyze

# Format all Dart code
melos run format

# Run code generation (freezed, json_serializable, drift, riverpod)
melos run build:runner

# Clean all packages
melos run clean
```

## Development Phases

- **Phase 0: Foundation** ✅ - Project setup, core architecture, identity system
- **Phase 1: Cloud Messaging** ✅ - Matrix integration, basic 1:1 messaging
- **Phase 2: Mesh Networking** ✅ - BLE mesh implementation, transport switching
- **Phase 3: Rally Mode** ✅ - Location-based public channels
- **Phase 4: Account Management** ✅ - 2FA, device management, email verification, data export
- **Phase 5: Bridge Relay** (Next) - AirTag-style message relay
- **Phase 6: Polish and Launch** - Media support, groups, onboarding

See `.claude/context/SPEC.md` for the complete specification.

## Architecture

Kinu follows Clean Architecture principles:

- **Presentation Layer**: UI screens and widgets
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Repositories and data sources
- **Core Layer**: Utilities, constants, and shared code

### Key Components

- **Identity Service**: Ed25519/X25519 key generation and management
- **Transport Manager**: Automatic selection between cloud, mesh, and bridge transports
- **Encryption**: Noise Protocol for mesh, Megolm for cloud groups
- **Database**: Drift for local message and contact storage
- **Auth Service**: JWT-based authentication with passkey/password support

## Deployment

### Auth Server (Fly.io)
The auth server is deployed to Fly.io at `auth.kinuchat.com`.

```bash
cd server/auth
fly deploy
```

### Matrix Server (Fly.io)
Dendrite Matrix server at `matrix.kinuchat.com`.

See `DEPLOYMENT_GUIDE.md` for detailed deployment instructions.

## Security & Privacy

- End-to-end encryption for all messages
- No phone number required
- No data collection or tracking
- Self-hostable infrastructure
- Open protocol
- GDPR-compliant data export

## API Documentation

See individual component documentation:
- [Auth Server API](server/auth/README.md)
- [Mobile App](apps/mobile/README.md)

## Testing

- See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for comprehensive test procedures
- See [BATTERY_OPTIMIZATION.md](./BATTERY_OPTIMIZATION.md) for tuning performance

## License

TBD

## Contributing

TBD
