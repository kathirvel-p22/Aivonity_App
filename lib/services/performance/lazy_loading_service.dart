import 'dart:async';
import 'package:flutter/material.dart';

/// Service for implementing lazy loading of widgets and data
class LazyLoadingService {
  final Map<String, LazyLoadController> _controllers = {};
  final Map<String, Timer> _loadTimers = {};

  /// Create a lazy load controller for a specific context
  LazyLoadController createController(String id) {
    final controller = LazyLoadController(id);
    _controllers[id] = controller;
    return controller;
  }

  /// Remove a lazy load controller
  void removeController(String id) {
    _controllers.remove(id);
    _loadTimers[id]?.cancel();
    _loadTimers.remove(id);
  }

  /// Create a lazy loading widget
  Widget createLazyWidget({
    required String id,
    required Widget Function() builder,
    Widget? placeholder,
    Duration delay = const Duration(milliseconds: 100),
    bool preload = false,
  }) {
    return LazyLoadWidget(
      id: id,
      builder: builder,
      placeholder: placeholder,
      delay: delay,
      preload: preload,
      service: this,
    );
  }

  /// Schedule delayed loading
  void scheduleLoad(String id, VoidCallback callback, Duration delay) {
    _loadTimers[id]?.cancel();
    _loadTimers[id] = Timer(delay, callback);
  }

  /// Cancel scheduled loading
  void cancelLoad(String id) {
    _loadTimers[id]?.cancel();
    _loadTimers.remove(id);
  }

  /// Dispose all resources
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    for (final timer in _loadTimers.values) {
      timer.cancel();
    }
    _loadTimers.clear();
  }
}

/// Controller for managing lazy loading state
class LazyLoadController {
  final String id;
  final StreamController<LazyLoadState> _stateController =
      StreamController<LazyLoadState>.broadcast();

  LazyLoadState _state = LazyLoadState.idle;
  dynamic _data;
  String? _error;

  LazyLoadController(this.id);

  /// Stream of loading states
  Stream<LazyLoadState> get stateStream => _stateController.stream;

  /// Current loading state
  LazyLoadState get state => _state;

  /// Loaded data
  dynamic get data => _data;

  /// Error message if loading failed
  String? get error => _error;

  /// Load data asynchronously
  Future<void> loadData(Future<dynamic> Function() loader) async {
    if (_state == LazyLoadState.loading) return;

    _setState(LazyLoadState.loading);

    try {
      _data = await loader();
      _error = null;
      _setState(LazyLoadState.loaded);
    } catch (e) {
      _error = e.toString();
      _setState(LazyLoadState.error);
    }
  }

  /// Reset controller state
  void reset() {
    _data = null;
    _error = null;
    _setState(LazyLoadState.idle);
  }

  void _setState(LazyLoadState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Dispose controller
  void dispose() {
    _stateController.close();
  }
}

/// Lazy loading widget that loads content when needed
class LazyLoadWidget extends StatefulWidget {
  final String id;
  final Widget Function() builder;
  final Widget? placeholder;
  final Duration delay;
  final bool preload;
  final LazyLoadingService service;

  const LazyLoadWidget({
    super.key,
    required this.id,
    required this.builder,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
    this.preload = false,
    required this.service,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  final bool _isVisible = false;
  bool _hasLoaded = false;
  Widget? _content;

  @override
  void initState() {
    super.initState();

    if (widget.preload) {
      _loadContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _hasLoaded && _content != null
        ? _content!
        : widget.placeholder ?? const SizedBox.shrink();
  }

  void _loadContent() {
    if (_hasLoaded) return;

    setState(() {
      _content = widget.builder();
      _hasLoaded = true;
    });
  }

  @override
  void dispose() {
    widget.service.cancelLoad(widget.id);
    super.dispose();
  }
}

/// Lazy loading states
enum LazyLoadState { idle, loading, loaded, error }

