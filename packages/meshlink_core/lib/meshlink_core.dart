/// MeshLink Core Library
///
/// Provides core functionality for MeshLink including:
/// - Cryptography (Ed25519, X25519, Noise Protocol)
/// - Mesh networking protocols
/// - Transport layer abstractions
/// - Data models and persistence
library meshlink_core;

// Crypto exports
export 'crypto/identity_service.dart';
export 'crypto/secure_storage.dart';
export 'crypto/bridge_encryption.dart';

// Models exports
export 'models/identity.dart';
export 'models/key_pair.dart';
export 'models/message.dart';
export 'models/contact.dart';

// Transport exports
export 'transport/transport_manager.dart';
export 'transport/cloud_transport.dart';
export 'transport/mesh_transport.dart';
export 'transport/bridge_transport.dart';

// Database exports
export 'database/app_database.dart';

// Auth exports
export 'auth/account.dart';
export 'auth/auth_service.dart';
export 'auth/passkey_service.dart';
