import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/location_service.dart';
import '../../../core/utils/logger.dart';
import '../models/service_center.dart';

// Location Service Provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// AIVONITY Service Center Map Widget
/// Interactive map showing service center locations
class ServiceCenterMap extends ConsumerStatefulWidget {
  final List<ServiceCenter> serviceCenters;
  final ServiceCenter? selectedCenter;
  final Function(ServiceCenter)? onCenterSelected;
  final bool showUserLocation;

  const ServiceCenterMap({
    super.key,
    required this.serviceCenters,
    this.selectedCenter,
    this.onCenterSelected,
    this.showUserLocation = true,
  });

  @override
  ConsumerState<ServiceCenterMap> createState() => _ServiceCenterMapState();
}

class _ServiceCenterMapState extends ConsumerState<ServiceCenterMap>
    with LoggingMixin {
  LocationData? _userLocation;
  ServiceCenter? _selectedCenter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCenter = widget.selectedCenter;
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    if (widget.showUserLocation) {
      try {
        final locationService = ref.read(locationServiceProvider);
        final location = await locationService.getCurrentLocation();

        if (mounted) {
          setState(() {
            _userLocation = location;
            _isLoading = false;
          });
        }
      } catch (e) {
        logError('Failed to load user location', e);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Mock Map Background
            _buildMapBackground(),

            // Service Center Markers
            ...widget.serviceCenters.asMap().entries.map((entry) {
              final index = entry.key;
              final center = entry.value;
              return _buildServiceCenterMarker(center, index);
            }),

            // User Location Marker
            if (_userLocation != null) _buildUserLocationMarker(),

            // Map Controls
            _buildMapControls(),

            // Selected Center Info
            if (_selectedCenter != null) _buildSelectedCenterInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.green.shade50],
        ),
      ),
      child: CustomPaint(painter: MapBackgroundPainter()),
    );
  }

  Widget _buildServiceCenterMarker(ServiceCenter center, int index) {
    final isSelected = _selectedCenter?.id == center.id;

    // Calculate position based on coordinates (mock positioning)
    final left = (center.longitude + 74.0060) * 1000 % 250;
    final top = (40.7831 - center.latitude) * 1000 % 200;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCenter = center;
          });
          widget.onCenterSelected?.call(center);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 40 : 32,
          height: isSelected ? 40 : 32,
          decoration: BoxDecoration(
            color:
                isSelected ? Theme.of(context).colorScheme.primary : Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.build,
            color: Colors.white,
            size: isSelected ? 20 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    // Mock user location positioning
    const left = 125.0;
    const top = 100.0;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Zoom In
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () {
                // Mock zoom in functionality
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Zoom in')));
              },
            ),
          ),

          const SizedBox(height: 8),

          // Zoom Out
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.remove, size: 20),
              onPressed: () {
                // Mock zoom out functionality
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Zoom out')));
              },
            ),
          ),

          const SizedBox(height: 8),

          // My Location
          if (widget.showUserLocation)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, size: 20),
                onPressed: () {
                  // Mock center on user location
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Centered on your location')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedCenterInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCenter!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedCenter = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _selectedCenter!.address,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  _selectedCenter!.rating.toStringAsFixed(1),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                if (_selectedCenter!.distanceKm != null) ...[
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedCenter!.distanceKm!.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for map background
class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw grid lines to simulate map
    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Draw some mock roads
    final roadPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

