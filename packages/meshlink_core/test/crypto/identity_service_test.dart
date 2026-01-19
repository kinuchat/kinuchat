import 'package:test/test.dart';
import '../../lib/crypto/identity_service.dart';
import '../../lib/crypto/secure_storage.dart';
import '../../lib/models/identity.dart';
import 'mock_secure_storage.dart';

void main() {
  group('IdentityService', () {
    late IdentityService identityService;
    late MockSecureStorage secureStorage;

    setUp(() {
      secureStorage = MockSecureStorage();
      identityService = IdentityService(secureStorage);
    });

    tearDown(() {
      secureStorage.clear();
    });

    group('generateIdentity', () {
      test('generates a valid identity with Ed25519 and X25519 key pairs', () async {
        final identity = await identityService.generateIdentity();

        // Verify Ed25519 key pair
        expect(identity.signingKeyPair.publicKey.length, equals(32));
        expect(identity.signingKeyPair.privateKey.length, equals(32));

        // Verify X25519 key pair
        expect(identity.exchangeKeyPair.publicKey.length, equals(32));
        expect(identity.exchangeKeyPair.privateKey.length, equals(32));

        // Verify mesh peer ID is 8 bytes
        expect(identity.meshPeerId.length, equals(8));

        // Verify created timestamp
        expect(identity.createdAt, isNotNull);
        expect(
          identity.createdAt.difference(DateTime.now()).abs().inSeconds,
          lessThan(2),
        );
      });

      test('generates unique identities each time', () async {
        final identity1 = await identityService.generateIdentity();
        final identity2 = await identityService.generateIdentity();

        // Ed25519 keys should be different
        expect(
          identity1.signingKeyPair.publicKey,
          isNot(equals(identity2.signingKeyPair.publicKey)),
        );

        // X25519 keys should be different
        expect(
          identity1.exchangeKeyPair.publicKey,
          isNot(equals(identity2.exchangeKeyPair.publicKey)),
        );

        // Mesh peer IDs should be different
        expect(
          identity1.meshPeerId,
          isNot(equals(identity2.meshPeerId)),
        );
      });

      test('stores identity in secure storage', () async {
        final identity = await identityService.generateIdentity(
          displayName: 'Test User',
        );

        // Verify keys are stored
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.ed25519PublicKey,
          ),
          isTrue,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.ed25519PrivateKey,
          ),
          isTrue,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.x25519PublicKey,
          ),
          isTrue,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.x25519PrivateKey,
          ),
          isTrue,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.identityMetadata,
          ),
          isTrue,
        );
      });

      test('stores display name and avatar', () async {
        const displayName = 'Alice';
        const avatar = 'https://example.com/avatar.png';

        final identity = await identityService.generateIdentity(
          displayName: displayName,
          avatar: avatar,
        );

        expect(identity.displayName, equals(displayName));
        expect(identity.avatar, equals(avatar));
      });
    });

    group('loadIdentity', () {
      test('loads stored identity correctly', () async {
        // Generate and store an identity
        final originalIdentity = await identityService.generateIdentity(
          displayName: 'Bob',
          avatar: 'avatar.jpg',
        );

        // Load the identity
        final loadedIdentity = await identityService.loadIdentity();

        expect(loadedIdentity, isNotNull);
        expect(
          loadedIdentity!.signingKeyPair.publicKey,
          equals(originalIdentity.signingKeyPair.publicKey),
        );
        expect(
          loadedIdentity.signingKeyPair.privateKey,
          equals(originalIdentity.signingKeyPair.privateKey),
        );
        expect(
          loadedIdentity.exchangeKeyPair.publicKey,
          equals(originalIdentity.exchangeKeyPair.publicKey),
        );
        expect(
          loadedIdentity.exchangeKeyPair.privateKey,
          equals(originalIdentity.exchangeKeyPair.privateKey),
        );
        expect(loadedIdentity.meshPeerId, equals(originalIdentity.meshPeerId));
        expect(loadedIdentity.displayName, equals('Bob'));
        expect(loadedIdentity.avatar, equals('avatar.jpg'));
      });

      test('returns null when no identity is stored', () async {
        final identity = await identityService.loadIdentity();
        expect(identity, isNull);
      });

      test('throws exception when storage has incomplete keys', () async {
        // Store only some keys
        await secureStorage.write(
          key: SecureStorageKeys.ed25519PublicKey,
          value: 'incomplete',
        );

        expect(
          () => identityService.loadIdentity(),
          throwsA(isA<IdentityServiceException>()),
        );
      });
    });

    group('deleteIdentity', () {
      test('removes all identity data from storage', () async {
        // Generate an identity
        await identityService.generateIdentity();

        // Verify keys exist
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.ed25519PublicKey,
          ),
          isTrue,
        );

        // Delete identity
        await identityService.deleteIdentity();

        // Verify keys are deleted
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.ed25519PublicKey,
          ),
          isFalse,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.ed25519PrivateKey,
          ),
          isFalse,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.x25519PublicKey,
          ),
          isFalse,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.x25519PrivateKey,
          ),
          isFalse,
        );
        expect(
          await secureStorage.containsKey(
            key: SecureStorageKeys.identityMetadata,
          ),
          isFalse,
        );
      });
    });

    group('exportIdentity and importIdentity', () {
      test('exports and imports identity successfully', () async {
        // Generate an identity
        final originalIdentity = await identityService.generateIdentity(
          displayName: 'Charlie',
          avatar: 'charlie.png',
        );

        // Export the identity
        const password = 'securePassword123';
        final backup = await identityService.exportIdentity(
          originalIdentity,
          password,
        );

        expect(backup, isNotEmpty);

        // Clear storage
        await identityService.deleteIdentity();

        // Import the identity
        final importedIdentity = await identityService.importIdentity(
          backup,
          password,
        );

        // Verify the imported identity matches
        expect(
          importedIdentity.signingKeyPair.publicKey,
          equals(originalIdentity.signingKeyPair.publicKey),
        );
        expect(
          importedIdentity.signingKeyPair.privateKey,
          equals(originalIdentity.signingKeyPair.privateKey),
        );
        expect(
          importedIdentity.exchangeKeyPair.publicKey,
          equals(originalIdentity.exchangeKeyPair.publicKey),
        );
        expect(
          importedIdentity.exchangeKeyPair.privateKey,
          equals(originalIdentity.exchangeKeyPair.privateKey),
        );
        expect(
          importedIdentity.meshPeerId,
          equals(originalIdentity.meshPeerId),
        );
        expect(importedIdentity.displayName, equals('Charlie'));
        expect(importedIdentity.avatar, equals('charlie.png'));
      });

      test('import fails with wrong password', () async {
        final identity = await identityService.generateIdentity();
        final backup = await identityService.exportIdentity(
          identity,
          'correctPassword',
        );

        await identityService.deleteIdentity();

        expect(
          () => identityService.importIdentity(backup, 'wrongPassword'),
          throwsA(isA<IdentityServiceException>()),
        );
      });
    });

    group('updateIdentityMetadata', () {
      test('updates display name and avatar', () async {
        final identity = await identityService.generateIdentity(
          displayName: 'Old Name',
        );

        await identityService.updateIdentityMetadata(
          identity: identity,
          displayName: 'New Name',
          avatar: 'new_avatar.png',
        );

        final loadedIdentity = await identityService.loadIdentity();
        expect(loadedIdentity!.displayName, equals('New Name'));
        expect(loadedIdentity.avatar, equals('new_avatar.png'));
      });
    });

    group('identity properties', () {
      test('signingKeyFingerprint returns hex-encoded public key', () async {
        final identity = await identityService.generateIdentity();
        final fingerprint = identity.signingKeyFingerprint;

        // Should be 64 hex characters (32 bytes * 2)
        expect(fingerprint.length, equals(64));
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(fingerprint), isTrue);
      });

      test('meshPeerIdHex returns hex-encoded mesh peer ID', () async {
        final identity = await identityService.generateIdentity();
        final meshPeerIdHex = identity.meshPeerIdHex;

        // Should be 16 hex characters (8 bytes * 2)
        expect(meshPeerIdHex.length, equals(16));
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(meshPeerIdHex), isTrue);
      });
    });
  });
}
