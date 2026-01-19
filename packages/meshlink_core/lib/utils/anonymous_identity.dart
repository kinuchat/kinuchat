import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Generates anonymous identities for Rally Mode
///
/// Anonymous identities provide privacy while allowing participation in
/// public Rally channels. Each identity is:
/// - Randomly generated
/// - Non-traceable across sessions
/// - Human-readable (adjective-noun-number format)
///
/// Example identities:
/// - anon-happy-fox-42
/// - anon-clever-owl-17
/// - anon-brave-wolf-99
class AnonymousIdentity {
  static final _adjectives = [
    'happy',
    'clever',
    'brave',
    'swift',
    'bright',
    'calm',
    'wise',
    'kind',
    'bold',
    'cool',
    'fair',
    'keen',
    'mild',
    'neat',
    'pure',
    'rare',
    'wild',
    'warm',
    'safe',
    'true',
    'quick',
    'quiet',
    'eager',
    'great',
    'noble',
    'proud',
    'loyal',
    'gentle',
    'honest',
    'humble',
    'steady',
    'lively',
  ];

  static final _nouns = [
    'fox',
    'owl',
    'bear',
    'wolf',
    'hawk',
    'lion',
    'seal',
    'deer',
    'crow',
    'dove',
    'lynx',
    'orca',
    'puma',
    'swan',
    'eagle',
    'tiger',
    'raven',
    'otter',
    'moose',
    'crane',
    'bison',
    'gecko',
    'finch',
    'heron',
    'manta',
    'panda',
    'koala',
    'sloth',
    'lemur',
    'quail',
    'badger',
    'falcon',
  ];

  /// Generate anonymous display name
  ///
  /// Format: anon-[adjective]-[noun]-[number]
  ///
  /// Example:
  /// ```dart
  /// final name = AnonymousIdentity.generate();
  /// print(name); // "anon-happy-fox-42"
  /// ```
  static String generate() {
    final random = Random.secure();
    final adjective = _adjectives[random.nextInt(_adjectives.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    final number = random.nextInt(100);

    return 'anon-$adjective-$noun-$number';
  }

  /// Generate anonymous user ID
  ///
  /// Creates a cryptographically secure random user ID for tracking
  /// Rally participation without linking to real identity.
  ///
  /// Returns a 32-character hex string (128-bit random ID).
  ///
  /// Example:
  /// ```dart
  /// final userId = AnonymousIdentity.generateUserId();
  /// print(userId); // "a3f2e1d4c5b6a7f8e9d0c1b2a3f4e5d6"
  /// ```
  static String generateUserId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generate deterministic anonymous ID from seed
  ///
  /// Useful for creating consistent anonymous IDs across app restarts
  /// while maintaining privacy. Uses the user's mesh peer ID as seed.
  ///
  /// Example:
  /// ```dart
  /// final userId = AnonymousIdentity.generateFromSeed('user-mesh-id');
  /// print(userId); // Always same ID for same seed
  /// ```
  static String generateFromSeed(String seed) {
    final bytes = utf8.encode(seed);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  /// Validate if a string is a valid anonymous identity format
  ///
  /// Example:
  /// ```dart
  /// print(AnonymousIdentity.isValidFormat('anon-happy-fox-42')); // true
  /// print(AnonymousIdentity.isValidFormat('invalid')); // false
  /// ```
  static bool isValidFormat(String identity) {
    if (!identity.startsWith('anon-')) {
      return false;
    }

    final parts = identity.split('-');
    if (parts.length != 4) {
      return false;
    }

    // Check if last part is a number
    final number = int.tryParse(parts[3]);
    if (number == null || number < 0 || number >= 100) {
      return false;
    }

    // Check if adjective and noun are in our lists
    return _adjectives.contains(parts[1]) && _nouns.contains(parts[2]);
  }

  /// Generate multiple unique anonymous identities
  ///
  /// Useful for testing or generating a pool of identities.
  ///
  /// Example:
  /// ```dart
  /// final identities = AnonymousIdentity.generateMultiple(5);
  /// print(identities); // ['anon-happy-fox-42', 'anon-brave-wolf-17', ...]
  /// ```
  static List<String> generateMultiple(int count) {
    final identities = <String>{};
    while (identities.length < count) {
      identities.add(generate());
    }
    return identities.toList();
  }

  /// Get total possible combinations
  ///
  /// Returns the total number of unique anonymous identities possible.
  ///
  /// Example:
  /// ```dart
  /// print(AnonymousIdentity.totalCombinations); // 102400
  /// ```
  static int get totalCombinations =>
      _adjectives.length * _nouns.length * 100;

  /// Extract adjective from anonymous identity
  ///
  /// Example:
  /// ```dart
  /// final adj = AnonymousIdentity.extractAdjective('anon-happy-fox-42');
  /// print(adj); // 'happy'
  /// ```
  static String? extractAdjective(String identity) {
    if (!isValidFormat(identity)) return null;
    return identity.split('-')[1];
  }

  /// Extract noun from anonymous identity
  ///
  /// Example:
  /// ```dart
  /// final noun = AnonymousIdentity.extractNoun('anon-happy-fox-42');
  /// print(noun); // 'fox'
  /// ```
  static String? extractNoun(String identity) {
    if (!isValidFormat(identity)) return null;
    return identity.split('-')[2];
  }

  /// Extract number from anonymous identity
  ///
  /// Example:
  /// ```dart
  /// final num = AnonymousIdentity.extractNumber('anon-happy-fox-42');
  /// print(num); // 42
  /// ```
  static int? extractNumber(String identity) {
    if (!isValidFormat(identity)) return null;
    return int.tryParse(identity.split('-')[3]);
  }
}
