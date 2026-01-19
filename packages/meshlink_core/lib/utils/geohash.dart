/// Geohash encoding/decoding for location-based channel IDs
///
/// Geohash provides a way to encode geographic coordinates (latitude/longitude)
/// into a short string of letters and digits. Each character in the geohash
/// represents a subdivision of space.
///
/// Precision levels:
/// - 1 char = ±2500 km
/// - 2 char = ±630 km
/// - 3 char = ±78 km
/// - 4 char = ±20 km
/// - 5 char = ±2.4 km
/// - 6 char = ±610 m (~1.2km x 0.6km) <- We use this for Rally channels
/// - 7 char = ±76 m
/// - 8 char = ±19 m
library;

class Geohash {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const _base32Map = {
    '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7,
    '8': 8, '9': 9, 'b': 10, 'c': 11, 'd': 12, 'e': 13, 'f': 14, 'g': 15,
    'h': 16, 'j': 17, 'k': 18, 'm': 19, 'n': 20, 'p': 21, 'q': 22, 'r': 23,
    's': 24, 't': 25, 'u': 26, 'v': 27, 'w': 28, 'x': 29, 'y': 30, 'z': 31,
  };

  /// Encode latitude/longitude to geohash
  ///
  /// [latitude] must be in range [-90, 90]
  /// [longitude] must be in range [-180, 180]
  /// [precision] is the number of characters (1-12, default 6)
  ///
  /// Example:
  /// ```dart
  /// final hash = Geohash.encode(37.7749, -122.4194, precision: 6);
  /// print(hash); // "9q8yy9"
  /// ```
  static String encode(
    double latitude,
    double longitude, {
    int precision = 6,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be in range [-90, 90]');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be in range [-180, 180]');
    }
    if (precision < 1 || precision > 12) {
      throw ArgumentError('Precision must be in range [1, 12]');
    }

    var minLat = -90.0;
    var maxLat = 90.0;
    var minLon = -180.0;
    var maxLon = 180.0;

    var geohash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (geohash.length < precision) {
      if (isEven) {
        // Longitude
        final mid = (minLon + maxLon) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          minLon = mid;
        } else {
          maxLon = mid;
        }
      } else {
        // Latitude
        final mid = (minLat + maxLat) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isEven = !isEven;
      bit++;

      if (bit == 5) {
        geohash += _base32[ch];
        bit = 0;
        ch = 0;
      }
    }

    return geohash;
  }

  /// Decode geohash to bounding box
  ///
  /// Returns a record with minimum and maximum latitude/longitude values
  /// that define the bounding box for the geohash.
  ///
  /// Example:
  /// ```dart
  /// final bounds = Geohash.decode('9q8yy9');
  /// print('Lat: ${bounds.minLat} to ${bounds.maxLat}');
  /// print('Lon: ${bounds.minLon} to ${bounds.maxLon}');
  /// ```
  static ({
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  }) decode(String geohash) {
    if (geohash.isEmpty) {
      throw ArgumentError('Geohash cannot be empty');
    }

    var minLat = -90.0;
    var maxLat = 90.0;
    var minLon = -180.0;
    var maxLon = 180.0;

    var isEven = true;

    for (var i = 0; i < geohash.length; i++) {
      final char = geohash[i].toLowerCase();
      final cd = _base32Map[char];
      if (cd == null) {
        throw ArgumentError('Invalid geohash character: $char');
      }

      for (var mask = 16; mask > 0; mask >>= 1) {
        if (isEven) {
          // Longitude
          final mid = (minLon + maxLon) / 2;
          if ((cd & mask) != 0) {
            minLon = mid;
          } else {
            maxLon = mid;
          }
        } else {
          // Latitude
          final mid = (minLat + maxLat) / 2;
          if ((cd & mask) != 0) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        isEven = !isEven;
      }
    }

    return (minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon);
  }

  /// Get center point of a geohash
  ///
  /// Returns the latitude and longitude of the center of the geohash box.
  ///
  /// Example:
  /// ```dart
  /// final center = Geohash.decodeCenter('9q8yy9');
  /// print('Center: ${center.latitude}, ${center.longitude}');
  /// ```
  static ({double latitude, double longitude}) decodeCenter(String geohash) {
    final bounds = decode(geohash);
    return (
      latitude: (bounds.minLat + bounds.maxLat) / 2,
      longitude: (bounds.minLon + bounds.maxLon) / 2,
    );
  }

  /// Get 8 neighboring geohashes
  ///
  /// Returns a list of 8 geohashes that are neighbors to the input geohash.
  /// Order: [N, NE, E, SE, S, SW, W, NW]
  ///
  /// Example:
  /// ```dart
  /// final neighbors = Geohash.neighbors('9q8yy9');
  /// print(neighbors); // ['9q8yyc', '9q8yyd', ...]
  /// ```
  static List<String> neighbors(String geohash) {
    if (geohash.isEmpty) {
      throw ArgumentError('Geohash cannot be empty');
    }

    return [
      _neighbor(geohash, 'top'),
      _neighbor(_neighbor(geohash, 'top'), 'right'),
      _neighbor(geohash, 'right'),
      _neighbor(_neighbor(geohash, 'bottom'), 'right'),
      _neighbor(geohash, 'bottom'),
      _neighbor(_neighbor(geohash, 'bottom'), 'left'),
      _neighbor(geohash, 'left'),
      _neighbor(_neighbor(geohash, 'top'), 'left'),
    ];
  }

  /// Generate Rally channel ID from location + time bucket
  ///
  /// Creates a deterministic channel ID based on:
  /// - Geohash (precision 6 = ~1.2km area)
  /// - Time bucket (4-hour intervals)
  ///
  /// This ensures:
  /// - Same location at same time = same channel
  /// - Channels expire every 4 hours (new IDs generated)
  ///
  /// Example:
  /// ```dart
  /// final channelId = Geohash.generateChannelId(37.7749, -122.4194);
  /// print(channelId); // "9q8yy9_123456"
  /// ```
  static String generateChannelId(double latitude, double longitude) {
    final geohash = encode(latitude, longitude, precision: 6);
    final now = DateTime.now();
    // 4-hour time buckets (6 buckets per day)
    final timeBucket = now.millisecondsSinceEpoch ~/ (4 * 3600000);
    return '${geohash}_$timeBucket';
  }

  // Neighbor lookup tables
  static const _neighborMap = {
    'top': {
      'even': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
      'odd': 'bc01fg45238967deuvhjyznpkmstqrwx',
    },
    'bottom': {
      'even': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
      'odd': '238967debc01fg45kmstqrwxuvhjyznp',
    },
    'right': {
      'even': 'bc01fg45238967deuvhjyznpkmstqrwx',
      'odd': 'p0r21436x8zb9dcf5h7kjnmqesgutwvy',
    },
    'left': {
      'even': '238967debc01fg45kmstqrwxuvhjyznp',
      'odd': '14365h7k9dcfesgujnmqp0r2twvyx8zb',
    },
  };

  static const _borderMap = {
    'top': {
      'even': 'prxz',
      'odd': 'bcfguvyz',
    },
    'bottom': {
      'even': '028b',
      'odd': '0145hjnp',
    },
    'right': {
      'even': 'bcfguvyz',
      'odd': 'prxz',
    },
    'left': {
      'even': '0145hjnp',
      'odd': '028b',
    },
  };

  static String _neighbor(String geohash, String direction) {
    if (geohash.isEmpty) {
      throw ArgumentError('Geohash cannot be empty');
    }

    final lastChar = geohash[geohash.length - 1].toLowerCase();
    var parent = geohash.substring(0, geohash.length - 1);
    final type = geohash.length % 2 == 0 ? 'even' : 'odd';

    // Check if we're at a border
    if (_borderMap[direction]![type]!.contains(lastChar)) {
      parent = _neighbor(parent, direction);
    }

    // Replace the last character
    final neighborIndex = _neighborMap[direction]![type]!.indexOf(lastChar);
    return parent + _base32[neighborIndex];
  }

  /// Validate if a string is a valid geohash
  ///
  /// Example:
  /// ```dart
  /// print(Geohash.isValid('9q8yy9')); // true
  /// print(Geohash.isValid('invalid')); // false (contains 'i')
  /// ```
  static bool isValid(String geohash) {
    if (geohash.isEmpty || geohash.length > 12) {
      return false;
    }

    for (var i = 0; i < geohash.length; i++) {
      if (!_base32Map.containsKey(geohash[i].toLowerCase())) {
        return false;
      }
    }

    return true;
  }

  /// Calculate approximate bounding box dimensions in meters
  ///
  /// Returns approximate width and height of the geohash bounding box.
  /// Note: These are approximations as the actual size varies by latitude.
  ///
  /// Example:
  /// ```dart
  /// final dims = Geohash.dimensions('9q8yy9');
  /// print('Width: ${dims.width}m, Height: ${dims.height}m');
  /// ```
  static ({double width, double height}) dimensions(String geohash) {
    final bounds = decode(geohash);

    // Approximate meters per degree of latitude (constant)
    const metersPerDegreeLat = 111320.0;

    // Meters per degree of longitude varies by latitude
    final avgLat = (bounds.minLat + bounds.maxLat) / 2;
    final metersPerDegreeLon = 111320.0 * _cos(avgLat * 3.14159265359 / 180);

    final width = (bounds.maxLon - bounds.minLon) * metersPerDegreeLon;
    final height = (bounds.maxLat - bounds.minLat) * metersPerDegreeLat;

    return (width: width, height: height);
  }

  // Simple cosine approximation (avoid dart:math dependency)
  static double _cos(double x) {
    // Taylor series approximation for cos(x)
    // cos(x) ≈ 1 - x²/2! + x⁴/4! - x⁶/6!
    final x2 = x * x;
    final x4 = x2 * x2;
    final x6 = x4 * x2;
    return 1 - (x2 / 2) + (x4 / 24) - (x6 / 720);
  }
}
