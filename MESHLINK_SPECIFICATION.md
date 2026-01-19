# MeshLink: Hybrid Cloud/Mesh Encrypted Messaging

**Version:** 1.0.0-draft  
**Last Updated:** January 2026  
**Status:** Design Specification

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Vision and Philosophy](#2-vision-and-philosophy)
3. [Architecture Overview](#3-architecture-overview)
4. [Tech Stack Decision](#4-tech-stack-decision)
5. [Core Features](#5-core-features)
6. [Protocol Specifications](#6-protocol-specifications)
7. [User Interface Design](#7-user-interface-design)
8. [Onboarding and Feature Walkthrough](#8-onboarding-and-feature-walkthrough)
9. [Server Infrastructure](#9-server-infrastructure)
10. [Cost Analysis](#10-cost-analysis)
11. [Security and Privacy](#11-security-and-privacy)
12. [Web Marketing Site](#12-web-marketing-site)
13. [Donation System](#13-donation-system)
14. [Implementation Phases](#14-implementation-phases)
15. [Claude Code CLI Integration](#15-claude-code-cli-integration)
16. [Appendices](#16-appendices)

---

## 1. Executive Summary

### What is MeshLink?

MeshLink is a privacy-first encrypted messaging application that seamlessly transitions between cloud-based messaging and Bluetooth Low Energy (BLE) mesh networking. When internet connectivity is strong, messages travel through encrypted cloud infrastructure. When connectivity degrades or fails, the app automatically switches to local mesh communication, allowing users to message nearby contacts without any internet connection.

### Key Differentiators

| Feature | Signal/WhatsApp | BitChat | MeshLink |
|---------|-----------------|---------|----------|
| Cloud E2E Encryption | Yes | No | Yes |
| Offline Mesh | No | Yes | Yes |
| Automatic Failover | No | No | Yes |
| Bridge Relay (AirTag-style) | No | No | Yes |
| Emergency Broadcast | No | Partial | Yes |
| Cross-platform | Yes | Yes | Yes |

### Target Use Cases

1. **Daily messaging** with Signal-level privacy
2. **Concerts, festivals, rallies** where cell towers are congested
3. **Disaster response** when infrastructure is down
4. **Remote areas** with limited connectivity
5. **Privacy-conscious users** who want infrastructure independence

---

## 2. Vision and Philosophy

### Core Principles

```
┌─────────────────────────────────────────────────────────────────┐
│  1. PRIVACY BY DEFAULT                                          │
│     No phone numbers required. No data collection.              │
│     End-to-end encryption for everything.                       │
├─────────────────────────────────────────────────────────────────┤
│  2. RESILIENT COMMUNICATION                                     │
│     Messages find a way. Cloud, mesh, or bridge relay.          │
│     No single point of failure.                                 │
├─────────────────────────────────────────────────────────────────┤
│  3. SEAMLESS EXPERIENCE                                         │
│     Users shouldn't think about transport layers.               │
│     It just works.                                              │
├─────────────────────────────────────────────────────────────────┤
│  4. COMMUNITY POWERED                                           │
│     Open protocol. Donation supported. No ads. No tracking.     │
│     Users who can help, help others.                            │
└─────────────────────────────────────────────────────────────────┘
```

### Design Language

MeshLink's visual identity communicates:
- **Trust**: Clean, uncluttered interfaces
- **Resilience**: Subtle indicators of connection state
- **Community**: Warm, human touches in an encrypted world

---

## 3. Architecture Overview

### High-Level System Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              MESHLINK SYSTEM                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         CLIENT APPLICATION                           │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │   │
│  │  │   Chat UI   │  │  Rally Mode │  │  Settings   │  │  Contacts  │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────┬──────┘  │   │
│  │         │                │                │               │          │   │
│  │  ┌──────┴────────────────┴────────────────┴───────────────┴──────┐  │   │
│  │  │                    MESSAGE ORCHESTRATOR                        │  │   │
│  │  │  - Transport selection logic                                   │  │   │
│  │  │  - Message queue management                                    │  │   │
│  │  │  - Deduplication engine                                        │  │   │
│  │  │  - Encryption coordinator                                      │  │   │
│  │  └──────┬────────────────┬────────────────┬───────────────────────┘  │   │
│  │         │                │                │                          │   │
│  │  ┌──────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐                  │   │
│  │  │   CLOUD     │  │  BLE MESH   │  │   BRIDGE    │                  │   │
│  │  │  TRANSPORT  │  │  TRANSPORT  │  │   CLIENT    │                  │   │
│  │  │  (Matrix)   │  │  (BitChat)  │  │   (Relay)   │                  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │   │
│  └─────────┼────────────────┼────────────────┼──────────────────────────┘   │
│            │                │                │                              │
├────────────┼────────────────┼────────────────┼──────────────────────────────┤
│            │                │                │                              │
│  ┌─────────▼─────────┐      │      ┌─────────▼─────────┐                   │
│  │   MATRIX SERVER   │      │      │   RELAY SERVER    │                   │
│  │   (Homeserver)    │      │      │   (Bridge Hub)    │                   │
│  │                   │      │      │                   │                   │
│  │  - E2E encrypted  │      │      │  - Encrypted blob │                   │
│  │  - Message sync   │◄─────┼─────►│    storage        │                   │
│  │  - Push notifs    │      │      │  - TTL-based      │                   │
│  │  - Key backup     │      │      │  - No inspection  │                   │
│  └───────────────────┘      │      └───────────────────┘                   │
│                             │                                               │
│                    ┌────────▼────────┐                                     │
│                    │   BLE MESH      │                                     │
│                    │   NETWORK       │                                     │
│                    │                 │                                     │
│                    │  [A]--[B]--[C]  │                                     │
│                    │   |       |     │                                     │
│                    │  [D]--[E]--[F]  │                                     │
│                    └─────────────────┘                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Transport Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRANSPORT MANAGER                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  selectTransport(message, recipient):                            │
│                                                                  │
│    1. Check recipient's last-known transport                     │
│    2. Evaluate current network conditions                        │
│    3. Check BLE mesh peer availability                           │
│    4. Apply user preferences                                     │
│    5. Return optimal transport                                   │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  DECISION MATRIX                                           │  │
│  ├───────────────────┬───────────────┬───────────────────────┤  │
│  │  Condition        │ Transport     │ Fallback              │  │
│  ├───────────────────┼───────────────┼───────────────────────┤  │
│  │  Strong internet  │ Cloud         │ None                  │  │
│  │  Weak internet    │ Cloud         │ Mesh (if peer nearby) │  │
│  │  No internet      │ Mesh          │ Bridge relay          │  │
│  │  Peer in BLE      │ Mesh (faster) │ Cloud                 │  │
│  │  Rally mode       │ Mesh broadcast│ None                  │  │
│  │  Bridge enabled   │ Cloud         │ Relay server          │  │
│  └───────────────────┴───────────────┴───────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow: Message Send

```
User taps "Send"
       │
       ▼
┌──────────────────┐
│ Generate msg ID  │  (SHA256 of content + timestamp + sender)
│ (deterministic)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Encrypt message  │  (Noise Protocol: X25519 + AES-256-GCM)
│ with recipient   │
│ public key       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌─────────────────────────────────────┐
│ Select transport │────►│ Cloud: Matrix E2E room              │
│                  │     │ Mesh: BLE broadcast/direct          │
│                  │     │ Bridge: Relay server upload         │
└────────┬─────────┘     └─────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│ Queue message    │  (Persist to local DB for retry/sync)
│ with status      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Await delivery   │  (ACK from transport or timeout)
│ confirmation     │
└──────────────────┘
```

---

## 4. Tech Stack Decision

### Mobile Application: Flutter (Dart)

**Why Flutter over React Native/Expo:**

| Criteria | Flutter | React Native | Expo |
|----------|---------|--------------|------|
| BLE Support | Excellent (flutter_blue_plus) | Good (react-native-ble-plx) | Limited |
| Crypto Libraries | Strong (pointycastle, cryptography) | Bridge-heavy | Limited |
| Background Execution | Native-like control | Requires native modules | Very limited |
| Performance | Near-native, AOT compiled | JIT, bridge overhead | Same as RN |
| Single Codebase | iOS, Android, macOS, Linux, Windows | iOS, Android | iOS, Android |
| Learning Curve | Moderate (Dart is easy) | Familiar (JS/TS) | Easiest |

**Decision: Flutter**

Flutter provides the low-level control needed for BLE mesh networking, background services, and cryptographic operations while maintaining cross-platform efficiency. Dart's strong typing and AOT compilation ensure performance-critical mesh routing code runs efficiently.

### Backend: Self-Hosted Matrix + Custom Relay

**Why Matrix over Firebase/Supabase/Convex:**

| Criteria | Matrix | Firebase | Supabase | Convex |
|----------|--------|----------|----------|--------|
| E2E Encryption | Native (Olm/Megolm) | None built-in | None built-in | None |
| Self-hostable | Yes (Synapse/Dendrite) | No | Yes | No |
| Federation | Yes | No | No | No |
| Vendor Lock-in | None | High | Medium | High |
| Privacy | Maximum | Google-dependent | Good | Unknown |
| Offline Sync | Excellent | Good | Good | Limited |

**Decision: Matrix (Dendrite homeserver)**

Matrix's built-in E2E encryption, federation capability, and self-hostability align perfectly with MeshLink's privacy-first philosophy. Dendrite (the Go implementation) is lighter weight than Synapse for our scale.

### Relay Server: Custom Rust Service

A minimal Rust service handles bridge relay functionality:
- Receives encrypted blobs from bridge nodes
- Stores with TTL-based expiration
- Allows recipients to poll with key hash
- No message inspection capability

**Why Rust:**
- Memory safety without garbage collection
- Excellent async performance (tokio)
- Small binary size for containerization
- Strong cryptographic library ecosystem

### Database Strategy

| Component | Database | Rationale |
|-----------|----------|-----------|
| Mobile Local | SQLite (drift) | Proven, embedded, encrypted (SQLCipher) |
| Matrix Homeserver | PostgreSQL | Dendrite requirement |
| Relay Server | Redis | TTL-native, high throughput |
| Analytics (optional) | None | Privacy-first: no tracking |

### Complete Tech Stack Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                         TECH STACK                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  MOBILE APPLICATION                                              │
│  ├── Framework: Flutter 3.x (Dart 3.x)                          │
│  ├── State Management: Riverpod 2.x                             │
│  ├── Local Database: Drift (SQLite) + SQLCipher                 │
│  ├── BLE: flutter_blue_plus                                     │
│  ├── Crypto: pointycastle, x25519, noise_protocol               │
│  ├── Matrix SDK: matrix_dart_sdk                                │
│  ├── Networking: dio, web_socket_channel                        │
│  ├── Background: workmanager, flutter_background_service        │
│  └── UI: Custom design system (no Material/Cupertino)           │
│                                                                  │
│  BACKEND SERVICES                                                │
│  ├── Matrix Homeserver: Dendrite (Go)                           │
│  ├── Relay Server: Custom Rust (axum + tokio)                   │
│  ├── Push Notifications: ntfy.sh (self-hosted) or Firebase FCM  │
│  ├── Database: PostgreSQL 15+, Redis 7+                         │
│  └── Container Orchestration: Docker Compose (small scale)      │
│      or Kubernetes (large scale)                                 │
│                                                                  │
│  WEB MARKETING SITE                                              │
│  ├── Framework: Astro 4.x (static generation)                   │
│  ├── Styling: Tailwind CSS 3.x                                  │
│  ├── Animations: Motion One                                      │
│  ├── Hosting: Cloudflare Pages (free tier)                      │
│  └── Analytics: Plausible (privacy-respecting) or none          │
│                                                                  │
│  DEVELOPMENT TOOLING                                             │
│  ├── Monorepo: Melos (Dart/Flutter)                             │
│  ├── CI/CD: GitHub Actions                                       │
│  ├── Testing: Flutter test, integration_test, mockito           │
│  ├── Linting: dart analyze, custom_lint                         │
│  └── Documentation: Docusaurus                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Core Features

### 5.1 Private Messaging (1:1)

Standard encrypted messaging with cloud/mesh hybrid delivery.

**Capabilities:**
- Text messages (unlimited length, chunked if needed)
- Images (compressed, thumbnails first, full on tap)
- Voice notes (Opus encoded, up to 5 minutes)
- Files (up to 25MB via cloud, 1MB via mesh)
- Read receipts (optional, user preference)
- Typing indicators (optional, cloud only)
- Message reactions (emoji)
- Reply threading
- Message deletion (local + request remote deletion)
- Disappearing messages (1 hour to 1 week)

**Delivery States:**
```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Pending │───►│  Sent   │───►│Delivered│───►│  Read   │
│   ○     │    │   ✓     │    │   ✓✓    │    │  ✓✓    │
│  gray   │    │  gray   │    │  gray   │    │  blue   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
                    │
                    ▼
              ┌─────────┐
              │ Failed  │  (tap to retry)
              │   !     │
              │  red    │
              └─────────┘
```

### 5.2 Group Chats

Encrypted group conversations with admin controls.

**Capabilities:**
- Up to 256 members (cloud), 32 members (mesh-only groups)
- Admin roles: Owner, Admin, Member
- Invite links with optional expiration
- Message pinning
- Polls
- Group name, description, avatar
- Mentions (@username, @everyone)

**Encryption Model:**
- Cloud: Megolm group sessions (Matrix standard)
- Mesh: Shared symmetric key derived from group seed, rotated on membership change

### 5.3 Mesh Mode

Automatic or manual activation of BLE mesh networking.

**Automatic Triggers:**
- Network quality below threshold (configurable)
- >5 mesh peers discovered
- Explicit user toggle

**Visual Indicators:**
```
┌─────────────────────────────────────────┐
│  Status Bar (when mesh active)          │
│  ┌─────────────────────────────────┐   │
│  │ 📡 Mesh Active · 12 peers nearby │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Mesh-Specific Features:**
- Peer count display
- Signal strength visualization
- Hop count for messages
- Store-and-forward for offline peers (up to 24 hours)

### 5.4 Rally Mode (Emergency Broadcast)

Location-bounded public channel for nearby users.

**Activation:**
1. Manual: Settings > Rally Mode > Activate
2. Suggested: "47 people nearby have weak signal. Activate Rally Mode?"

**Channel Discovery:**
```dart
class RallyChannel {
  // Deterministic channel ID from location + time
  static String generateChannelId(double lat, double lng) {
    final geohash = Geohash.encode(lat, lng, precision: 6); // ~1.2km
    final timeBucket = DateTime.now().millisecondsSinceEpoch ~/ (4 * 3600000);
    return sha256('$geohash:$timeBucket').substring(0, 16);
  }
}
```

**Identity Options:**
- Anonymous: `anon-[adjective]-[number]` (new each session)
- Pseudonymous: User-chosen handle (persistent)
- Verified: Linked cloud account (shows badge)

**Moderation:**
- Local reputation scoring
- Block/mute (affects your view only)
- Report (categories: spam, harassment, threats, CSAM)
- Auto-hide low-reputation senders
- On-device content filtering (optional)

**Safety Features:**
- Age verification (16+) required
- CSAM hash detection on media
- Credible threat reports queued for upload

### 5.5 Bridge Mode (AirTag-Style Relay)

Users with internet connectivity can relay encrypted messages for those without.

**Consent Flow:**
```
First trigger (detected as potential bridge):

┌─────────────────────────────────────────────────────────┐
│  🌉 You Can Help                                        │
│                                                         │
│  47 nearby users don't have internet access.            │
│  You can relay their encrypted messages.                │
│                                                         │
│  What you should know:                                  │
│  • Messages are end-to-end encrypted                    │
│  • You cannot read the content                          │
│  • Uses approximately 2-5 MB/hour                       │
│  • Pauses below 30% battery                             │
│                                                         │
│  ┌─────────────┐     ┌─────────────┐                   │
│  │   Enable    │     │   Not Now   │                   │
│  └─────────────┘     └─────────────┘                   │
│                                                         │
│  □ Remember my choice                                   │
└─────────────────────────────────────────────────────────┘
```

**Bridge Indicator:**
```
Status bar when active:
┌──────────────────────────────────────────────┐
│ 🌉 Bridging · 23 msgs relayed · 1.2 MB used  │
└──────────────────────────────────────────────┘
```

**Configuration Options:**
- Enable/disable
- Bandwidth limit (MB/day)
- Battery threshold
- Relay for contacts only vs. all

### 5.6 Contact Management

**Adding Contacts:**
1. QR code scan (in-person)
2. Username search (cloud)
3. Invite link
4. Nearby discovery (BLE, opt-in)

**Contact Information:**
- Display name
- Optional avatar
- Public key fingerprint (verifiable)
- Verification status (QR verified, unverified)
- Last seen (optional, user preference)
- Preferred transport hint

**Contact Actions:**
- Message
- Voice call (future)
- Video call (future)
- Block
- Delete
- Verify (QR code comparison)

---

## 6. Protocol Specifications

### 6.1 Identity and Keys

```
┌─────────────────────────────────────────────────────────────────┐
│                      KEY HIERARCHY                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ROOT IDENTITY                                                   │
│  ├── Ed25519 Signing Key (persistent)                           │
│  │   └── Used for: identity verification, message signing       │
│  │                                                               │
│  ├── X25519 Key Exchange Key (persistent)                       │
│  │   └── Derived from Ed25519 seed                              │
│  │   └── Used for: Noise handshakes, session establishment      │
│  │                                                               │
│  └── Derived Identifiers                                         │
│      ├── Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)   │
│      ├── Matrix User ID: @base58(Ed25519_pub[0:10]):server      │
│      └── Relay Key Hash: SHA256(X25519_pub)                     │
│                                                                  │
│  SESSION KEYS (ephemeral)                                        │
│  ├── Noise Session Keys: derived per conversation               │
│  └── Megolm Session Keys: for Matrix group encryption           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Key Generation (first launch):**
```dart
class IdentityService {
  Future<Identity> generateIdentity() async {
    // Generate 32 bytes of secure randomness
    final seed = SecureRandom.generate(32);
    
    // Ed25519 for signing
    final signingKeyPair = Ed25519().newKeyPairFromSeed(seed);
    
    // X25519 for key exchange (derived from same seed for determinism)
    final exchangeKeyPair = X25519().newKeyPairFromSeed(seed);
    
    // Derive identifiers
    final meshPeerId = sha256(signingKeyPair.publicKey).sublist(0, 8);
    
    return Identity(
      signingKeyPair: signingKeyPair,
      exchangeKeyPair: exchangeKeyPair,
      meshPeerId: meshPeerId,
      createdAt: DateTime.now(),
    );
  }
}
```

### 6.2 Noise Protocol Handshake

MeshLink uses Noise Protocol Framework with the `XX` pattern for mutual authentication.

```
┌─────────────────────────────────────────────────────────────────┐
│  NOISE XX HANDSHAKE                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Initiator (Alice)                    Responder (Bob)           │
│       │                                      │                   │
│       │  1. -> e                             │                   │
│       │     (ephemeral public key)           │                   │
│       │─────────────────────────────────────►│                   │
│       │                                      │                   │
│       │  2. <- e, ee, s, es                  │                   │
│       │     (Bob's ephemeral + static)       │                   │
│       │◄─────────────────────────────────────│                   │
│       │                                      │                   │
│       │  3. -> s, se                         │                   │
│       │     (Alice's static, encrypted)      │                   │
│       │─────────────────────────────────────►│                   │
│       │                                      │                   │
│       │  [Session established]               │                   │
│       │  [Both have authenticated]           │                   │
│       │                                      │                   │
└─────────────────────────────────────────────────────────────────┘

Cipher: ChaChaPoly
Hash: SHA256
DH: X25519
```

### 6.3 Message Packet Format (Mesh)

```
┌─────────────────────────────────────────────────────────────────┐
│  MESHLINK PACKET FORMAT (Binary)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Offset  Size   Field           Description                     │
│  ───────────────────────────────────────────────────────────    │
│  0       1      Version         Protocol version (0x01)         │
│  1       1      Type            Message type (see enum)         │
│  2       1      TTL             Hop limit (max 7)               │
│  3       1      Flags           Bitmask (see below)             │
│  4       8      Timestamp       Unix ms (uint64 BE)             │
│  12      16     MessageID       Random + hash (dedup)           │
│  28      8      RecipientID     Truncated pubkey (or 0xFF..FF)  │
│  36      2      PayloadLen      Payload length (uint16 BE)      │
│  38      N      Payload         Encrypted content               │
│  38+N    64     Signature       Ed25519 (if flag set)           │
│  ...     P      Padding         PKCS#7 to block boundary        │
│                                                                  │
│  FLAGS BITMASK:                                                  │
│  ├── 0x01: hasRecipient (unicast vs broadcast)                  │
│  ├── 0x02: hasSignature                                         │
│  ├── 0x04: isCompressed (LZ4)                                   │
│  ├── 0x08: isFragmented                                         │
│  └── 0x10: requiresAck                                          │
│                                                                  │
│  MESSAGE TYPES:                                                  │
│  ├── 0x01: TEXT                                                 │
│  ├── 0x02: MEDIA_HEADER                                         │
│  ├── 0x03: MEDIA_CHUNK                                          │
│  ├── 0x04: ACK                                                  │
│  ├── 0x05: HANDSHAKE_INIT                                       │
│  ├── 0x06: HANDSHAKE_RESP                                       │
│  ├── 0x07: PEER_ANNOUNCE                                        │
│  ├── 0x08: RELAY_REQUEST                                        │
│  └── 0x09: RALLY_BROADCAST                                      │
│                                                                  │
│  PADDING (to resist traffic analysis):                          │
│  ├── < 192 bytes  -> pad to 256                                 │
│  ├── < 448 bytes  -> pad to 512                                 │
│  ├── < 960 bytes  -> pad to 1024                                │
│  └── < 1984 bytes -> pad to 2048                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Bridge Relay Protocol

```
┌─────────────────────────────────────────────────────────────────┐
│  RELAY ENVELOPE FORMAT                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  {                                                               │
│    "recipient_key_hash": "base64(SHA256(recipient_X25519_pub))", │
│    "encrypted_payload": "base64(noise_encrypted_packet)",        │
│    "ttl_hours": 4,                                               │
│    "priority": "normal" | "urgent" | "emergency",                │
│    "nonce": "base64(16 random bytes)",                          │
│    "created_at": 1704067200000                                   │
│  }                                                               │
│                                                                  │
│  PRIVACY GUARANTEES:                                             │
│  ├── Bridge node cannot read payload (E2E encrypted)            │
│  ├── Bridge node cannot identify sender (not in envelope)       │
│  ├── Relay server only sees key hash (not full key)             │
│  └── TTL prevents indefinite storage                            │
│                                                                  │
│  RECIPIENT POLLING:                                              │
│  GET /relay/poll?key_hash={hash}                                │
│  Response: [array of encrypted_payloads]                        │
│  (Payloads deleted after retrieval)                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.5 Rally Channel Protocol

```
┌─────────────────────────────────────────────────────────────────┐
│  RALLY CHANNEL DISCOVERY                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Channel ID Derivation:                                          │
│  ─────────────────────                                           │
│  geohash = encode(lat, lng, precision=6)  // ~1.2km cell        │
│  time_bucket = floor(unix_time / (4 * 3600))  // 4-hour windows │
│  channel_id = SHA256(geohash || ":" || time_bucket)[0:16]       │
│                                                                  │
│  Channel Encryption:                                             │
│  ──────────────────                                              │
│  channel_key = HKDF(                                             │
│    ikm = channel_id,                                             │
│    salt = "meshlink-rally-v1",                                   │
│    info = geohash || time_bucket,                                │
│    length = 32                                                   │
│  )                                                               │
│                                                                  │
│  All participants derive same key from same location/time.      │
│  Messages encrypted with channel_key (AES-256-GCM).             │
│  Anyone in area can decrypt (public channel by design).         │
│                                                                  │
│  EPHEMERAL IDENTITY:                                             │
│  ──────────────────                                              │
│  session_keypair = X25519.generate()  // Fresh each join        │
│  anonymous_name = wordlist[hash(session_pub)[0:2]] + "-" +      │
│                   wordlist[hash(session_pub)[2:4]] + "-" +      │
│                   (hash(session_pub)[4] % 100)                  │
│  Example: "brave-river-42"                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. User Interface Design

### 7.1 Design System

**Design Philosophy:** Clean, trustworthy, and human. Inspired by Signal's simplicity but with warmer touches and better status communication.

**Color Palette:**

```
┌─────────────────────────────────────────────────────────────────┐
│  COLOR SYSTEM                                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PRIMARY PALETTE (Light Mode)                                    │
│  ├── Background:      #FAFAFA (warm white)                      │
│  ├── Surface:         #FFFFFF                                   │
│  ├── Primary:         #1B7F6E (teal, trust)                     │
│  ├── Primary Variant: #145F52                                   │
│  ├── Secondary:       #6B5B95 (muted purple, calm)              │
│  ├── Text Primary:    #1A1A1A                                   │
│  ├── Text Secondary:  #666666                                   │
│  └── Divider:         #E5E5E5                                   │
│                                                                  │
│  PRIMARY PALETTE (Dark Mode)                                     │
│  ├── Background:      #121212                                   │
│  ├── Surface:         #1E1E1E                                   │
│  ├── Primary:         #4ECDC4 (bright teal)                     │
│  ├── Primary Variant: #3AA89E                                   │
│  ├── Secondary:       #9B8AC4                                   │
│  ├── Text Primary:    #F5F5F5                                   │
│  ├── Text Secondary:  #AAAAAA                                   │
│  └── Divider:         #333333                                   │
│                                                                  │
│  SEMANTIC COLORS                                                 │
│  ├── Success:         #4CAF50                                   │
│  ├── Warning:         #FF9800                                   │
│  ├── Error:           #E53935                                   │
│  ├── Mesh Active:     #00BCD4 (cyan glow)                       │
│  ├── Bridge Active:   #FFB300 (amber)                           │
│  └── Rally Mode:      #7C4DFF (vibrant purple)                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Typography:**

```
┌─────────────────────────────────────────────────────────────────┐
│  TYPOGRAPHY SCALE                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Font Family: "DM Sans" (body), "DM Mono" (code/IDs)            │
│  Fallback: system-ui, -apple-system, sans-serif                 │
│                                                                  │
│  Scale:                                                          │
│  ├── Display:    32px / 40px line / -0.5 tracking / Bold        │
│  ├── Headline:   24px / 32px line / 0 tracking / SemiBold       │
│  ├── Title:      20px / 28px line / 0 tracking / Medium         │
│  ├── Body:       16px / 24px line / 0 tracking / Regular        │
│  ├── Body Small: 14px / 20px line / 0 tracking / Regular        │
│  ├── Caption:    12px / 16px line / 0.2 tracking / Regular      │
│  └── Mono:       14px / 20px line / 0 tracking / DM Mono        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Screen Layouts

**Chat List (Home):**

```
┌─────────────────────────────────────────┐
│ ≡  MeshLink                    🔍  ⋮   │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 📡 Mesh Active · 8 peers nearby     │ │  <- Status banner (when active)
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│                                         │
│  ┌───┐  Alice Chen              2:34 PM │
│  │ A │  Sure, see you there! ✓✓        │  <- Blue check = read
│  └───┘                                  │
│  ─────────────────────────────────────  │
│  ┌───┐  Work Group              1:15 PM │
│  │👥│  Bob: The meeting is moved...    │
│  └───┘                           (3)    │  <- Unread badge
│  ─────────────────────────────────────  │
│  ┌───┐  Mom                    Yesterday│
│  │ M │  Call me when you can          │
│  └───┘                                  │
│                                         │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│     💬        📍        ⚙️             │
│    Chats    Rally    Settings          │
└─────────────────────────────────────────┘
```

**Chat View:**

```
┌─────────────────────────────────────────┐
│  ←  Alice Chen                 📞  ⋮   │
│      Online · via Cloud ☁️              │  <- Transport indicator
├─────────────────────────────────────────┤
│                                         │
│              ┌─────────────────────┐    │
│              │  Hey! Are you coming │    │
│              │  to the concert?     │    │
│              └─────────────────────┘    │
│                              2:30 PM    │
│                                         │
│  ┌─────────────────────┐                │
│  │  Yes! Can't wait 🎵 │                │
│  └─────────────────────┘                │
│  2:32 PM ✓✓                             │
│                                         │
│              ┌─────────────────────┐    │
│              │  Great! Meet at      │    │
│              │  the north entrance  │    │
│              └─────────────────────┘    │
│                              2:34 PM    │
│                                         │
│  ┌─────────────────────┐                │
│  │  Sure, see you there!│                │
│  └─────────────────────┘                │
│  2:34 PM ✓✓                             │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ Message...              📷 🎤 ➤ │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Rally Mode:**

```
┌─────────────────────────────────────────┐
│  ←  Rally Mode                    ⚠️   │
│      📍 ~2,400 people · #rally-x7k2    │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ ⚠️ Public channel. Be mindful of   │ │
│ │    what you share.            [×]   │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│                                         │
│  brave-fox-23                   2:41 PM │
│  Anyone know where the water station   │
│  is?                                    │
│                                         │
│  calm-river-87                  2:42 PM │
│  Northwest corner near the big tree    │
│                                         │
│  quick-bear-12                  2:43 PM │
│  ⚠️ Medic needed section B!            │
│                                         │
│  ✓ @RedCross (Verified)         2:44 PM│
│  First aid tent is at coordinates...   │
│  We're sending someone to section B.   │
│                                         │
│  [You] bold-wave-55             2:45 PM │
│  Thanks for the quick response! 🙏     │
│                                         │
├─────────────────────────────────────────┤
│  Your identity: bold-wave-55           │
│  ┌─────────────────────────────────┐   │
│  │ Message...              📷 🎤 ➤ │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 7.3 Status Indicators

```
┌─────────────────────────────────────────────────────────────────┐
│  CONNECTION STATUS INDICATORS                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TRANSPORT MODE (in chat header)                                 │
│  ├── ☁️  Cloud      (strong internet, normal operation)         │
│  ├── 📡  Mesh       (BLE connection to peer)                    │
│  ├── 🌉  Bridge     (relayed through another user)              │
│  └── ⏳  Queued     (no transport available, will retry)        │
│                                                                  │
│  MESSAGE STATUS (below message bubble)                           │
│  ├── ○   Pending    (not yet sent)                              │
│  ├── ✓   Sent       (delivered to server/mesh)                  │
│  ├── ✓✓  Delivered  (received by device)                        │
│  ├── ✓✓  Read       (blue, if read receipts enabled)            │
│  └── !   Failed     (tap to retry, shows reason)                │
│                                                                  │
│  GLOBAL STATUS BAR (top of chat list)                           │
│  ├── Normal:  (hidden, no banner)                               │
│  ├── Mesh:    "📡 Mesh Active · 12 peers nearby"                │
│  ├── Bridge:  "🌉 Bridging · 23 msgs relayed"                   │
│  ├── Rally:   "📍 Rally Mode · 2,400 people"                    │
│  └── Offline: "⚠️ No connection · Messages queued"              │
│                                                                  │
│  CONTACT STATUS (in contact list/header)                        │
│  ├── ●  Online      (green dot)                                 │
│  ├── ○  Offline     (gray outline)                              │
│  ├── ●  Nearby      (cyan dot, mesh reachable)                  │
│  └── (none)         (if user disabled "show online status")     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.4 Animations and Microinteractions

```dart
// Key animations to implement

class MeshLinkAnimations {
  // Message send: bubble scales up slightly then settles
  static const messageSend = Duration(milliseconds: 150);
  
  // Status change: smooth crossfade between states
  static const statusTransition = Duration(milliseconds: 200);
  
  // Mesh activation: ripple effect from status bar
  static const meshActivate = Duration(milliseconds: 400);
  
  // New message: slide in from bottom with subtle bounce
  static const messageReceive = Duration(milliseconds: 250);
  
  // Transport switch: icon morphs with rotation
  static const transportSwitch = Duration(milliseconds: 300);
  
  // Rally mode: pulse effect on participant count
  static const rallyPulse = Duration(milliseconds: 1500); // repeating
}
```

---

## 8. Onboarding and Feature Walkthrough

### 8.1 First Launch Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  ONBOARDING FLOW (5 screens)                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  SCREEN 1: Welcome                                               │
│  ─────────────────────                                           │
│  [Illustration: Two phones connected by mesh lines]             │
│                                                                  │
│  "Welcome to MeshLink"                                           │
│                                                                  │
│  Encrypted messaging that works                                  │
│  everywhere, even without internet.                              │
│                                                                  │
│  [Get Started]                                                   │
│                                                                  │
│  ───────────────────────────────────────────────────────────    │
│                                                                  │
│  SCREEN 2: How It Works                                          │
│  ──────────────────────                                          │
│  [Animation: Cloud morphing into mesh network]                  │
│                                                                  │
│  "Always Connected"                                              │
│                                                                  │
│  Strong signal? Messages go through                              │
│  encrypted cloud servers.                                        │
│                                                                  │
│  Weak signal? Messages hop through                               │
│  nearby MeshLink users via Bluetooth.                            │
│                                                                  │
│  You don't have to do anything. It just works.                   │
│                                                                  │
│  [Continue]                                                      │
│                                                                  │
│  ───────────────────────────────────────────────────────────    │
│                                                                  │
│  SCREEN 3: Privacy First                                         │
│  ───────────────────────                                         │
│  [Illustration: Lock with shield]                               │
│                                                                  │
│  "Your Messages, Your Business"                                  │
│                                                                  │
│  ✓ End-to-end encrypted                                         │
│  ✓ No phone number required                                     │
│  ✓ No data collection                                           │
│  ✓ Open protocol                                                │
│                                                                  │
│  [Continue]                                                      │
│                                                                  │
│  ───────────────────────────────────────────────────────────    │
│                                                                  │
│  SCREEN 4: Permissions                                           │
│  ─────────────────────                                           │
│  [Icons for each permission]                                    │
│                                                                  │
│  "A Few Permissions"                                             │
│                                                                  │
│  📶 Bluetooth                                                    │
│     For mesh networking with nearby users                       │
│                                                                  │
│  📍 Location (optional)                                          │
│     For Rally Mode location channels                            │
│     (Never shared with anyone)                                   │
│                                                                  │
│  🔔 Notifications                                                │
│     To alert you of new messages                                │
│                                                                  │
│  [Allow Permissions]                                             │
│  [Skip for now]                                                  │
│                                                                  │
│  ───────────────────────────────────────────────────────────    │
│                                                                  │
│  SCREEN 5: Create Identity                                       │
│  ─────────────────────────                                       │
│  [Input field with avatar picker]                               │
│                                                                  │
│  "Choose Your Name"                                              │
│                                                                  │
│  [Profile Picture] (optional)                                   │
│                                                                  │
│  Display Name: [_______________]                                │
│                                                                  │
│  This is what others will see. You can                          │
│  change it anytime.                                              │
│                                                                  │
│  🔐 Your encryption keys are being                              │
│     generated securely on this device.                          │
│                                                                  │
│  [Create Account]                                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Feature Discovery (Contextual)

```
┌─────────────────────────────────────────────────────────────────┐
│  CONTEXTUAL TIPS (shown once, dismissible)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  FIRST MESSAGE SENT                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ✓✓ means delivered                                      │    │
│  │                                                          │    │
│  │  One check = sent to server                              │    │
│  │  Two checks = delivered to recipient                     │    │
│  │  Blue checks = read (if enabled)                         │    │
│  │                                                          │    │
│  │  [Got it]                                                │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  FIRST MESH CONNECTION                                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  📡 Mesh Mode Activated                                  │    │
│  │                                                          │    │
│  │  You're now connected to 5 nearby                       │    │
│  │  MeshLink users via Bluetooth.                          │    │
│  │                                                          │    │
│  │  Messages to nearby contacts will be                    │    │
│  │  faster and work without internet.                      │    │
│  │                                                          │    │
│  │  [Cool!]                                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  BRIDGE POTENTIAL DETECTED                                       │
│  (See section 5.5 for full consent flow)                        │
│                                                                  │
│  RALLY MODE AVAILABLE                                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  📍 Rally Mode Available                                 │    │
│  │                                                          │    │
│  │  Looks like there are many people nearby.               │    │
│  │  Rally Mode lets you chat with everyone in              │    │
│  │  your area, even without cell service.                  │    │
│  │                                                          │    │
│  │  [Learn More]  [Activate]  [Not Now]                    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.3 Settings Walkthrough

First time entering Settings, highlight key sections:

```
┌─────────────────────────────────────────┐
│  ←  Settings                            │
├─────────────────────────────────────────┤
│                                         │
│  [Profile Picture]                      │
│  Your Name                              │
│  Edit profile                           │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  🔐 Privacy                        →   │
│  ┌─────────────────────────────────┐   │
│  │ ⓘ Control who sees your info   │   │  <- Tooltip
│  └─────────────────────────────────┘   │
│                                         │
│  📡 Mesh Settings                  →   │
│  ┌─────────────────────────────────┐   │
│  │ ⓘ Configure offline messaging  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  🌉 Bridge Mode                    →   │
│  ┌─────────────────────────────────┐   │
│  │ ⓘ Help others stay connected   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  🔔 Notifications                  →   │
│                                         │
│  🎨 Appearance                     →   │
│                                         │
│  💝 Support MeshLink               →   │
│                                         │
│  ℹ️  About                          →   │
│                                         │
└─────────────────────────────────────────┘
```

---

## 9. Server Infrastructure

### 9.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRODUCTION INFRASTRUCTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         CLOUDFLARE (Edge)                            │   │
│  │  ├── DDoS Protection                                                 │   │
│  │  ├── SSL Termination                                                 │   │
│  │  ├── CDN for web assets                                              │   │
│  │  └── Rate limiting                                                   │   │
│  └──────────────────────────────┬──────────────────────────────────────┘   │
│                                 │                                           │
│         ┌───────────────────────┼───────────────────────┐                  │
│         │                       │                       │                  │
│         ▼                       ▼                       ▼                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │  MATRIX CLUSTER │  │  RELAY CLUSTER  │  │   PUSH SERVICE  │            │
│  │  (Dendrite)     │  │  (Rust)         │  │   (ntfy.sh)     │            │
│  │                 │  │                 │  │                 │            │
│  │  Load Balancer  │  │  Load Balancer  │  │  Single node    │            │
│  │       │         │  │       │         │  │  (HA optional)  │            │
│  │  ┌────┴────┐    │  │  ┌────┴────┐    │  │                 │            │
│  │  │ Node 1  │    │  │  │ Node 1  │    │  └────────┬────────┘            │
│  │  │ Node 2  │    │  │  │ Node 2  │    │           │                     │
│  │  │ Node N  │    │  │  │ Node N  │    │           │                     │
│  │  └────┬────┘    │  │  └────┬────┘    │           │                     │
│  │       │         │  │       │         │           │                     │
│  └───────┼─────────┘  └───────┼─────────┘           │                     │
│          │                    │                     │                     │
│          ▼                    ▼                     │                     │
│  ┌─────────────────┐  ┌─────────────────┐          │                     │
│  │   POSTGRESQL    │  │     REDIS       │          │                     │
│  │   (Primary +    │  │   (Cluster)     │◄─────────┘                     │
│  │    Replicas)    │  │                 │                                 │
│  │                 │  │  - Relay store  │                                 │
│  │  - User data    │  │  - Rate limits  │                                 │
│  │  - Room state   │  │  - Sessions     │                                 │
│  │  - Messages     │  │  - Pub/sub      │                                 │
│  └─────────────────┘  └─────────────────┘                                 │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                        MONITORING STACK                              │  │
│  │  ├── Prometheus (metrics)                                            │  │
│  │  ├── Grafana (dashboards)                                            │  │
│  │  ├── Loki (logs)                                                     │  │
│  │  └── Alertmanager (paging)                                           │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Service Specifications

**Matrix Homeserver (Dendrite):**
```yaml
# dendrite.yaml (key sections)
global:
  server_name: meshlink.app
  private_key: /etc/dendrite/matrix_key.pem
  
  database:
    connection_string: postgres://dendrite:xxx@db:5432/dendrite?sslmode=require
    max_open_conns: 100
    max_idle_conns: 10
    
  cache:
    max_size_estimated: 1gb
    max_age: 1h

client_api:
  registration_disabled: false
  registration_shared_secret: "${REGISTRATION_SECRET}"
  rate_limiting:
    enabled: true
    threshold: 20
    cooloff_ms: 500

federation_api:
  enabled: false  # Single-server deployment initially

media_api:
  max_file_size_bytes: 26214400  # 25MB
  max_thumbnail_generators: 4
```

**Relay Server (Rust):**
```rust
// Cargo.toml dependencies
[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
redis = { version = "0.24", features = ["tokio-comp", "cluster"] }
serde = { version = "1", features = ["derive"] }
tracing = "0.1"
tracing-subscriber = "0.3"
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace"] }

// Key config
struct RelayConfig {
    redis_url: String,
    max_payload_size: usize,      // 64KB
    default_ttl_hours: u32,       // 4
    max_ttl_hours: u32,           // 24
    rate_limit_per_minute: u32,   // 60
}
```

**Push Service (ntfy.sh self-hosted):**
```yaml
# ntfy server config
base-url: "https://push.meshlink.app"
listen-http: ":8080"
cache-file: "/var/cache/ntfy/cache.db"
cache-duration: "24h"
auth-default-access: "deny-all"
behind-proxy: true
```

### 9.3 Deployment Configuration

**Docker Compose (development/small scale):**
```yaml
version: '3.8'

services:
  dendrite:
    image: matrixdotorg/dendrite-monolith:latest
    restart: unless-stopped
    volumes:
      - ./config/dendrite.yaml:/etc/dendrite/dendrite.yaml
      - dendrite_media:/var/dendrite/media
      - dendrite_jetstream:/var/dendrite/jetstream
    depends_on:
      - postgres
    environment:
      - DENDRITE_CONFIG=/etc/dendrite/dendrite.yaml
    
  relay:
    build: ./relay-server
    restart: unless-stopped
    environment:
      - REDIS_URL=redis://redis:6379
      - RUST_LOG=info
    depends_on:
      - redis
      
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=dendrite
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=dendrite
      
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    
  ntfy:
    image: binwiederhier/ntfy
    restart: unless-stopped
    volumes:
      - ./config/ntfy.yml:/etc/ntfy/server.yml
      - ntfy_cache:/var/cache/ntfy
    command: serve

volumes:
  dendrite_media:
  dendrite_jetstream:
  postgres_data:
  redis_data:
  ntfy_cache:
```

---

## 10. Cost Analysis

### 10.1 Infrastructure Costs (per 1,000 Monthly Active Users)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  COST BREAKDOWN PER 1,000 MAU                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ASSUMPTIONS:                                                                │
│  ├── 50 messages/user/day average                                           │
│  ├── 10% include media (avg 200KB)                                          │
│  ├── 5% of messages go through bridge relay                                 │
│  ├── 30-day message retention                                               │
│  ├── Peak concurrent: 10% of MAU                                            │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════    │
│                                                                              │
│  TIER 1: Minimal (1,000 MAU)                                                │
│  ──────────────────────────────                                              │
│  Single VPS deployment (Hetzner/DigitalOcean)                               │
│                                                                              │
│  │ Component              │ Spec              │ Cost/month   │              │
│  ├────────────────────────┼───────────────────┼──────────────┤              │
│  │ VPS (all services)     │ 4 vCPU, 8GB RAM   │ $24          │              │
│  │ Block storage          │ 100GB SSD         │ $10          │              │
│  │ Bandwidth              │ ~500GB            │ Included     │              │
│  │ Backups                │ Weekly            │ $5           │              │
│  │ Domain + SSL           │ Cloudflare free   │ $0           │              │
│  ├────────────────────────┼───────────────────┼──────────────┤              │
│  │ TOTAL                  │                   │ ~$39/month   │              │
│  │ Per user               │                   │ $0.039       │              │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════    │
│                                                                              │
│  TIER 2: Growth (10,000 MAU)                                                │
│  ────────────────────────────                                                │
│  Separated services, some redundancy                                        │
│                                                                              │
│  │ Component              │ Spec              │ Cost/month   │              │
│  ├────────────────────────┼───────────────────┼──────────────┤              │
│  │ Matrix server (x2)     │ 2 vCPU, 4GB each  │ $40          │              │
│  │ Relay server (x2)      │ 2 vCPU, 2GB each  │ $20          │              │
│  │ PostgreSQL             │ Managed, 2 vCPU   │ $50          │              │
│  │ Redis                  │ Managed, 1GB      │ $15          │              │
│  │ Object storage         │ 500GB (media)     │ $10          │              │
│  │ Load balancer          │ Basic             │ $10          │              │
│  │ Bandwidth              │ ~2TB              │ $20          │              │
│  │ Monitoring             │ Basic stack       │ $0 (self)    │              │
│  ├────────────────────────┼───────────────────┼──────────────┤              │
│  │ TOTAL                  │                   │ ~$165/month  │              │
│  │ Per user               │                   │ $0.0165      │              │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════    │
│                                                                              │
│  TIER 3: Scale (100,000 MAU)                                                │
│  ─────────────────────────────                                               │
│  Full HA, auto-scaling, multi-region                                        │
│                                                                              │
│  │ Component              │ Spec              │ Cost/month   │              │
│  ├────────────────────────┼───────────────────┼──────────────┤              │
│  │ Kubernetes cluster     │ 3 nodes, 4vCPU/8GB│ $200         │              │
│  │ Matrix pods (HPA)      │ 4-8 replicas      │ (included)   │              │
│  │ Relay pods (HPA)       │ 2-4 replicas      │ (included)   │              │
│  │ PostgreSQL HA          │ Primary + replica │ $150         │              │
│  │ Redis cluster          │ 3 nodes, 2GB each │ $75          │              │
│  │ Object storage         │ 5TB               │ $100         │              │
│  │ CDN (Cloudflare Pro)   │ Pro plan          │ $20          │              │
│  │ Bandwidth              │ ~20TB             │ $100         │              │
│  │ Monitoring (Datadog)   │ Basic plan        │ $50          │              │
│  │ Backup/DR              │ Cross-region      │ $50          │              │
│  ├────────────────────────┼───────────────────┼──────────────┤              │
│  │ TOTAL                  │                   │ ~$745/month  │              │
│  │ Per user               │                   │ $0.00745     │              │
│                                                                              │
│  ═══════════════════════════════════════════════════════════════════════    │
│                                                                              │
│  COST SCALING SUMMARY                                                        │
│  ────────────────────                                                        │
│  │ MAU       │ Monthly Cost │ Per User │ Notes                  │           │
│  ├───────────┼──────────────┼──────────┼────────────────────────┤           │
│  │ 1,000     │ $39          │ $0.039   │ Single server          │           │
│  │ 10,000    │ $165         │ $0.017   │ Basic redundancy       │           │
│  │ 50,000    │ $450         │ $0.009   │ Partial HA             │           │
│  │ 100,000   │ $745         │ $0.007   │ Full HA                │           │
│  │ 500,000   │ $2,500       │ $0.005   │ Multi-region           │           │
│  │ 1,000,000 │ $4,500       │ $0.0045  │ Full scale             │           │
│                                                                              │
│  Economy of scale reduces per-user cost significantly.                      │
│  Mesh/Bridge traffic is nearly free (user devices handle it).               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Donation Model Analysis

Based on Signal's model and our cost structure:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DONATION SUSTAINABILITY MODEL                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  SIGNAL'S REPORTED METRICS (for comparison):                                │
│  ├── ~40 million MAU (estimated)                                            │
│  ├── ~$50M annual costs                                                     │
│  ├── ~$1.25/user/year cost                                                  │
│  ├── Funded by: Signal Foundation, donations, grants                        │
│                                                                              │
│  MESHLINK TARGET METRICS:                                                    │
│  ├── Per-user cost: ~$0.05-0.10/year at scale                              │
│  ├── Much lower than Signal due to:                                         │
│  │   - Mesh offloads traffic to users                                       │
│  │   - No voice/video infrastructure initially                             │
│  │   - Simpler server architecture                                          │
│  │   - Bridge relay is user-powered                                         │
│                                                                              │
│  DONATION SCENARIOS:                                                         │
│  ─────────────────────                                                       │
│                                                                              │
│  Conservative (1% donate, avg $5/year):                                     │
│  │ MAU        │ Donors  │ Revenue  │ Costs   │ Surplus    │                │
│  ├────────────┼─────────┼──────────┼─────────┼────────────┤                │
│  │ 10,000     │ 100     │ $500     │ $2,000  │ -$1,500    │                │
│  │ 50,000     │ 500     │ $2,500   │ $5,400  │ -$2,900    │                │
│  │ 100,000    │ 1,000   │ $5,000   │ $8,940  │ -$3,940    │                │
│  │ 500,000    │ 5,000   │ $25,000  │ $30,000 │ -$5,000    │                │
│  │ 1,000,000  │ 10,000  │ $50,000  │ $54,000 │ -$4,000    │                │
│                                                                              │
│  Moderate (2% donate, avg $10/year):                                        │
│  │ MAU        │ Donors  │ Revenue  │ Costs   │ Surplus    │                │
│  ├────────────┼─────────┼──────────┼─────────┼────────────┤                │
│  │ 10,000     │ 200     │ $2,000   │ $2,000  │ $0         │ <- Break even │
│  │ 50,000     │ 1,000   │ $10,000  │ $5,400  │ +$4,600    │                │
│  │ 100,000    │ 2,000   │ $20,000  │ $8,940  │ +$11,060   │                │
│  │ 500,000    │ 10,000  │ $100,000 │ $30,000 │ +$70,000   │                │
│  │ 1,000,000  │ 20,000  │ $200,000 │ $54,000 │ +$146,000  │                │
│                                                                              │
│  Optimistic (3% donate, avg $15/year):                                      │
│  │ MAU        │ Donors  │ Revenue  │ Costs   │ Surplus    │                │
│  ├────────────┼─────────┼──────────┼─────────┼────────────┤                │
│  │ 10,000     │ 300     │ $4,500   │ $2,000  │ +$2,500    │                │
│  │ 100,000    │ 3,000   │ $45,000  │ $8,940  │ +$36,060   │                │
│  │ 1,000,000  │ 30,000  │ $450,000 │ $54,000 │ +$396,000  │                │
│                                                                              │
│  RECOMMENDATION:                                                             │
│  ────────────────                                                            │
│  Break-even requires ~10,000 MAU with moderate donation rate.               │
│  Early funding (grants, personal) needed for first 6-12 months.             │
│  Surplus should fund: development, security audits, reserves.               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 11. Security and Privacy

### 11.1 Threat Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  THREAT MODEL                                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PROTECTED AGAINST:                                                          │
│  ──────────────────                                                          │
│  ✓ Mass surveillance (E2E encryption)                                       │
│  ✓ Server compromise (no plaintext access)                                  │
│  ✓ Network eavesdropping (TLS + Noise)                                      │
│  ✓ Traffic analysis (fixed packet sizes, padding)                           │
│  ✓ Metadata leakage (mesh reduces server knowledge)                         │
│  ✓ Single point of failure (hybrid transport)                               │
│  ✓ Targeted blocking (mesh bypasses network blocks)                         │
│                                                                              │
│  PARTIALLY PROTECTED:                                                        │
│  ─────────────────────                                                       │
│  △ Device compromise (keys stored on device)                                │
│    Mitigation: Device encryption, biometric lock option                     │
│  △ Social engineering (user education)                                      │
│    Mitigation: Verification badges, safety tips                             │
│  △ Mesh peer identification (BLE advertising)                               │
│    Mitigation: Rotating identifiers, optional stealth mode                  │
│                                                                              │
│  NOT PROTECTED:                                                              │
│  ─────────────────                                                           │
│  ✗ Physical device access with passcode                                     │
│  ✗ Compromised recipient sharing messages                                   │
│  ✗ Legal compulsion of end users                                            │
│  ✗ Zero-day exploits in cryptographic libraries                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 11.2 Security Measures

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SECURITY IMPLEMENTATION                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  CRYPTOGRAPHIC CHOICES:                                                      │
│  ───────────────────────                                                     │
│  │ Purpose               │ Algorithm            │ Library          │        │
│  ├───────────────────────┼──────────────────────┼──────────────────┤        │
│  │ Key exchange          │ X25519               │ cryptography     │        │
│  │ Signing               │ Ed25519              │ cryptography     │        │
│  │ Symmetric encryption  │ AES-256-GCM          │ pointycastle     │        │
│  │ Hashing               │ SHA-256, BLAKE2b     │ crypto           │        │
│  │ KDF                   │ HKDF-SHA256          │ cryptography     │        │
│  │ Session protocol      │ Noise XX             │ noise_protocol   │        │
│  │ Group encryption      │ Megolm (Matrix)      │ vodozemac        │        │
│  │ Local DB encryption   │ SQLCipher (AES-256)  │ drift_sqflite    │        │
│                                                                              │
│  KEY STORAGE:                                                                │
│  ────────────                                                                │
│  iOS: Secure Enclave (hardware) via flutter_secure_storage                  │
│  Android: Keystore (hardware-backed where available)                        │
│  Desktop: OS keychain (macOS Keychain, Windows Credential Manager)          │
│                                                                              │
│  TRANSPORT SECURITY:                                                         │
│  ────────────────────                                                        │
│  Cloud: TLS 1.3 + Certificate pinning                                       │
│  Mesh: Noise Protocol over BLE (no TLS needed)                              │
│  Relay: TLS 1.3 + Encrypted payloads                                        │
│                                                                              │
│  APPLICATION SECURITY:                                                       │
│  ──────────────────────                                                      │
│  ├── No clipboard logging                                                   │
│  ├── Screenshot prevention (optional)                                       │
│  ├── App lock (biometric/PIN)                                               │
│  ├── Panic wipe (triple-tap logo)                                           │
│  ├── Memory clearing on background                                          │
│  ├── No analytics/telemetry                                                 │
│  ├── No third-party SDKs (except crypto)                                    │
│  └── Regular dependency audits                                              │
│                                                                              │
│  OPERATIONAL SECURITY:                                                       │
│  ──────────────────────                                                      │
│  ├── Server infrastructure: No logging of message content                   │
│  ├── Logs: Only metadata (timestamp, size, not content)                     │
│  ├── Retention: Minimum required (messages deleted after sync)              │
│  ├── Access: Multi-factor auth, audit logs for admin                        │
│  └── Incident response: Published security contact, bug bounty              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 11.3 Child Safety

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CHILD SAFETY MEASURES                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  RALLY MODE RESTRICTIONS:                                                    │
│  ─────────────────────────                                                   │
│  ├── Age verification required (self-declared, 16+)                         │
│  ├── On-device content filtering (ML classifier)                            │
│  ├── Report button with clear categories                                    │
│  ├── Auto-hide messages from low-reputation senders                         │
│  └── Warning banner about public nature                                     │
│                                                                              │
│  CSAM DETECTION (when media enabled):                                        │
│  ─────────────────────────────────────                                       │
│  ├── PhotoDNA or similar hash matching (on-device, before send)             │
│  ├── Match triggers: block upload, report to NCMEC                          │
│  ├── No E2E bypass (detection before encryption)                            │
│  └── Transparent policy published                                           │
│                                                                              │
│  REPORTING FLOW:                                                             │
│  ────────────────                                                            │
│  1. User long-presses message, selects "Report"                             │
│  2. Categories: Spam, Harassment, Threats, CSAM, Other                      │
│  3. For CSAM/Threats:                                                        │
│     - Content hash + reporter key queued for upload                         │
│     - Uploaded when internet available                                       │
│     - Routed to appropriate authority                                        │
│  4. User notified: "Report submitted"                                       │
│  5. Local action: Sender blocked                                            │
│                                                                              │
│  LEGAL COMPLIANCE:                                                           │
│  ─────────────────                                                           │
│  ├── NCMEC reporting for CSAM (US law requirement)                          │
│  ├── Law enforcement cooperation policy published                           │
│  ├── Transparency report (annual)                                           │
│  └── Legal counsel retained                                                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 12. Web Marketing Site

### 12.1 Site Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  MARKETING SITE MAP                                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  meshlink.app/                                                              │
│  ├── (home)              Landing page with hero, features, download         │
│  ├── /features           Detailed feature breakdown                         │
│  │   ├── /mesh           Mesh networking explained                          │
│  │   ├── /rally          Rally Mode for events                              │
│  │   └── /bridge         Bridge relay system                                │
│  ├── /security           Security whitepaper, audits                        │
│  ├── /privacy            Privacy policy, data practices                     │
│  ├── /donate             Donation page with badge preview                   │
│  ├── /about              Team, mission, contact                             │
│  ├── /blog               Updates, tutorials, stories                        │
│  └── /download           App store links, direct APK                        │
│                                                                              │
│  docs.meshlink.app/                                                         │
│  ├── /getting-started    User guides                                        │
│  ├── /protocol           Technical protocol docs                            │
│  ├── /api                API reference (for developers)                     │
│  └── /contribute         How to contribute                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 12.2 Landing Page Design

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  LANDING PAGE WIREFRAME                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  [Logo] MeshLink          Features  Security  Donate  Download       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │              HERO SECTION                                            │   │
│  │              ────────────                                            │   │
│  │                                                                      │   │
│  │    ┌─────────────────────────┐    Messaging that                    │   │
│  │    │                         │    finds a way.                       │   │
│  │    │   [Animated phone       │                                       │   │
│  │    │    showing mesh         │    Encrypted. Offline-capable.        │   │
│  │    │    connections forming] │    Community-powered.                 │   │
│  │    │                         │                                       │   │
│  │    └─────────────────────────┘    [Download]  [Learn More]          │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │              HOW IT WORKS                                            │   │
│  │              ────────────                                            │   │
│  │                                                                      │   │
│  │    ┌──────────┐     ┌──────────┐     ┌──────────┐                   │   │
│  │    │    ☁️    │     │    📡    │     │    🌉    │                   │   │
│  │    │  Cloud   │     │   Mesh   │     │  Bridge  │                   │   │
│  │    │          │     │          │     │          │                   │   │
│  │    │ Strong   │ ──► │ Weak     │ ──► │ Someone  │                   │   │
│  │    │ signal?  │     │ signal?  │     │ nearby   │                   │   │
│  │    │ Cloud.   │     │ Bluetooth│     │ can help │                   │   │
│  │    └──────────┘     └──────────┘     └──────────┘                   │   │
│  │                                                                      │   │
│  │    You don't have to think about it. It just works.                  │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │              FEATURES (Cards)                                        │   │
│  │              ────────────────                                        │   │
│  │                                                                      │   │
│  │    ┌────────────────┐  ┌────────────────┐  ┌────────────────┐       │   │
│  │    │ 🔐 Private     │  │ 📡 Mesh Mode   │  │ 📍 Rally Mode  │       │   │
│  │    │                │  │                │  │                │       │   │
│  │    │ End-to-end     │  │ No internet?   │  │ At a concert?  │       │   │
│  │    │ encrypted.     │  │ No problem.    │  │ Chat with      │       │   │
│  │    │ Always.        │  │ Messages hop   │  │ everyone       │       │   │
│  │    │                │  │ through nearby │  │ nearby.        │       │   │
│  │    │ [Learn more]   │  │ users.         │  │                │       │   │
│  │    └────────────────┘  └────────────────┘  └────────────────┘       │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │              TRUST INDICATORS                                        │   │
│  │              ────────────────                                        │   │
│  │                                                                      │   │
│  │    ✓ Open source          ✓ No phone number required                │   │
│  │    ✓ No data collection   ✓ Community funded                        │   │
│  │    ✓ Security audited     ✓ Public domain protocol                  │   │
│  │                                                                      │   │
│  │    [View Security Report]  [Read the Code]                          │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │              DOWNLOAD CTA                                            │   │
│  │              ────────────                                            │   │
│  │                                                                      │   │
│  │         Ready to message without limits?                            │   │
│  │                                                                      │   │
│  │    [App Store]  [Google Play]  [Direct Download]                    │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Footer: About | Security | Privacy | Donate | GitHub | Contact     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 12.3 Design Specifications

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  WEB DESIGN SYSTEM                                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  TYPOGRAPHY:                                                                 │
│  ├── Display: "Cabinet Grotesk" (bold, distinctive)                         │
│  ├── Body: "Satoshi" (clean, readable)                                      │
│  ├── Mono: "JetBrains Mono" (code blocks)                                   │
│  └── Fallbacks: system-ui, sans-serif                                       │
│                                                                              │
│  COLORS:                                                                     │
│  ├── Background: #FEFEFE (warm off-white)                                   │
│  ├── Text: #1A1A1A                                                          │
│  ├── Primary: #1B7F6E (teal)                                                │
│  ├── Accent: #FFB300 (amber, for highlights)                                │
│  └── Gradient: teal to cyan (mesh visualization)                            │
│                                                                              │
│  ANIMATIONS:                                                                 │
│  ├── Hero: Mesh network forming animation (Three.js or Lottie)              │
│  ├── Scroll: Fade-in on scroll for sections                                 │
│  ├── Hover: Subtle lift on cards                                            │
│  └── Page transitions: Smooth fade                                          │
│                                                                              │
│  RESPONSIVE BREAKPOINTS:                                                     │
│  ├── Mobile: < 640px                                                        │
│  ├── Tablet: 640px - 1024px                                                 │
│  └── Desktop: > 1024px                                                      │
│                                                                              │
│  ACCESSIBILITY:                                                              │
│  ├── WCAG 2.1 AA compliant                                                  │
│  ├── Keyboard navigable                                                     │
│  ├── Screen reader optimized                                                │
│  ├── Reduced motion support                                                 │
│  └── High contrast mode                                                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 13. Donation System

### 13.1 Donation Tiers and Badges

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DONATION TIERS                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  TIER STRUCTURE:                                                             │
│  ────────────────                                                            │
│                                                                              │
│  │ Tier        │ Amount      │ Badge     │ Perks                        │  │
│  ├─────────────┼─────────────┼───────────┼──────────────────────────────┤  │
│  │ Supporter   │ Any amount  │ 💚        │ Green heart badge            │  │
│  │ Contributor │ $5+/month   │ 🌟        │ Star badge, early features   │  │
│  │ Champion    │ $20+/month  │ 🏆        │ Trophy badge, beta access    │  │
│  │ Guardian    │ $50+/month  │ 🛡️        │ Shield badge, name in app    │  │
│  │ Lifetime    │ $500 once   │ ✨        │ Sparkle badge, permanent     │  │
│                                                                              │
│  BADGE DISPLAY:                                                              │
│  ───────────────                                                             │
│  - Shown next to name in chats (optional, user can hide)                    │
│  - Shown in profile                                                          │
│  - Does NOT affect functionality (no pay-to-win)                            │
│  - Badges are purely cosmetic appreciation                                   │
│                                                                              │
│  DONATION TRANSPARENCY:                                                      │
│  ───────────────────────                                                     │
│  - Monthly financial report published                                       │
│  - Breakdown: Infrastructure X%, Development Y%, Reserve Z%                  │
│  - Donor list (opt-in) on website                                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 13.2 Payment Integration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PAYMENT METHODS                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PRIMARY (Low friction):                                                     │
│  ├── Stripe (credit card, Apple Pay, Google Pay)                            │
│  ├── PayPal                                                                 │
│  └── In-app purchase (iOS/Android for simplicity)                           │
│                                                                              │
│  PRIVACY-FOCUSED:                                                            │
│  ├── Bitcoin (via BTCPay Server, self-hosted)                               │
│  ├── Monero (XMR)                                                           │
│  └── Cash/check by mail (for maximum privacy)                               │
│                                                                              │
│  IMPLEMENTATION:                                                             │
│  ├── In-app: Navigate to Settings > Support MeshLink                        │
│  ├── Web: meshlink.app/donate                                               │
│  ├── Anonymous option: Generate one-time payment link                       │
│  └── Receipt: Email (optional) or in-app confirmation                       │
│                                                                              │
│  BADGE ASSIGNMENT:                                                           │
│  ├── Stripe/PayPal: Webhook triggers badge assignment                       │
│  ├── Crypto: Manual verification or BTCPay webhook                          │
│  ├── In-app: Platform receipt verification                                  │
│  └── Badge synced to account, visible across devices                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 13.3 Donation Page UX

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DONATION PAGE WIREFRAME                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │         Keep MeshLink Free and Independent                          │   │
│  │                                                                      │   │
│  │    MeshLink is funded entirely by people like you.                  │   │
│  │    No ads. No tracking. No investors to please.                     │   │
│  │                                                                      │   │
│  │    ────────────────────────────────────────────                     │   │
│  │                                                                      │   │
│  │    Current costs: $745/month                                        │   │
│  │    This month's donations: $892                                     │   │
│  │    ████████████████████░░░░  120% funded                            │   │
│  │                                                                      │   │
│  │    ────────────────────────────────────────────                     │   │
│  │                                                                      │   │
│  │    Choose your support level:                                       │   │
│  │                                                                      │   │
│  │    ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐              │   │
│  │    │  $5     │  │  $10    │  │  $20    │  │ Custom  │              │   │
│  │    │ /month  │  │ /month  │  │ /month  │  │         │              │   │
│  │    │   💚    │  │   🌟    │  │   🏆    │  │   🎁    │              │   │
│  │    └─────────┘  └─────────┘  └─────────┘  └─────────┘              │   │
│  │                                                                      │   │
│  │    □ One-time donation instead                                      │   │
│  │                                                                      │   │
│  │    ────────────────────────────────────────────                     │   │
│  │                                                                      │   │
│  │    Payment method:                                                  │   │
│  │    ○ Card  ○ PayPal  ○ Bitcoin  ○ Other crypto                     │   │
│  │                                                                      │   │
│  │    [Continue to Payment]                                            │   │
│  │                                                                      │   │
│  │    ────────────────────────────────────────────                     │   │
│  │                                                                      │   │
│  │    Where your donation goes:                                        │   │
│  │    ├── 60% Server infrastructure                                    │   │
│  │    ├── 25% Development & security audits                            │   │
│  │    └── 15% Reserve fund                                             │   │
│  │                                                                      │   │
│  │    [View Financial Reports]                                         │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 14. Implementation Phases

### 14.1 Development Roadmap

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  IMPLEMENTATION PHASES                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  PHASE 0: Foundation (Weeks 1-4)                                            │
│  ════════════════════════════════                                            │
│  □ Project setup                                                            │
│    ├── Flutter project initialization with Melos                            │
│    ├── CI/CD pipeline (GitHub Actions)                                      │
│    ├── Linting and code style configuration                                 │
│    └── Documentation structure (Docusaurus)                                 │
│  □ Core architecture                                                        │
│    ├── Riverpod state management setup                                      │
│    ├── Drift database schema                                                │
│    ├── Crypto service abstraction                                           │
│    └── Transport manager interface                                          │
│  □ Identity system                                                          │
│    ├── Key generation (Ed25519, X25519)                                     │
│    ├── Secure storage integration                                           │
│    └── Identity export/import                                               │
│  Deliverable: Running app with identity creation, no messaging              │
│                                                                              │
│  PHASE 1: Cloud Messaging (Weeks 5-10)                                      │
│  ══════════════════════════════════════                                      │
│  □ Matrix integration                                                       │
│    ├── matrix_dart_sdk setup                                                │
│    ├── Account registration/login                                           │
│    ├── Room creation and management                                         │
│    └── E2E encryption (Megolm)                                              │
│  □ Basic messaging                                                          │
│    ├── 1:1 conversations                                                    │
│    ├── Text messages with delivery status                                   │
│    ├── Message persistence (local + sync)                                   │
│    └── Push notifications                                                   │
│  □ UI implementation                                                        │
│    ├── Chat list screen                                                     │
│    ├── Chat view screen                                                     │
│    ├── Contact management                                                   │
│    └── Settings screens                                                     │
│  □ Backend deployment                                                       │
│    ├── Dendrite homeserver                                                  │
│    ├── PostgreSQL setup                                                     │
│    └── Basic monitoring                                                     │
│  Deliverable: Functional Signal-like messaging app                          │
│                                                                              │
│  PHASE 2: Mesh Networking (Weeks 11-18)                                     │
│  ═══════════════════════════════════════                                     │
│  □ BLE implementation                                                       │
│    ├── flutter_blue_plus integration                                        │
│    ├── Peripheral/central mode                                              │
│    ├── Service/characteristic setup                                         │
│    └── Connection management                                                │
│  □ Mesh protocol                                                            │
│    ├── Packet format implementation                                         │
│    ├── Noise Protocol handshake                                             │
│    ├── Peer discovery and announcement                                      │
│    ├── Flooding/gossip routing                                              │
│    ├── Bloom filter for dedup                                               │
│    └── Store-and-forward                                                    │
│  □ Transport switching                                                      │
│    ├── Network quality monitoring                                           │
│    ├── Automatic transport selection                                        │
│    ├── Message deduplication                                                │
│    └── Status indicators                                                    │
│  □ Background operation                                                     │
│    ├── iOS background modes                                                 │
│    ├── Android foreground service                                           │
│    └── Battery optimization                                                 │
│  Deliverable: Hybrid cloud/mesh messaging                                   │
│                                                                              │
│  PHASE 3: Rally Mode (Weeks 19-24)                                          │
│  ═════════════════════════════════                                           │
│  □ Channel system                                                           │
│    ├── Geohash-based channel discovery                                      │
│    ├── Channel key derivation                                               │
│    ├── Ephemeral identity generation                                        │
│    └── Channel UI                                                           │
│  □ Moderation                                                               │
│    ├── Local reputation system                                              │
│    ├── Block/mute functionality                                             │
│    ├── Report flow                                                          │
│    └── Content filtering (on-device ML)                                     │
│  □ Safety features                                                          │
│    ├── Age verification                                                     │
│    ├── CSAM detection integration                                           │
│    └── Report queue for upload                                              │
│  Deliverable: Complete Rally Mode                                           │
│                                                                              │
│  PHASE 4: Bridge Relay (Weeks 25-30)                                        │
│  ════════════════════════════════════                                        │
│  □ Relay server                                                             │
│    ├── Rust service implementation                                          │
│    ├── Redis integration                                                    │
│    ├── API endpoints                                                        │
│    └── Rate limiting                                                        │
│  □ Bridge client                                                            │
│    ├── Edge detection                                                       │
│    ├── Consent flow                                                         │
│    ├── Envelope wrapping                                                    │
│    ├── Upload queue                                                         │
│    └── Status indicators                                                    │
│  □ Recipient polling                                                        │
│    ├── Background polling                                                   │
│    ├── Decryption and delivery                                              │
│    └── Deduplication with mesh/cloud                                        │
│  Deliverable: Complete bridge relay system                                  │
│                                                                              │
│  PHASE 5: Polish and Launch (Weeks 31-36)                                   │
│  ═════════════════════════════════════════                                   │
│  □ Media support                                                            │
│    ├── Image sending (compression, thumbnails)                              │
│    ├── Voice notes                                                          │
│    ├── File attachments                                                     │
│    └── Media over mesh (chunking)                                           │
│  □ Group chats                                                              │
│    ├── Group creation and management                                        │
│    ├── Admin controls                                                       │
│    └── Group encryption                                                     │
│  □ Onboarding                                                               │
│    ├── First-launch flow                                                    │
│    ├── Contextual tips                                                      │
│    └── Feature discovery                                                    │
│  □ Web marketing site                                                       │
│    ├── Astro site development                                               │
│    ├── Content writing                                                      │
│    └── SEO optimization                                                     │
│  □ Donation system                                                          │
│    ├── Payment integration                                                  │
│    ├── Badge system                                                         │
│    └── Transparency reports                                                 │
│  □ Launch preparation                                                       │
│    ├── Security audit                                                       │
│    ├── Beta testing                                                         │
│    ├── App store submissions                                                │
│    └── Launch marketing                                                     │
│  Deliverable: Public launch                                                 │
│                                                                              │
│  POST-LAUNCH (Ongoing)                                                      │
│  ═════════════════════                                                       │
│  □ Voice/video calls                                                        │
│  □ Desktop apps (Windows, macOS, Linux)                                     │
│  □ Multi-device sync                                                        │
│  □ Meshtastic/LoRa integration                                              │
│  □ Protocol standardization                                                 │
│  □ Community relay federation                                               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 14.2 Milestone Definitions

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  MILESTONE CRITERIA                                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  M1: ALPHA (End of Phase 2)                                                 │
│  ──────────────────────────                                                  │
│  ✓ Cloud messaging functional                                               │
│  ✓ Mesh messaging functional                                                │
│  ✓ Automatic transport switching                                            │
│  ✓ Basic UI complete                                                        │
│  ✗ No media, groups, rally, or bridge                                       │
│  Target: Internal testing only                                              │
│                                                                              │
│  M2: BETA (End of Phase 4)                                                  │
│  ─────────────────────────                                                   │
│  ✓ All core features functional                                             │
│  ✓ Rally mode complete                                                      │
│  ✓ Bridge relay complete                                                    │
│  ✓ Basic onboarding                                                         │
│  ✗ May have rough edges, bugs                                               │
│  Target: Public beta (TestFlight, APK)                                      │
│                                                                              │
│  M3: RELEASE CANDIDATE (Week 34)                                            │
│  ─────────────────────────────────                                           │
│  ✓ All features complete                                                    │
│  ✓ Security audit passed                                                    │
│  ✓ Performance optimized                                                    │
│  ✓ Onboarding polished                                                      │
│  ✓ Marketing site live                                                      │
│  Target: Final testing before launch                                        │
│                                                                              │
│  M4: PUBLIC LAUNCH (Week 36)                                                │
│  ───────────────────────────                                                 │
│  ✓ App store approved                                                       │
│  ✓ Donation system live                                                     │
│  ✓ Documentation complete                                                   │
│  ✓ Support channels established                                             │
│  Target: General availability                                               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 15. Claude Code CLI Integration

### 15.1 Recommended Agents/Skills

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CLAUDE CODE CLI CONFIGURATION                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  CUSTOM AGENTS TO CREATE:                                                    │
│  ─────────────────────────                                                   │
│                                                                              │
│  1. flutter-expert                                                          │
│     Purpose: Flutter/Dart development assistance                            │
│     Knowledge:                                                               │
│     ├── Flutter 3.x best practices                                          │
│     ├── Riverpod state management patterns                                  │
│     ├── Drift database patterns                                             │
│     ├── Platform channels for native code                                   │
│     └── Performance optimization                                            │
│     Files to include:                                                        │
│     ├── pubspec.yaml                                                        │
│     ├── lib/ structure                                                      │
│     └── This spec document                                                  │
│                                                                              │
│  2. crypto-protocol                                                         │
│     Purpose: Cryptography and protocol implementation                       │
│     Knowledge:                                                               │
│     ├── Noise Protocol specification                                        │
│     ├── X25519, Ed25519 operations                                          │
│     ├── AES-GCM encryption                                                  │
│     ├── BitChat protocol reference                                          │
│     └── Matrix E2E encryption (Olm/Megolm)                                  │
│     Files to include:                                                        │
│     ├── Protocol spec sections from this doc                                │
│     ├── Reference implementations                                           │
│     └── Test vectors                                                        │
│                                                                              │
│  3. ble-mesh                                                                │
│     Purpose: Bluetooth Low Energy mesh networking                           │
│     Knowledge:                                                               │
│     ├── BLE GATT services and characteristics                               │
│     ├── flutter_blue_plus API                                               │
│     ├── iOS CoreBluetooth background modes                                  │
│     ├── Android BLE best practices                                          │
│     └── Mesh routing algorithms                                             │
│     Files to include:                                                        │
│     ├── BLE service definitions                                             │
│     └── Routing algorithm pseudocode                                        │
│                                                                              │
│  4. security-reviewer                                                       │
│     Purpose: Security review and vulnerability detection                    │
│     Knowledge:                                                               │
│     ├── OWASP mobile security                                               │
│     ├── Cryptographic best practices                                        │
│     ├── Common Flutter security issues                                      │
│     └── Privacy-preserving design patterns                                  │
│     Mode: Review-focused, suggests improvements                             │
│                                                                              │
│  5. ui-design                                                               │
│     Purpose: UI implementation and design system                            │
│     Knowledge:                                                               │
│     ├── MeshLink design system (from this doc)                              │
│     ├── Flutter custom painting                                             │
│     ├── Animation best practices                                            │
│     └── Accessibility requirements                                          │
│     Files to include:                                                        │
│     ├── Design system constants                                             │
│     └── Component library                                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 15.2 Project Structure for CLI

```
meshlink/
├── .claude/
│   ├── config.yaml              # Claude Code CLI configuration
│   ├── agents/
│   │   ├── flutter-expert.md
│   │   ├── crypto-protocol.md
│   │   ├── ble-mesh.md
│   │   ├── security-reviewer.md
│   │   └── ui-design.md
│   └── context/
│       ├── SPEC.md              # This document
│       ├── ARCHITECTURE.md      # Extracted architecture details
│       └── PROTOCOLS.md         # Protocol specifications
├── apps/
│   ├── mobile/                  # Flutter mobile app
│   │   ├── lib/
│   │   │   ├── core/           # Core utilities, constants
│   │   │   ├── data/           # Data layer (repos, sources)
│   │   │   ├── domain/         # Domain models, use cases
│   │   │   ├── presentation/   # UI (screens, widgets)
│   │   │   └── main.dart
│   │   ├── test/
│   │   ├── integration_test/
│   │   └── pubspec.yaml
│   └── web/                     # Marketing website (Astro)
├── packages/
│   ├── meshlink_core/           # Shared Dart code
│   │   ├── lib/
│   │   │   ├── crypto/
│   │   │   ├── mesh/
│   │   │   ├── transport/
│   │   │   └── models/
│   │   └── pubspec.yaml
│   └── meshlink_ui/             # Shared UI components
├── server/
│   ├── relay/                   # Rust relay server
│   │   ├── src/
│   │   └── Cargo.toml
│   └── config/                  # Server configurations
│       ├── dendrite.yaml
│       └── docker-compose.yml
├── docs/                        # Docusaurus documentation
├── melos.yaml                   # Monorepo configuration
└── README.md
```

### 15.3 Claude Code CLI Config

```yaml
# .claude/config.yaml

project:
  name: meshlink
  description: "Hybrid cloud/mesh encrypted messaging app"
  
context:
  always_include:
    - .claude/context/SPEC.md
    - apps/mobile/pubspec.yaml
  
agents:
  default: flutter-expert
  available:
    - flutter-expert
    - crypto-protocol
    - ble-mesh
    - security-reviewer
    - ui-design
    
conventions:
  dart:
    style: effective_dart
    null_safety: strict
    analysis_options: strict
  
  naming:
    files: snake_case
    classes: PascalCase
    variables: camelCase
    constants: SCREAMING_SNAKE_CASE
    
  architecture:
    pattern: clean_architecture
    state_management: riverpod
    
commands:
  test: "melos run test"
  build: "melos run build"
  analyze: "melos run analyze"
  format: "melos run format"
```

### 15.4 Example Agent Prompt (flutter-expert.md)

```markdown
# Flutter Expert Agent

You are an expert Flutter/Dart developer working on MeshLink, a hybrid cloud/mesh encrypted messaging application.

## Your Expertise

- Flutter 3.x and Dart 3.x
- Riverpod for state management
- Drift (formerly Moor) for SQLite
- Clean Architecture patterns
- Platform channels for native integration
- Performance optimization

## Project Context

MeshLink is a privacy-first messaging app that:
1. Uses Matrix protocol for cloud messaging
2. Uses BLE mesh networking for offline messaging
3. Automatically switches between transports
4. Supports Rally Mode (location-based public channels)
5. Supports Bridge Mode (AirTag-style relay)

## Code Style

- Follow Effective Dart guidelines
- Use strict null safety
- Prefer immutable data classes (freezed)
- Use Riverpod providers for dependency injection
- Write tests for all business logic

## When Writing Code

1. Always consider the encryption layer
2. Handle offline scenarios gracefully
3. Minimize battery usage for background operations
4. Follow the design system in the spec
5. Include error handling and logging

## Architecture Layers

```
presentation/  -> UI, widgets, screens
domain/        -> Use cases, entities, repository interfaces
data/          -> Repository implementations, data sources, DTOs
core/          -> Utilities, constants, extensions
```

Refer to the full specification in .claude/context/SPEC.md for detailed requirements.
```

---

## 16. Appendices

### 16.1 Glossary

| Term | Definition |
|------|------------|
| BLE | Bluetooth Low Energy, the wireless protocol used for mesh networking |
| Bridge | A user with internet who relays messages for users without |
| E2E | End-to-end encryption, where only sender and recipient can read messages |
| Geohash | A string encoding of geographic coordinates for location channels |
| MAU | Monthly Active Users |
| Megolm | Matrix's group encryption protocol |
| Mesh | Network topology where devices relay messages through each other |
| Noise Protocol | Cryptographic framework for secure channel establishment |
| Rally Mode | Public channel for all users in a geographic area |
| TTL | Time-to-live, controls how long messages or packets persist |
| X25519 | Elliptic curve Diffie-Hellman for key exchange |

### 16.2 Reference Links

**Protocols:**
- [Noise Protocol Framework](http://noiseprotocol.org/)
- [Matrix Specification](https://spec.matrix.org/)
- [BitChat Repository](https://github.com/permissionlesstech/bitchat)

**Libraries:**
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- [matrix_dart_sdk](https://pub.dev/packages/matrix)
- [drift](https://pub.dev/packages/drift)
- [riverpod](https://riverpod.dev/)

**Infrastructure:**
- [Dendrite](https://github.com/matrix-org/dendrite)
- [ntfy.sh](https://ntfy.sh/)

### 16.3 Open Questions

1. **Federation**: Should we support Matrix federation from day one, or start single-server?
   - Recommendation: Start single-server, add federation post-launch

2. **Desktop**: Should desktop apps be Flutter or native?
   - Recommendation: Flutter for consistency, evaluate performance

3. **LoRa Integration**: Should we build Meshtastic bridge?
   - Recommendation: Post-launch feature based on demand

4. **Moderation at Scale**: How to handle Rally Mode abuse at large events?
   - Needs further design for reputation federation

5. **Legal Entity**: What structure for accepting donations?
   - Options: 501(c)(3) nonprofit, fiscal sponsor, or for-profit with mission

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0-draft | 2026-01-17 | Claude + User | Initial specification |

---

*This specification is a living document. Updates should be tracked in version control with meaningful commit messages.*
