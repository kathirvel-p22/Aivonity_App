import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_manager.dart';

/// Service for optimizing image loading and caching
class ImageOptimizationService {
  static const String _imageMetadataPrefix = 'img_meta_';
  static const int _maxImageCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration _imageCacheTtl = Duration(days: 7);

  late final AdvancedCacheManager _cacheManager;
  SharedPreferences? _prefs;

  final Map<String, Completer<ui.Image>> _loadingImages = {};
  final Map<String, ImageMetadata> _imageMetadata = {};

  /// Initialize the image optimization service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheManager = AdvancedCacheManager();
    await _cacheManager.initialize();
    _cacheManager.setMaxCacheSize(_maxImageCacheSize);

    await _loadImageMetadata();

    print('🖼️ Image optimization service initialized');
  }

  /// Load and optimize image with caching
  Future<ui.Image> loadOptimizedImage(
    String imageUrl, {
    int? targetWidth,
    int? targetHeight,
    ImageQuality quality = ImageQuality.medium,
    bool useCache = true,
  }) async {
    final cacheKey = _generateImageCacheKey(
      imageUrl,
      targetWidth,
      targetHeight,
      quality,
    );

    // Check if already loading
    if (_loadingImages.containsKey(cacheKey)) {
      return await _loadingImages[cacheKey]!.future;
    }

    // Check cache first
    if (useCache) {
      final cachedImage = await _getCachedImage(cacheKey);
      if (cachedImage != null) {
        return cachedImage;
      }
    }

    // Start loading
    final completer = Completer<ui.Image>();
    _loadingImages[cacheKey] = completer;

    try {
      final image = await _loadAndProcessImage(
        imageUrl,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        quality: quality,
      );

      // Cache the processed image
      if (useCache) {
        await _cacheImage(cacheKey, image, imageUrl);
      }

      completer.complete(image);
      return image;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _loadingImages.remove(cacheKey);
    }
  }

  /// Create optimized image widget with lazy loading
  Widget createOptimizedImageWidget(
    String imageUrl, {
    int? targetWidth,
    int? targetHeight,
    ImageQuality quality = ImageQuality.medium,
    Widget? placeholder,
    Widget? errorWidget,
    BoxFit fit = BoxFit.cover,
  }) {
    return OptimizedImageWidget(
      imageUrl: imageUrl,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fit: fit,
      imageService: this,
    );
  }

  /// Clear image cache
  Future<void> clearImageCache() async {
    await _cacheManager.clear();
    _imageMetadata.clear();

    // Clear metadata from persistent storage
    final keys = _prefs?.getKeys() ?? <String>{};
    final metadataKeys = keys.where(
      (key) => key.startsWith(_imageMetadataPrefix),
    );

    for (final key in metadataKeys) {
      await _prefs?.remove(key);
    }

    print('🖼️ Cleared image cache');
  }

  // Private helper methods

  String _generateImageCacheKey(
    String imageUrl,
    int? width,
    int? height,
    ImageQuality quality,
  ) {
    return 'img_${imageUrl.hashCode}_${width ?? 0}_${height ?? 0}_${quality.name}';
  }

  Future<ui.Image?> _getCachedImage(String cacheKey) async {
    try {
      final imageData = await _cacheManager.get<Uint8List>(cacheKey);
      if (imageData != null) {
        final codec = await ui.instantiateImageCodec(imageData);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (e) {
      print('❌ Error loading cached image: $e');
    }
    return null;
  }

  Future<ui.Image> _loadAndProcessImage(
    String imageUrl, {
    int? targetWidth,
    int? targetHeight,
    ImageQuality quality = ImageQuality.medium,
  }) async {
    // Load image data
    Uint8List imageData;

    if (imageUrl.startsWith('assets/')) {
      // Asset image
      final byteData = await rootBundle.load(imageUrl);
      imageData = byteData.buffer.asUint8List();
    } else {
      throw Exception('Unsupported image URL: $imageUrl');
    }

    // Decode image
    final codec = await ui.instantiateImageCodec(imageData);
    final frame = await codec.getNextFrame();
    ui.Image image = frame.image;

    // Resize if needed
    if (targetWidth != null || targetHeight != null) {
      image = await _resizeImage(image, targetWidth, targetHeight);
    }

    return image;
  }

  Future<ui.Image> _resizeImage(
    ui.Image image,
    int? targetWidth,
    int? targetHeight,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Calculate dimensions maintaining aspect ratio
    double scaleX = 1.0;
    double scaleY = 1.0;

    if (targetWidth != null) {
      scaleX = targetWidth / image.width;
    }

    if (targetHeight != null) {
      scaleY = targetHeight / image.height;
    }

    final scale = math.min(scaleX, scaleY);
    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();

    // Draw resized image
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(newWidth, newHeight);
  }

  Future<void> _cacheImage(
    String cacheKey,
    ui.Image image,
    String originalUrl,
  ) async {
    try {
      // Convert image to bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final imageBytes = byteData.buffer.asUint8List();
        await _cacheManager.put(cacheKey, imageBytes, ttl: _imageCacheTtl);
      }
    } catch (e) {
      print('❌ Error caching image: $e');
    }
  }

  Future<void> _loadImageMetadata() async {
    // Load metadata implementation
  }

  /// Dispose resources
  void dispose() {
    _cacheManager.dispose();
    _loadingImages.clear();
    _imageMetadata.clear();
  }
}

/// Optimized image widget with lazy loading
class OptimizedImageWidget extends StatefulWidget {
  final String imageUrl;
  final int? targetWidth;
  final int? targetHeight;
  final ImageQuality quality;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final ImageOptimizationService imageService;

  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.targetWidth,
    this.targetHeight,
    this.quality = ImageQuality.medium,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    required this.imageService,
  });

  @override
  State<OptimizedImageWidget> createState() => _OptimizedImageWidgetState();
}

class _OptimizedImageWidgetState extends State<OptimizedImageWidget> {
  ui.Image? _image;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final image = await widget.imageService.loadOptimizedImage(
        widget.imageUrl,
        targetWidth: widget.targetWidth,
        targetHeight: widget.targetHeight,
        quality: widget.quality,
      );

      if (mounted) {
        setState(() {
          _image = image;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return widget.errorWidget ?? const Center(child: Icon(Icons.error));
    }

    if (_image != null) {
      return RawImage(image: _image, fit: widget.fit);
    }

    return widget.placeholder ?? const SizedBox.shrink();
  }
}

/// Image quality levels
enum ImageQuality { low, medium, high, original }

/// Image metadata
class ImageMetadata {
  final String url;
  final int width;
  final int height;
  final int sizeBytes;
  final DateTime loadedAt;

  ImageMetadata({
    required this.url,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.loadedAt,
  });
}

