import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/enhanced_location_service.dart';
import '../../../core/services/service_centers_service.dart';

// Import the ServiceCenter model from the service
import '../../../core/services/service_centers_service.dart'
    show ServiceCenter, LocationCoordinates;

/// Service Centers Screen with Location Integration
class ServiceCentersScreen extends ConsumerStatefulWidget {
  const ServiceCentersScreen({super.key});

  @override
  ConsumerState<ServiceCentersScreen> createState() =>
      _ServiceCentersScreenState();
}

class _ServiceCentersScreenState extends ConsumerState<ServiceCentersScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  List<ServiceCenter> _serviceCenters = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServiceCenters();
  }

  void _loadServiceCenters() {
    setState(() => _isLoading = true);

    // Load service centers from service
    Future.delayed(const Duration(milliseconds: 500), () {
      final serviceCentersService = ServiceCentersService();
      setState(() {
        _serviceCenters = serviceCentersService.getAllServiceCenters();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Centers'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnUserLocation,
            tooltip: 'Find Nearest Centers',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildServiceCentersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _shareCurrentLocationForService(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.share_location, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search service centers...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Services'),
                const SizedBox(width: 8),
                _buildFilterChip('maintenance', 'Maintenance'),
                const SizedBox(width: 8),
                _buildFilterChip('repair', 'Repair'),
                const SizedBox(width: 8),
                _buildFilterChip('mobile', 'Mobile Service'),
                const SizedBox(width: 8),
                _buildFilterChip('emergency', 'Emergency'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedFilter = value),
      selectedColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
    );
  }

  Widget _buildServiceCentersList() {
    final filteredCenters = _serviceCenters.where((center) {
      final matchesSearch =
          center.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              center.address.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'all' ||
          center.services.any(
            (service) => service.toLowerCase().contains(_selectedFilter),
          );

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredCenters.isEmpty) {
      return const Center(
        child: Text('No service centers found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCenters.length,
      itemBuilder: (context, index) {
        final center = filteredCenters[index];
        return _buildServiceCenterCard(center);
      },
    );
  }

  Widget _buildServiceCenterCard(ServiceCenter center) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    center.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: center.isOpen ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    center.isOpen ? 'OPEN' : 'CLOSED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              center.address,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text('${center.rating}'),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text('Distance: Calculate'),
                const SizedBox(width: 16),
                const Icon(
                  Icons.phone,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(center.phone),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: center.services.map((service) {
                return Chip(
                  label: Text(service, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _callCenter(center),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _getDirections(center),
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _bookAtCenter(center),
                  icon: const Icon(Icons.book_online, size: 16),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _callCenter(ServiceCenter center) async {
    final url = 'tel:${center.phone}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make phone call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $e')),
      );
    }
  }

  void _getDirections(ServiceCenter center) async {
    final locationService = ref.read(enhancedLocationServiceProvider);

    try {
      // Get available navigation apps
      final availableApps = await locationService.getAvailableNavigationApps();

      if (availableApps.isEmpty) {
        // Fallback to web URL with proper error handling
        final url =
            'https://www.google.com/maps/dir/?api=1&destination=${center.coordinates.latitude},${center.coordinates.longitude}';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Google Maps in browser')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to open maps. Please install a navigation app.',
              ),
            ),
          );
        }
        return;
      }

      if (availableApps.length == 1) {
        // Only one app available, use it directly
        await locationService.launchNavigationApp(
          destinationLatitude: center.coordinates.latitude,
          destinationLongitude: center.coordinates.longitude,
          app: availableApps.first,
          destinationLabel: center.name,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${availableApps.first.displayName}...'),
            ),
          );
        }
      } else {
        // Multiple apps available, show selection dialog
        _showNavigationAppSelectionDialog(center, availableApps);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening directions: $e')),
        );
      }
    }
  }

  void _bookAtCenter(ServiceCenter center) {
    // Navigate back to booking with selected center
    Navigator.pop(context, center);
  }

  void _centerOnUserLocation() {
    // Use enhanced location service to find nearest centers
    final locationService = ref.read(enhancedLocationServiceProvider);
    locationService.getCurrentLocation().then((position) {
      if (position != null) {
        // Sort centers by distance from current location
        setState(() {
          _serviceCenters.sort((a, b) {
            final distanceA = _calculateDistance(
              position.latitude,
              position.longitude,
              a.coordinates.latitude,
              a.coordinates.longitude,
            );
            final distanceB = _calculateDistance(
              position.latitude,
              position.longitude,
              b.coordinates.latitude,
              b.coordinates.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Centers sorted by distance')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current location')),
        );
      }
    });
  }

  void _shareCurrentLocationForService() {
    final locationService = ref.read(enhancedLocationServiceProvider);
    locationService.shareCurrentLocation(
      message: 'Looking for service centers near my location',
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Haversine formula for distance calculation
    const double R = 6371; // Earth's radius in kilometers

    final double dLat = (lat2 - lat1) * 3.14159 / 180;
    final double dLon = (lon2 - lon1) * 3.14159 / 180;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * 3.14159 / 180) *
            cos(lat2 * 3.14159 / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c * 0.621371; // Convert to miles
  }

  void _showNavigationAppSelectionDialog(
    ServiceCenter center,
    List<NavigationApp> availableApps,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Navigation App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableApps.map((app) {
            return ListTile(
              leading: Icon(_getNavigationAppIcon(app)),
              title: Text(app.displayName),
              onTap: () async {
                Navigator.of(context).pop();
                final locationService =
                    ref.read(enhancedLocationServiceProvider);
                try {
                  await locationService.launchNavigationApp(
                    destinationLatitude: center.coordinates.latitude,
                    destinationLongitude: center.coordinates.longitude,
                    app: app,
                    destinationLabel: center.name,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening ${app.displayName}: $e'),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  IconData _getNavigationAppIcon(NavigationApp app) {
    switch (app) {
      case NavigationApp.googleMaps:
        return Icons.map;
      case NavigationApp.waze:
        return Icons.navigation;
      case NavigationApp.appleMaps:
        return Icons.location_on;
      case NavigationApp.hereWeGo:
        return Icons.explore;
      case NavigationApp.yandex:
        return Icons.public;
      case NavigationApp.mapsMe:
        return Icons.place;
      case NavigationApp.osmAnd:
        return Icons.terrain;
      case NavigationApp.sygic:
        return Icons.gps_fixed;
      case NavigationApp.tomtom:
        return Icons.directions_car;
      case NavigationApp.coPilot:
        return Icons.navigation;
      case NavigationApp.mapQuest:
        return Icons.map;
    }
  }
}
