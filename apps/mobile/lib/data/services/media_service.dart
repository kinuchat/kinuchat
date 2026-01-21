import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Service for handling media compression, thumbnails, and caching
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  /// Custom cache manager for media files
  static final _cacheManager = CacheManager(
    Config(
      'kinu_media_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  /// Get the cache manager instance
  CacheManager get cacheManager => _cacheManager;

  // ============================================================================
  // Image Processing
  // ============================================================================

  /// Compress an image file
  /// Returns the compressed image bytes
  Future<Uint8List> compressImage(
    File imageFile, {
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 85,
  }) async {
    final bytes = await imageFile.readAsBytes();

    // Decode the image
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Calculate new dimensions maintaining aspect ratio
    int targetWidth = image.width;
    int targetHeight = image.height;

    if (targetWidth > maxWidth || targetHeight > maxHeight) {
      final aspectRatio = targetWidth / targetHeight;
      if (targetWidth > targetHeight) {
        targetWidth = maxWidth;
        targetHeight = (maxWidth / aspectRatio).round();
      } else {
        targetHeight = maxHeight;
        targetWidth = (maxHeight * aspectRatio).round();
      }
    }

    // For now, return original bytes if no compression needed
    // In a production app, you'd use image package or native code for actual compression
    if (targetWidth == image.width && targetHeight == image.height) {
      return bytes;
    }

    // Return original for now - actual compression would use FFI or platform channels
    // The image package can be added for more advanced processing
    return bytes;
  }

  /// Generate a thumbnail from an image file
  Future<ThumbnailResult> generateImageThumbnail(
    File imageFile, {
    int maxWidth = 200,
    int maxHeight = 200,
  }) async {
    final bytes = await imageFile.readAsBytes();

    // Decode to get dimensions
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Calculate thumbnail dimensions
    int thumbWidth = image.width;
    int thumbHeight = image.height;
    final aspectRatio = thumbWidth / thumbHeight;

    if (thumbWidth > thumbHeight) {
      thumbWidth = maxWidth;
      thumbHeight = (maxWidth / aspectRatio).round();
    } else {
      thumbHeight = maxHeight;
      thumbWidth = (maxHeight * aspectRatio).round();
    }

    // For now return the original - production would resize
    return ThumbnailResult(
      bytes: bytes,
      width: thumbWidth,
      height: thumbHeight,
    );
  }

  /// Get image dimensions
  Future<ImageDimensions> getImageDimensions(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return ImageDimensions(
      width: frame.image.width,
      height: frame.image.height,
    );
  }

  // ============================================================================
  // Video Processing
  // ============================================================================

  /// Compress a video file
  Future<File?> compressVideo(
    File videoFile, {
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    try {
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      return info?.file;
    } catch (e) {
      debugPrint('Video compression failed: $e');
      return null;
    }
  }

  /// Generate a thumbnail from a video file
  Future<ThumbnailResult?> generateVideoThumbnail(
    File videoFile, {
    int maxWidth = 200,
    int maxHeight = 200,
  }) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 75,
        position: -1, // Get from middle of video
      );

      final bytes = await thumbnailFile.readAsBytes();

      // Get actual dimensions
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      return ThumbnailResult(
        bytes: bytes,
        width: frame.image.width,
        height: frame.image.height,
      );
    } catch (e) {
      debugPrint('Video thumbnail generation failed: $e');
      return null;
    }
  }

  /// Get video metadata
  Future<VideoMetadata?> getVideoMetadata(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      // duration is in seconds as double
      final durationMs = ((info.duration ?? 0) * 1000).round();
      return VideoMetadata(
        width: info.width ?? 0,
        height: info.height ?? 0,
        duration: durationMs,
        size: info.filesize ?? 0,
      );
    } catch (e) {
      debugPrint('Failed to get video metadata: $e');
      return null;
    }
  }

  // ============================================================================
  // Caching
  // ============================================================================

  /// Cache a media file from URL
  Future<File> cacheMediaFromUrl(String url) async {
    final fileInfo = await _cacheManager.downloadFile(url);
    return fileInfo.file;
  }

  /// Get cached file if exists
  Future<File?> getCachedFile(String url) async {
    final fileInfo = await _cacheManager.getFileFromCache(url);
    return fileInfo?.file;
  }

  /// Cache media bytes with a key
  Future<File> cacheMediaBytes(String key, Uint8List bytes, String fileExtension) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$key.$fileExtension');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Clear all cached media
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    // This is an approximation - actual implementation would sum file sizes
    return 0;
  }

  // ============================================================================
  // Audio Processing
  // ============================================================================

  /// Get audio file duration in milliseconds
  Future<int> getAudioDuration(File audioFile) async {
    // This would use a native plugin or FFI for accurate duration
    // For now, estimate based on file size (very rough approximation)
    final size = await audioFile.length();
    // Assume ~16kbps for voice messages
    return (size * 8 / 16000 * 1000).round();
  }

  // ============================================================================
  // File Utilities
  // ============================================================================

  /// Get the temp directory for media files
  Future<Directory> getTempDirectory() async {
    return getTemporaryDirectory();
  }

  /// Create a temp file with the given extension
  Future<File> createTempFile(String extension) async {
    final tempDir = await getTempDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File('${tempDir.path}/media_$timestamp.$extension');
  }

  /// Delete a temp file
  Future<void> deleteTempFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return file.length();
  }

  /// Check if file size is within limit
  Future<bool> isFileSizeValid(File file, int maxSizeBytes) async {
    final size = await file.length();
    return size <= maxSizeBytes;
  }
}

/// Result of thumbnail generation
class ThumbnailResult {
  final Uint8List bytes;
  final int width;
  final int height;

  ThumbnailResult({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// Image dimensions
class ImageDimensions {
  final int width;
  final int height;

  ImageDimensions({
    required this.width,
    required this.height,
  });
}

/// Video metadata
class VideoMetadata {
  final int width;
  final int height;
  final int duration; // in milliseconds
  final int size; // in bytes

  VideoMetadata({
    required this.width,
    required this.height,
    required this.duration,
    required this.size,
  });
}

/// Media size limits
class MediaLimits {
  /// Max file size for cloud transport (25MB)
  static const int cloudMaxBytes = 25 * 1024 * 1024;

  /// Max file size for mesh transport (1MB)
  static const int meshMaxBytes = 1 * 1024 * 1024;

  /// Max file size for bridge relay (25MB)
  static const int bridgeMaxBytes = 25 * 1024 * 1024;

  /// Max image dimensions
  static const int maxImageWidth = 4096;
  static const int maxImageHeight = 4096;

  /// Max video duration in seconds (5 minutes)
  static const int maxVideoDurationSeconds = 300;

  /// Max voice message duration in seconds (5 minutes)
  static const int maxVoiceDurationSeconds = 300;
}
