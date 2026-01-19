cat > CLAUDE.md << 'EOF'
# MeshLink Project

## Context
Read `.claude/context/SPEC.md` for the complete project specification including architecture, tech stack, protocols, and implementation phases.

## Tech Stack
- Flutter 3.x (Dart) for mobile app
- Riverpod for state management
- Drift + SQLCipher for local database
- Matrix (Dendrite) for cloud messaging
- Rust for relay server
- Astro for marketing website

## Architecture
Clean Architecture with layers: presentation, domain, data, core

## Conventions
- Dart: strict null safety, effective_dart style
- Files: snake_case
- Classes: PascalCase
- State: Riverpod providers

## Current Phase
Phase 0: Foundation - Project setup and core architecture
EOF
```

**3. Launch Claude Code CLI and use this initial prompt:**
```
I'm starting the MeshLink project from scratch. Please read the full specification 
in .claude/context/SPEC.md first.

Then, let's begin Phase 0 - Foundation:

1. Initialize the Flutter monorepo structure using Melos with:
   - apps/mobile (main Flutter app)
   - packages/meshlink_core (shared crypto, mesh, transport code)
   - packages/meshlink_ui (shared UI components)

2. Set up the core architecture in meshlink_core:
   - Identity service with Ed25519/X25519 key generation
   - Secure storage abstraction
   - Transport manager interface (cloud, mesh, bridge)
   - Basic Drift database schema for messages and contacts

3. Configure strict linting and analysis options

Start with step 1 - create the monorepo structure with proper pubspec.yaml 
files and melos.yaml configuration.
```

## Alternative: Phased Prompts

If you prefer smaller chunks, use these sequential prompts:

**Prompt 1 - Monorepo setup:**
```
Read .claude/context/SPEC.md for project requirements.

Create a Flutter monorepo using Melos with this structure:
- apps/mobile (Flutter app, iOS/Android)
- packages/meshlink_core (shared Dart code)
- packages/meshlink_ui (shared widgets)

Include proper pubspec.yaml files with the dependencies from the spec 
(riverpod, drift, flutter_blue_plus, pointycastle, etc.)
```

**Prompt 2 - Identity system:**
```
Now implement the identity system in packages/meshlink_core/lib/crypto/:

- Key generation (Ed25519 signing, X25519 key exchange)
- Secure storage service using flutter_secure_storage
- Identity model with mesh peer ID derivation
- Export/import functionality for backup

Follow the key hierarchy defined in Section 6.1 of the spec.
```

**Prompt 3 - Transport abstraction:**
```
Create the transport manager abstraction in packages/meshlink_core/lib/transport/:

- TransportManager interface with selectTransport() logic
- CloudTransport placeholder (Matrix integration later)
- MeshTransport placeholder (BLE integration later)  
- BridgeTransport placeholder
- Message queue with persistence
- Deduplication engine using message IDs

Follow the transport selection matrix in Section 3 of the spec.
```

## Pro Tips

1. **Keep the spec updated** - As you make decisions or changes, update SPEC.md so Claude always has current context

2. **Reference specific sections** - When asking about something specific, point to it:
```
   Implement the Noise XX handshake as described in Section 6.2 of the spec
```

3. **Use checkpoints** - After each major piece:
```
   Let's verify what we have so far compiles and the tests pass before moving on
