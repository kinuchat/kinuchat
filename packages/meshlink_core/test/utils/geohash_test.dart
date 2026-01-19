import 'package:test/test.dart';
import 'package:meshlink_core/utils/geohash.dart';

void main() {
  group('Geohash encoding', () {
    test('encodes San Francisco coordinates correctly', () {
      final hash = Geohash.encode(37.7749, -122.4194, precision: 6);
      expect(hash.length, equals(6));
      expect(hash.startsWith('9q8'), isTrue); // Correct general area
    });

    test('encodes London coordinates correctly', () {
      final hash = Geohash.encode(51.5074, -0.1278, precision: 6);
      expect(hash.length, equals(6));
      expect(hash.startsWith('gcp'), isTrue); // Correct general area
    });

    test('encodes Tokyo coordinates correctly', () {
      final hash = Geohash.encode(35.6762, 139.6503, precision: 6);
      expect(hash.length, equals(6));
      expect(hash.startsWith('xn'), isTrue); // Correct general area
    });

    test('encodes with different precision levels', () {
      final lat = 37.7749;
      final lon = -122.4194;

      expect(Geohash.encode(lat, lon, precision: 1).length, equals(1));
      expect(Geohash.encode(lat, lon, precision: 3).length, equals(3));
      expect(Geohash.encode(lat, lon, precision: 6).length, equals(6));
      expect(Geohash.encode(lat, lon, precision: 9).length, equals(9));
    });

    test('handles edge cases at equator', () {
      final hash = Geohash.encode(0, 0, precision: 6);
      expect(hash.length, equals(6));
      expect(Geohash.isValid(hash), isTrue);
    });

    test('handles edge cases at poles', () {
      final northPole = Geohash.encode(89.9, 0, precision: 6);
      final southPole = Geohash.encode(-89.9, 0, precision: 6);

      expect(northPole.length, equals(6));
      expect(southPole.length, equals(6));
    });

    test('handles edge cases at date line', () {
      final east = Geohash.encode(0, 179.9, precision: 6);
      final west = Geohash.encode(0, -179.9, precision: 6);

      expect(east.length, equals(6));
      expect(west.length, equals(6));
    });

    test('throws on invalid latitude', () {
      expect(() => Geohash.encode(91, 0), throwsArgumentError);
      expect(() => Geohash.encode(-91, 0), throwsArgumentError);
    });

    test('throws on invalid longitude', () {
      expect(() => Geohash.encode(0, 181), throwsArgumentError);
      expect(() => Geohash.encode(0, -181), throwsArgumentError);
    });

    test('throws on invalid precision', () {
      expect(() => Geohash.encode(0, 0, precision: 0), throwsArgumentError);
      expect(() => Geohash.encode(0, 0, precision: 13), throwsArgumentError);
    });
  });

  group('Geohash decoding', () {
    test('decodes to bounding box correctly', () {
      final bounds = Geohash.decode('9q8yyk');

      // Bounding box should be in San Francisco area
      expect(bounds.minLat, greaterThan(37.7));
      expect(bounds.maxLat, lessThan(37.8));
      expect(bounds.minLon, greaterThan(-122.5));
      expect(bounds.maxLon, lessThan(-122.4));
    });

    test('decodes center point correctly', () {
      final center = Geohash.decodeCenter('9q8yyk');

      // Center should be in San Francisco area
      expect(center.latitude, closeTo(37.775, 0.03));
      expect(center.longitude, closeTo(-122.42, 0.03));
    });

    test('roundtrip encoding and decoding', () {
      final lat = 37.7749;
      final lon = -122.4194;
      final hash = Geohash.encode(lat, lon, precision: 6);
      final center = Geohash.decodeCenter(hash);

      // Should be within the geohash cell (~1.2km for precision 6)
      expect((center.latitude - lat).abs(), lessThan(0.01));
      expect((center.longitude - lon).abs(), lessThan(0.01));
    });

    test('throws on empty geohash', () {
      expect(() => Geohash.decode(''), throwsArgumentError);
    });

    test('throws on invalid characters', () {
      expect(() => Geohash.decode('invalid!'), throwsArgumentError);
    });
  });

  group('Geohash neighbors', () {
    test('returns 8 neighbors', () {
      final neighbors = Geohash.neighbors('9q8yy9');
      expect(neighbors.length, equals(8));
    });

    test('neighbors have same length as input', () {
      final hash = '9q8yy9';
      final neighbors = Geohash.neighbors(hash);

      for (final neighbor in neighbors) {
        expect(neighbor.length, equals(hash.length));
      }
    });

    test('neighbors are all valid geohashes', () {
      final neighbors = Geohash.neighbors('9q8yy9');

      for (final neighbor in neighbors) {
        expect(Geohash.isValid(neighbor), isTrue);
      }
    });

    test('neighbors are adjacent cells', () {
      final center = Geohash.decodeCenter('9q8yy9');
      final neighbors = Geohash.neighbors('9q8yy9');

      for (final neighbor in neighbors) {
        final neighborCenter = Geohash.decodeCenter(neighbor);

        // Neighbors should be close (within ~3km for precision 6)
        final latDiff = (neighborCenter.latitude - center.latitude).abs();
        final lonDiff = (neighborCenter.longitude - center.longitude).abs();

        expect(latDiff, lessThan(0.03));
        expect(lonDiff, lessThan(0.03));
      }
    });

    test('throws on empty geohash', () {
      expect(() => Geohash.neighbors(''), throwsArgumentError);
    });
  });

  group('Channel ID generation', () {
    test('generates deterministic IDs for same location', () {
      final id1 = Geohash.generateChannelId(37.7749, -122.4194);
      final id2 = Geohash.generateChannelId(37.7749, -122.4194);

      // Within same time bucket, IDs should match
      expect(id1, equals(id2));
    });

    test('includes geohash and time bucket', () {
      final id = Geohash.generateChannelId(37.7749, -122.4194);

      expect(id.contains('_'), isTrue);
      final parts = id.split('_');
      expect(parts.length, equals(2));

      // First part is geohash
      expect(parts[0].length, equals(6));
      expect(Geohash.isValid(parts[0]), isTrue);

      // Second part is time bucket (number)
      expect(int.tryParse(parts[1]), isNotNull);
    });

    test('different locations generate different IDs', () {
      final sf = Geohash.generateChannelId(37.7749, -122.4194);
      final london = Geohash.generateChannelId(51.5074, -0.1278);

      expect(sf, isNot(equals(london)));
    });
  });

  group('Geohash validation', () {
    test('validates correct geohashes', () {
      expect(Geohash.isValid('9q8yy9'), isTrue);
      expect(Geohash.isValid('gcpvj0'), isTrue);
      expect(Geohash.isValid('u4pruydqqvj'), isTrue);
    });

    test('rejects empty string', () {
      expect(Geohash.isValid(''), isFalse);
    });

    test('rejects too long geohash', () {
      expect(Geohash.isValid('9q8yy9abc123456'), isFalse);
    });

    test('rejects invalid characters', () {
      expect(Geohash.isValid('invalid!'), isFalse);
      expect(Geohash.isValid('9q8yy@'), isFalse);
      expect(Geohash.isValid('ABCDEF'), isFalse); // Base32 doesn't use uppercase A,I,L,O
    });

    test('accepts case insensitive input', () {
      expect(Geohash.isValid('9Q8YY9'), isTrue);
    });
  });

  group('Geohash dimensions', () {
    test('calculates approximate dimensions', () {
      final dims = Geohash.dimensions('9q8yy9');

      // Precision 6 should be ~1.2km x 0.6km
      expect(dims.width, greaterThan(500));
      expect(dims.width, lessThan(2000));
      expect(dims.height, greaterThan(500));
      expect(dims.height, lessThan(2000));
    });

    test('shorter geohash has larger dimensions', () {
      final dims3 = Geohash.dimensions('9q8');
      final dims6 = Geohash.dimensions('9q8yy9');

      expect(dims3.width, greaterThan(dims6.width));
      expect(dims3.height, greaterThan(dims6.height));
    });
  });

  group('Integration tests', () {
    test('encode/decode preserves approximate location', () {
      final testCases = [
        {'lat': 37.7749, 'lon': -122.4194}, // San Francisco
        {'lat': 51.5074, 'lon': -0.1278},   // London
        {'lat': 35.6762, 'lon': 139.6503},  // Tokyo
        {'lat': -33.8688, 'lon': 151.2093}, // Sydney
        {'lat': 0.0, 'lon': 0.0},           // Null Island
      ];

      for (final testCase in testCases) {
        final lat = testCase['lat']!;
        final lon = testCase['lon']!;

        final hash = Geohash.encode(lat, lon, precision: 6);
        final center = Geohash.decodeCenter(hash);

        // Within ~1km for precision 6
        expect((center.latitude - lat).abs(), lessThan(0.01));
        expect((center.longitude - lon).abs(), lessThan(0.01));
      }
    });

    test('neighboring cells cover area around point', () {
      final lat = 37.7749;
      final lon = -122.4194;

      final centerHash = Geohash.encode(lat, lon, precision: 6);
      final neighbors = Geohash.neighbors(centerHash);

      // Point should be within center cell or one of its neighbors
      final allHashes = [centerHash, ...neighbors];

      // Try encoding with slightly offset coordinates
      final nearbyHash = Geohash.encode(lat + 0.005, lon + 0.005, precision: 6);

      expect(allHashes.contains(nearbyHash), isTrue);
    });
  });
}
