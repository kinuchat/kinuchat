# MeshLink

**Hybrid Cloud/Mesh Encrypted Messaging**

MeshLink is a privacy-first encrypted messaging application that seamlessly transitions between cloud-based messaging and Bluetooth Low Energy (BLE) mesh networking. When internet connectivity is strong, messages travel through encrypted cloud infrastructure. When connectivity degrades or fails, the app automatically switches to local mesh communication.

## Project Structure

This is a Flutter monorepo managed with [Melos](https://melos.invertase.dev/).

```
meshlink/
├── apps/
│   └── mobile/                # Flutter mobile app (iOS/Android)
├── packages/
│   ├── meshlink_core/         # Core business logic (crypto, mesh, transport)
│   └── meshlink_ui/           # Shared UI components and design system
├── server/
│   ├── relay/                 # Rust relay server (future)
│   └── config/                # Server configurations
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
- **Backend**: Rust relay server, PostgreSQL, Redis

## Getting Started

### Prerequisites

- Flutter SDK 3.x or later
- Dart SDK 3.x or later
- Melos CLI tool

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

### Running the Mobile App

```bash
cd apps/mobile
flutter run
```

## Development Phases

This project follows a phased development approach:

- **Phase 0: Foundation** ✅ **Complete** - Project setup, core architecture, identity system
- **Phase 1: Cloud Messaging** ✅ **Complete** - Matrix integration, basic 1:1 messaging
- **Phase 2: Mesh Networking** ✅ **Complete** - BLE mesh implementation, transport switching
- **Phase 3: Rally Mode** (Next) - Location-based public channels
- **Phase 4: Bridge Relay** - AirTag-style message relay
- **Phase 5: Polish and Launch** - Media support, groups, onboarding

See `.claude/context/SPEC.md` for the complete specification.

### Phase 2: Mesh Networking (Completed)

**What's Working:**
- ✅ BLE peer discovery and pairing via Noise Protocol XX handshake
- ✅ Direct peer-to-peer encrypted messaging (internet-free)
- ✅ Multi-hop routing with flooding algorithm (up to 7 hops)
- ✅ Automatic transport selection (cloud vs mesh based on peer availability)
- ✅ Store-and-forward message queuing for offline peers
- ✅ Message deduplication to prevent routing loops
- ✅ Background service for Android (foreground notification)
- ✅ iOS background mode for BLE
- ✅ Real-time UI indicators showing transport mode and peer count
- ✅ 89/89 unit tests passing

**Testing:**
- Requires **physical devices** (BLE doesn't work in simulator/emulator)
- See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for comprehensive test procedures
- See [BATTERY_OPTIMIZATION.md](./BATTERY_OPTIMIZATION.md) for tuning performance

**Known Limitations:**
- iOS background BLE has reduced scan frequency (controlled by OS)
- Battery usage: ~8-10% per hour with active mesh (can be optimized)
- Max 7 hops for routing (as per spec)

## Architecture

MeshLink follows Clean Architecture principles:

- **Presentation Layer**: UI screens and widgets
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Repositories and data sources
- **Core Layer**: Utilities, constants, and shared code

### Key Components

- **Identity Service**: Ed25519/X25519 key generation and management
- **Transport Manager**: Automatic selection between cloud, mesh, and bridge transports
- **Encryption**: Noise Protocol for mesh, Megolm for cloud groups
- **Database**: Drift for local message and contact storage

## Security & Privacy

- End-to-end encryption for all messages
- No phone number required
- No data collection or tracking
- Self-hostable infrastructure
- Open protocol

## License

TBD

## Contributing

TBD

## Documentation

- Full specification: `.claude/context/SPEC.md`
- Architecture details: Coming soon
- Protocol specifications: Coming soon
