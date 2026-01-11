import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'cache_policy.dart';

/// Service for compressing and decompressing cached data
class CompressionService {
  static final CompressionService _instance = CompressionService._internal();
  factory CompressionService() => _instance;
  CompressionService._internal();

  /// Compress data based on configuration
  Future<Uint8List> compress(
    dynamic data, {
    CompressionConfig config = const CompressionConfig(enabled: true),
  }) async {
    if (!config.enabled) {
      return _dataToBytes(data);
    }

    final bytes = _dataToBytes(data);

    // Only compress if data is above threshold
    if (bytes.length < config.threshold) {
      return bytes;
    }

    try {
      switch (config.algorithm) {
        case CompressionAlgorithm.gzip:
          return await _compressGzip(bytes, config.level);
        case CompressionAlgorithm.deflate:
          return await _compressDeflate(bytes, config.level);
        case CompressionAlgorithm.brotli:
          // Brotli not available in Dart standard library
          // Fall back to gzip
          return await _compressGzip(bytes, config.level);
      }
    } catch (e) {
      debugPrint('Compression failed: $e');
      return bytes; // Return uncompressed data on failure
    }
  }

  /// Decompress data
  Future<dynamic> decompress(
    Uint8List compressedData, {
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
    Type? expectedType,
  }) async {
    try {
      Uint8List decompressed;

      switch (algorithm) {
        case CompressionAlgorithm.gzip:
          decompressed = await _decompressGzip(compressedData);
          break;
        case CompressionAlgorithm.deflate:
          decompressed = await _decompressDeflate(compressedData);
          break;
        case CompressionAlgorithm.brotli:
          // Fall back to gzip
          decompressed = await _decompressGzip(compressedData);
          break;
      }

      return _bytesToData(decompressed, expectedType);
    } catch (e) {
      debugPrint('Decompression failed: $e');
      // Try to return as uncompressed data
      return _bytesToData(compressedData, expectedType);
    }
  }

  /// Check if data should be compressed
  bool shouldCompress(dynamic data, CompressionConfig config) {
    if (!config.enabled) return false;

    final bytes = _dataToBytes(data);
    return bytes.length >= config.threshold;
  }

  /// Estimate compression ratio for given data
  Future<double> estimateCompressionRatio(
    dynamic data, {
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
  }) async {
    final originalBytes = _dataToBytes(data);
    if (originalBytes.isEmpty) return 1.0;

    try {
      final compressed = await compress(
        data,
        config: CompressionConfig(
          enabled: true,
          algorithm: algorithm,
          threshold: 0, // Compress regardless of size for estimation
        ),
      );

      return compressed.length / originalBytes.length;
    } catch (e) {
      return 1.0; // No compression benefit
    }
  }

  /// Get compression statistics for monitoring
  Future<CompressionStats> getStats(List<dynamic> dataItems) async {
    int totalOriginalSize = 0;
    int totalCompressedSize = 0;
    int compressibleItems = 0;

    for (final item in dataItems) {
      final originalBytes = _dataToBytes(item);
      totalOriginalSize += originalBytes.length;

      if (originalBytes.length >= 1024) {
        // 1KB threshold
        try {
          final compressed = await compress(item);
          totalCompressedSize += compressed.length;
          compressibleItems++;
        } catch (e) {
          totalCompressedSize += originalBytes.length;
        }
      } else {
        totalCompressedSize += originalBytes.length;
      }
    }

    return CompressionStats(
      totalItems: dataItems.length,
      compressibleItems: compressibleItems,
      originalSizeBytes: totalOriginalSize,
      compressedSizeBytes: totalCompressedSize,
      compressionRatio: totalOriginalSize > 0
          ? totalCompressedSize / totalOriginalSize
          : 1.0,
      spaceSavedBytes: totalOriginalSize - totalCompressedSize,
    );
  }

  // Private methods

  Uint8List _dataToBytes(dynamic data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);

    // Convert to JSON string first
    String jsonString;
    if (data is String) {
      jsonString = data;
    } else {
      jsonString = json.encode(data);
    }

    return Uint8List.fromList(utf8.encode(jsonString));
  }

  dynamic _bytesToData(Uint8List bytes, Type? expectedType) {
    final string = utf8.decode(bytes);

    // Try to parse as JSON
    try {
      return json.decode(string);
    } catch (e) {
      // Return as string if JSON parsing fails
      return string;
    }
  }

  Future<Uint8List> _compressGzip(Uint8List data, int level) async {
    return await compute(_compressGzipIsolate, {'data': data, 'level': level});
  }

  Future<Uint8List> _decompressGzip(Uint8List data) async {
    return await compute(_decompressGzipIsolate, data);
  }

  Future<Uint8List> _compressDeflate(Uint8List data, int level) async {
    return await compute(_compressDeflateIsolate, {
      'data': data,
      'level': level,
    });
  }

  Future<Uint8List> _decompressDeflate(Uint8List data) async {
    return await compute(_decompressDeflateIsolate, data);
  }

  // Static methods for isolate execution

  static Uint8List _compressGzipIsolate(Map<String, dynamic> params) {
    final data = params['data'] as Uint8List;
    final level = params['level'] as int;

    final codec = GZipCodec(level: level);
    return Uint8List.fromList(codec.encode(data));
  }

  static Uint8List _decompressGzipIsolate(Uint8List data) {
    final codec = GZipCodec();
    return Uint8List.fromList(codec.decode(data));
  }

  static Uint8List _compressDeflateIsolate(Map<String, dynamic> params) {
    final data = params['data'] as Uint8List;
    final level = params['level'] as int;

    final codec = ZLibCodec(level: level);
    return Uint8List.fromList(codec.encode(data));
  }

  static Uint8List _decompressDeflateIsolate(Uint8List data) {
    final codec = ZLibCodec();
    return Uint8List.fromList(codec.decode(data));
  }
}

/// Compression statistics
class CompressionStats {
  final int totalItems;
  final int compressibleItems;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final double compressionRatio;
  final int spaceSavedBytes;

  CompressionStats({
    required this.totalItems,
    required this.compressibleItems,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.compressionRatio,
    required this.spaceSavedBytes,
  });

  double get spaceSavedPercentage =>
      originalSizeBytes > 0 ? (spaceSavedBytes / originalSizeBytes) * 100 : 0.0;

  String get formattedOriginalSize => _formatBytes(originalSizeBytes);
  String get formattedCompressedSize => _formatBytes(compressedSizeBytes);
  String get formattedSpaceSaved => _formatBytes(spaceSavedBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'compressible_items': compressibleItems,
      'original_size_bytes': originalSizeBytes,
      'compressed_size_bytes': compressedSizeBytes,
      'compression_ratio': compressionRatio,
      'space_saved_bytes': spaceSavedBytes,
      'space_saved_percentage': spaceSavedPercentage,
    };
  }
}

/// Adaptive compression that chooses the best algorithm
class AdaptiveCompression {
  static final Map<String, CompressionAlgorithm> _bestAlgorithms = {};

  /// Find the best compression algorithm for a data type
  static Future<CompressionAlgorithm> findBestAlgorithm(
    dynamic sampleData,
    String dataType,
  ) async {
    // Check if we already know the best algorithm for this data type
    if (_bestAlgorithms.containsKey(dataType)) {
      return _bestAlgorithms[dataType]!;
    }

    final compressionService = CompressionService();
    final algorithms = [
      CompressionAlgorithm.gzip,
      CompressionAlgorithm.deflate,
    ];

    CompressionAlgorithm bestAlgorithm = CompressionAlgorithm.gzip;
    double bestRatio = 1.0;

    for (final algorithm in algorithms) {
      try {
        final ratio = await compressionService.estimateCompressionRatio(
          sampleData,
          algorithm: algorithm,
        );

        if (ratio < bestRatio) {
          bestRatio = ratio;
          bestAlgorithm = algorithm;
        }
      } catch (e) {
        // Skip algorithm if it fails
        continue;
      }
    }

    _bestAlgorithms[dataType] = bestAlgorithm;
    return bestAlgorithm;
  }

  /// Clear cached algorithm preferences
  static void clearCache() {
    _bestAlgorithms.clear();
  }
}

