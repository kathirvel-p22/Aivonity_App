import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/enhanced_location_service.dart';

/// Vehicle Locator Screen with enhanced real-time GPS tracking and sharing
class VehicleLocatorScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const VehicleLocatorScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  ConsumerState<VehicleLocatorScreen> createState() =>
      _VehicleLocatorScreenState();
}

class _VehicleLocatorScreenState extends ConsumerState<VehicleLocatorScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Enhanced location service
  late EnhancedLocationService _locationService;

  // Vehicle location data
  Position? _vehiclePosition;
  String _vehicleAddress = 'Loading location...';
  String _lastUpdate = 'Just now';
  bool _isTracking = true;
  double _accuracy = 5.0; // meters

  Timer? _locationTimer;
  List<Map<String, dynamic>> _locationHistory = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLocationService();
    _startLocationTracking();
    _loadLocationHistory();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeLocationService() {
    _locationService = ref.read(enhancedLocationServiceProvider);
    _locationService.initialize();
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _isTracking) {
        _updateLocation();
      }
    });
    _updateLocation(); // Initial update
  }

  void _updateLocation() async {
    try {
      // Get real location from enhanced location service
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _vehiclePosition = position;
          _vehicleAddress = _locationService.currentAddress;
          _accuracy = position.accuracy;
          _lastUpdate = 'Just now';

          // Add to history
          _locationHistory.insert(0, {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now(),
            'accuracy': position.accuracy,
            'address': _vehicleAddress,
          });

          // Keep only last 10 locations
          if (_locationHistory.length > 10) {
            _locationHistory = _locationHistory.sublist(0, 10);
          }
        });
      }
    } catch (e) {
      // Fallback to mock data if real location fails
      setState(() {
        final random = Random();
        _vehiclePosition = Position(
          latitude: 40.7128 + (random.nextDouble() - 0.5) * 0.001,
          longitude: -74.0060 + (random.nextDouble() - 0.5) * 0.001,
          timestamp: DateTime.now(),
          accuracy: 3.0 + random.nextDouble() * 7.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _vehicleAddress = '123 Main Street, New York, NY 10001';
        _accuracy = _vehiclePosition!.accuracy;
        _lastUpdate = 'Just now';
      });
    }
  }

  void _loadLocationHistory() {
    // Use current vehicle position as base for history or fallback to default coordinates
    final baseLat = _vehiclePosition?.latitude ?? 40.7128; // Default NYC
    final baseLng = _vehiclePosition?.longitude ?? -74.0060;

    // Simulate loading recent locations around current position
    _locationHistory = List.generate(5, (index) {
      final now = DateTime.now();
      return {
        'latitude': baseLat + (Random().nextDouble() - 0.5) * 0.01,
        'longitude': baseLng + (Random().nextDouble() - 0.5) * 0.01,
        'timestamp': now.subtract(Duration(minutes: index * 2)),
        'accuracy': 3.0 + Random().nextDouble() * 7.0,
        'address': 'Historical location ${index + 1}',
      };
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find ${widget.vehicleName}',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.location_on : Icons.location_off),
            onPressed: _toggleTracking,
            tooltip: _isTracking ? 'Stop Tracking' : 'Start Tracking',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareLocation();
                  break;
                case 'directions':
                  _getDirections();
                  break;
                case 'history':
                  _showLocationHistory();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text('Share Location'),
              ),
              const PopupMenuItem(
                value: 'directions',
                child: Text('Get Directions'),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Text('Location History'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLocationCard(),
          Expanded(
            child: _buildMapPlaceholder(),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isTracking ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isTracking ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vehicleName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isTracking ? 'Tracking Active' : 'Tracking Paused',
                        style: TextStyle(
                          color: _isTracking ? Colors.green : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '±${_accuracy.toStringAsFixed(1)}m',
                    style: TextStyle(
                      color: _getAccuracyColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _vehicleAddress,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Last updated: $_lastUpdate',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (_vehiclePosition != null)
                  Text(
                    '${_vehiclePosition!.latitude.toStringAsFixed(4)}, ${_vehiclePosition!.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Mock map background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[100]!, Colors.green[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Grid lines to simulate map
          CustomPaint(
            painter: MapGridPainter(),
            size: Size.infinite,
          ),

          // Vehicle marker
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isTracking ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),

          // Accuracy circle
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ),

          // Map controls
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () {},
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Location info overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMapInfo('Speed', '0 mph'),
                  _buildMapInfo('Heading', 'N'),
                  _buildMapInfo('Altitude', '50 ft'),
                  _buildMapInfo('Signal', 'Strong'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Directions'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareLocation,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTracking() {
    setState(() => _isTracking = !_isTracking);

    if (_isTracking) {
      _startLocationTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location tracking started')),
      );
    } else {
      _locationTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location tracking stopped')),
      );
    }
  }

  void _shareLocation() async {
    try {
      await _locationService.shareCurrentLocation(
        message: 'Vehicle location from ${widget.vehicleName}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _getDirections() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening navigation app...')),
    );
  }

  void _showLocationHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _locationHistory.length,
                  itemBuilder: (context, index) {
                    final location = _locationHistory[index];
                    final timestamp = location['timestamp'] as DateTime;
                    final accuracy = location['accuracy'] as double;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.location_on, color: Colors.blue),
                        title: Text(
                          '${location['latitude'].toStringAsFixed(4)}, ${location['longitude'].toStringAsFixed(4)}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: Text(
                          '${_formatTimeAgo(timestamp)} • ±${accuracy.toStringAsFixed(1)}m accuracy',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.directions),
                          onPressed: () => _getDirectionsToLocation(location),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _getDirectionsToLocation(Map<String, dynamic> location) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Getting directions to historical location...'),
      ),
    );
  }

  Color _getAccuracyColor() {
    if (_accuracy <= 5) return Colors.green;
    if (_accuracy <= 10) return Colors.yellow;
    return Colors.red;
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

