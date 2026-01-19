import 'package:test/test.dart';
import 'package:meshlink_core/utils/anonymous_identity.dart';

void main() {
  group('AnonymousIdentity generation', () {
    test('generates valid format', () {
      final identity = AnonymousIdentity.generate();

      expect(identity.startsWith('anon-'), isTrue);
      expect(identity.split('-').length, equals(4));
    });

    test('generates different identities', () {
      final identities = <String>{};
      for (var i = 0; i < 100; i++) {
        identities.add(AnonymousIdentity.generate());
      }

      // Should generate at least 90 unique identities out of 100
      expect(identities.length, greaterThan(90));
    });

    test('generates valid parts', () {
      for (var i = 0; i < 50; i++) {
        final identity = AnonymousIdentity.generate();
        final parts = identity.split('-');

        expect(parts[0], equals('anon'));
        expect(parts[1].isNotEmpty, isTrue); // Adjective
        expect(parts[2].isNotEmpty, isTrue); // Noun
        expect(int.tryParse(parts[3]), isNotNull); // Number
        expect(int.parse(parts[3]), inInclusiveRange(0, 99));
      }
    });

    test('number is always two digits or less', () {
      for (var i = 0; i < 50; i++) {
        final identity = AnonymousIdentity.generate();
        final parts = identity.split('-');
        final number = int.parse(parts[3]);

        expect(number, lessThan(100));
        expect(number, greaterThanOrEqualTo(0));
      }
    });
  });

  group('AnonymousIdentity user ID generation', () {
    test('generates 32-character hex string', () {
      final userId = AnonymousIdentity.generateUserId();

      expect(userId.length, equals(32));
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(userId), isTrue);
    });

    test('generates different user IDs', () {
      final userIds = <String>{};
      for (var i = 0; i < 100; i++) {
        userIds.add(AnonymousIdentity.generateUserId());
      }

      // All should be unique
      expect(userIds.length, equals(100));
    });
  });

  group('AnonymousIdentity from seed', () {
    test('generates deterministic ID from seed', () {
      final seed = 'test-seed-123';
      final id1 = AnonymousIdentity.generateFromSeed(seed);
      final id2 = AnonymousIdentity.generateFromSeed(seed);

      expect(id1, equals(id2));
    });

    test('different seeds generate different IDs', () {
      final id1 = AnonymousIdentity.generateFromSeed('seed1');
      final id2 = AnonymousIdentity.generateFromSeed('seed2');

      expect(id1, isNot(equals(id2)));
    });

    test('generates 32-character string', () {
      final id = AnonymousIdentity.generateFromSeed('test');
      expect(id.length, equals(32));
    });
  });

  group('AnonymousIdentity validation', () {
    test('validates correct format', () {
      expect(AnonymousIdentity.isValidFormat('anon-happy-fox-42'), isTrue);
      expect(AnonymousIdentity.isValidFormat('anon-brave-wolf-99'), isTrue);
      expect(AnonymousIdentity.isValidFormat('anon-calm-owl-0'), isTrue);
    });

    test('rejects invalid prefix', () {
      expect(AnonymousIdentity.isValidFormat('user-happy-fox-42'), isFalse);
      expect(AnonymousIdentity.isValidFormat('happy-fox-42'), isFalse);
    });

    test('rejects wrong number of parts', () {
      expect(AnonymousIdentity.isValidFormat('anon-happy-42'), isFalse);
      expect(AnonymousIdentity.isValidFormat('anon-happy-fox'), isFalse);
      expect(AnonymousIdentity.isValidFormat('anon-happy-fox-42-extra'), isFalse);
    });

    test('rejects invalid number', () {
      expect(AnonymousIdentity.isValidFormat('anon-happy-fox-abc'), isFalse);
      expect(AnonymousIdentity.isValidFormat('anon-happy-fox-100'), isFalse);
      expect(AnonymousIdentity.isValidFormat('anon-happy-fox--1'), isFalse);
    });

    test('rejects invalid adjective or noun', () {
      expect(AnonymousIdentity.isValidFormat('anon-invalid-fox-42'), isFalse);
      expect(AnonymousIdentity.isValidFormat('anon-happy-invalid-42'), isFalse);
    });
  });

  group('AnonymousIdentity extraction', () {
    test('extracts adjective correctly', () {
      expect(AnonymousIdentity.extractAdjective('anon-happy-fox-42'), equals('happy'));
      expect(AnonymousIdentity.extractAdjective('anon-brave-wolf-17'), equals('brave'));
    });

    test('extracts noun correctly', () {
      expect(AnonymousIdentity.extractNoun('anon-happy-fox-42'), equals('fox'));
      expect(AnonymousIdentity.extractNoun('anon-brave-wolf-17'), equals('wolf'));
    });

    test('extracts number correctly', () {
      expect(AnonymousIdentity.extractNumber('anon-happy-fox-42'), equals(42));
      expect(AnonymousIdentity.extractNumber('anon-brave-wolf-0'), equals(0));
      expect(AnonymousIdentity.extractNumber('anon-calm-owl-99'), equals(99));
    });

    test('returns null for invalid format', () {
      expect(AnonymousIdentity.extractAdjective('invalid'), isNull);
      expect(AnonymousIdentity.extractNoun('invalid'), isNull);
      expect(AnonymousIdentity.extractNumber('invalid'), isNull);
    });
  });

  group('AnonymousIdentity multiple generation', () {
    test('generates requested number of identities', () {
      final identities = AnonymousIdentity.generateMultiple(10);
      expect(identities.length, equals(10));
    });

    test('all generated identities are unique', () {
      final identities = AnonymousIdentity.generateMultiple(50);
      final uniqueSet = identities.toSet();

      expect(uniqueSet.length, equals(identities.length));
    });

    test('all generated identities are valid', () {
      final identities = AnonymousIdentity.generateMultiple(20);

      for (final identity in identities) {
        expect(AnonymousIdentity.isValidFormat(identity), isTrue);
      }
    });
  });

  group('AnonymousIdentity total combinations', () {
    test('returns correct total combinations', () {
      final total = AnonymousIdentity.totalCombinations;

      // 32 adjectives * 32 nouns * 100 numbers = 102,400
      expect(total, equals(102400));
    });

    test('total is greater than zero', () {
      expect(AnonymousIdentity.totalCombinations, greaterThan(0));
    });
  });

  group('Integration tests', () {
    test('generated identities are always valid', () {
      for (var i = 0; i < 100; i++) {
        final identity = AnonymousIdentity.generate();
        expect(AnonymousIdentity.isValidFormat(identity), isTrue);
      }
    });

    test('can extract parts from generated identity', () {
      for (var i = 0; i < 50; i++) {
        final identity = AnonymousIdentity.generate();

        final adjective = AnonymousIdentity.extractAdjective(identity);
        final noun = AnonymousIdentity.extractNoun(identity);
        final number = AnonymousIdentity.extractNumber(identity);

        expect(adjective, isNotNull);
        expect(noun, isNotNull);
        expect(number, isNotNull);
        expect(number, inInclusiveRange(0, 99));
      }
    });

    test('identity format follows specification', () {
      final identity = AnonymousIdentity.generate();
      final parts = identity.split('-');

      // Verify format: anon-[adjective]-[noun]-[number]
      expect(parts.length, equals(4));
      expect(parts[0], equals('anon'));
      expect(parts[1], matches(RegExp(r'^[a-z]+$'))); // lowercase letters only
      expect(parts[2], matches(RegExp(r'^[a-z]+$'))); // lowercase letters only
      expect(parts[3], matches(RegExp(r'^\d{1,2}$'))); // 1-2 digits
    });
  });
}
