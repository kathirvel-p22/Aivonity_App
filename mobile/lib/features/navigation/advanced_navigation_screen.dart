import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/enhanced_location_service.dart';

/// Advanced Navigation Screen with AI-powered route optimization
class AdvancedNavigationScreen extends ConsumerStatefulWidget {
  const AdvancedNavigationScreen({super.key});

  @override
  ConsumerState<AdvancedNavigationScreen> createState() =>
      _AdvancedNavigationScreenState();
}

class _AdvancedNavigationScreenState
    extends ConsumerState<AdvancedNavigationScreen>
    with TickerProviderStateMixin {
  late AnimationController _routeAnimationController;
  late Animation<double> _routeAnimation;

  // Navigation state
  String _destination = '';
  List<RouteOption> _routeOptions = [];
  RouteOption? _selectedRoute;
  NavigationMode _navigationMode = NavigationMode.efficient;
  bool _isNavigating = false;

  // Real-time data
  double _currentSpeed = 0.0;
  double _eta = 0.0;
  double _distanceRemaining = 0.0;
  List<TrafficIncident> _trafficIncidents = [];
  List<POI> _pointsOfInterest = [];

  // AI Optimization
  Timer? _optimizationTimer;
  final List<RouteOptimization> _optimizations = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeNavigation();
    _startRealTimeUpdates();
  }

  void _setupAnimations() {
    _routeAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _routeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _routeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeNavigation() {
    // Generate sample route options
    _routeOptions = [
      const RouteOption(
        id: 'route_1',
        name: 'Fastest Route',
        duration: 25,
        distance: 15.2,
        trafficLevel: TrafficLevel.light,
        fuelConsumption: 2.1,
        co2Emission: 4.8,
        tolls: 0,
        highways: true,
        score: 85,
      ),
      const RouteOption(
        id: 'route_2',
        name: 'Eco-Friendly Route',
        duration: 32,
        distance: 16.8,
        trafficLevel: TrafficLevel.moderate,
        fuelConsumption: 1.8,
        co2Emission: 4.1,
        tolls: 2.50,
        highways: false,
        score: 92,
      ),
      const RouteOption(
        id: 'route_3',
        name: 'Scenic Route',
        duration: 45,
        distance: 18.5,
        trafficLevel: TrafficLevel.heavy,
        fuelConsumption: 2.4,
        co2Emission: 5.5,
        tolls: 0,
        highways: false,
        score: 78,
      ),
    ];

    _selectedRoute = _routeOptions[0];

    // Generate sample traffic incidents
    _trafficIncidents = [
      const TrafficIncident(
        id: 'incident_1',
        type: IncidentType.construction,
        description: 'Road construction ahead',
        location: 'Highway 101, Mile 45',
        severity: IncidentSeverity.moderate,
        estimatedDelay: 10,
        distance: 2.5,
      ),
      const TrafficIncident(
        id: 'incident_2',
        type: IncidentType.accident,
        description: 'Multi-vehicle accident',
        location: 'Main St & Oak Ave',
        severity: IncidentSeverity.high,
        estimatedDelay: 25,
        distance: 5.2,
      ),
    ];

    // Generate sample POIs
    _pointsOfInterest = [
      const POI(
        id: 'poi_1',
        name: 'Rest Stop',
        type: POIType.restArea,
        distance: 3.2,
        rating: 4.2,
        amenities: ['Restrooms', 'Food', 'Fuel'],
      ),
      const POI(
        id: 'poi_2',
        name: 'Charging Station',
        type: POIType.chargingStation,
        distance: 7.8,
        rating: 4.8,
        amenities: ['Fast Charging', 'Restrooms'],
      ),
    ];
  }

  void _startRealTimeUpdates() {
    // Simulate real-time navigation updates
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isNavigating) {
        setState(() {
          _currentSpeed = 45 + Random().nextDouble() * 20;
          _distanceRemaining = max(0, _distanceRemaining - 0.1);
          _eta = _distanceRemaining / (_currentSpeed / 60); // ETA in minutes
        });
      }
    });

    // AI route optimization
    _optimizationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _isNavigating) {
        _generateRouteOptimization();
      }
    });
  }

  void _generateRouteOptimization() {
    final optimizations = [
      RouteOptimization(
        id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
        type: OptimizationType.trafficAvoidance,
        title: 'Avoid Traffic Jam Ahead',
        description: 'Alternative route saves 12 minutes',
        timeSaved: 12,
        fuelSaved: 0.3,
        confidence: 0.85,
      ),
      RouteOptimization(
        id: 'opt_${DateTime.now().millisecondsSinceEpoch + 1}',
        type: OptimizationType.fuelEfficiency,
        title: 'Eco Route Available',
        description: 'Slight detour reduces fuel consumption by 8%',
        timeSaved: -3, // Slight time increase
        fuelSaved: 0.5,
        confidence: 0.78,
      ),
    ];

    setState(() {
      _optimizations
          .addAll(optimizations.take(2)); // Keep only recent optimizations
      if (_optimizations.length > 3) {
        _optimizations.removeRange(0, _optimizations.length - 3);
      }
    });
  }

  @override
  void dispose() {
    _routeAnimationController.dispose();
    _optimizationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Navigation'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_location),
            onPressed: _shareCurrentLocation,
            tooltip: 'Share Location',
          ),
          IconButton(
            icon: const Icon(Icons.launch),
            onPressed: _showNavigationAppSelector,
            tooltip: 'Open in External App',
          ),
          IconButton(
            icon: Icon(
              _navigationMode == NavigationMode.efficient
                  ? Icons.speed
                  : _navigationMode == NavigationMode.eco
                      ? Icons.eco
                      : Icons.landscape,
            ),
            onPressed: _showNavigationModeSelector,
          ),
        ],
      ),
      body: _isNavigating ? _buildNavigationView() : _buildRoutePlanningView(),
    );
  }

  Widget _buildRoutePlanningView() {
    return Column(
      children: [
        // Destination input
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Enter destination',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) => setState(() => _destination = value),
          ),
        ),

        // Route options
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _routeOptions.length,
            itemBuilder: (context, index) {
              final route = _routeOptions[index];
              final isSelected = _selectedRoute?.id == route.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedRoute = route),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              route.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTrafficColor(route.trafficLevel)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                route.trafficLevel.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getTrafficColor(route.trafficLevel),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
                            Text('${route.duration} min'),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.straighten,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text('${route.distance} mi'),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.local_gas_station,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text('${route.fuelConsumption} gal'),
                          ],
                        ),
                        if (route.tolls > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.orange[600],
                              ),
                              const SizedBox(width: 4),
                              Text('\$${route.tolls} toll'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: route.score / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            route.score > 80
                                ? Colors.green
                                : route.score > 60
                                    ? Colors.yellow
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Route Score: ${route.score}/100',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Navigation action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Start navigation button (internal)
              ElevatedButton(
                onPressed: _selectedRoute != null ? _startNavigation : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Start Navigation (In-App)'),
              ),
              const SizedBox(height: 12),
              // Launch external navigation app
              OutlinedButton(
                onPressed:
                    _selectedRoute != null ? _showNavigationAppSelector : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Open in Navigation App'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationView() {
    return Stack(
      children: [
        // Map placeholder (would be replaced with actual map widget)
        Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.map, size: 100, color: Colors.grey),
          ),
        ),

        // Navigation overlay
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: _buildNavigationHeader(),
        ),

        // Route optimizations
        if (_optimizations.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: _buildOptimizationsPanel(),
          ),

        // Bottom navigation controls
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildNavigationControls(),
        ),
      ],
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.navigation, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Turn right in 500 ft',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_distanceRemaining.toStringAsFixed(1)} mi • ${_eta.toStringAsFixed(0)} min',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentSpeed.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationsPanel() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: _optimizations.length,
        itemBuilder: (context, index) {
          final optimization = _optimizations[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getOptimizationIcon(optimization.type),
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        optimization.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  optimization.description,
                  style: const TextStyle(fontSize: 10),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (optimization.timeSaved > 0)
                      Text(
                        '+${optimization.timeSaved}min',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (optimization.fuelSaved > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${optimization.fuelSaved}gal saved',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          Icons.volume_up,
          'Voice',
          () => _toggleVoiceGuidance(),
        ),
        _buildControlButton(
          Icons.my_location,
          'Center',
          () => _centerOnRoute(),
        ),
        _buildControlButton(
          Icons.pause,
          'Pause',
          () => setState(() => _isNavigating = false),
        ),
        _buildControlButton(
          Icons.stop,
          'End',
          () => _endNavigation(),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        FloatingActionButton(
          mini: true,
          onPressed: onPressed,
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  void _showNavigationModeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Navigation Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...NavigationMode.values.map(
              (mode) => ListTile(
                leading: Icon(_getNavigationModeIcon(mode)),
                title: Text(_getNavigationModeName(mode)),
                subtitle: Text(_getNavigationModeDescription(mode)),
                onTap: () {
                  setState(() => _navigationMode = mode);
                  Navigator.of(context).pop();
                },
                selected: _navigationMode == mode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _distanceRemaining = _selectedRoute?.distance ?? 15.0;
    });
  }

  void _endNavigation() {
    setState(() {
      _isNavigating = false;
      _optimizations.clear();
    });
  }

  void _toggleVoiceGuidance() {
    // Toggle voice guidance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice guidance toggled')),
    );
  }

  void _centerOnRoute() {
    // Center map on current route
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Centered on route')),
    );
  }

  void _shareCurrentLocation() {
    final locationService = ref.read(enhancedLocationServiceProvider);
    locationService.shareCurrentLocation(
      message: 'Sharing my current location for navigation',
    );
  }

  Color _getTrafficColor(TrafficLevel level) {
    switch (level) {
      case TrafficLevel.light:
        return Colors.green;
      case TrafficLevel.moderate:
        return Colors.yellow;
      case TrafficLevel.heavy:
        return Colors.red;
    }
  }

  IconData _getOptimizationIcon(OptimizationType type) {
    switch (type) {
      case OptimizationType.trafficAvoidance:
        return Icons.traffic;
      case OptimizationType.fuelEfficiency:
        return Icons.eco;
      case OptimizationType.timeOptimization:
        return Icons.schedule;
    }
  }

  IconData _getNavigationModeIcon(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.fastest:
        return Icons.speed;
      case NavigationMode.efficient:
        return Icons.timeline;
      case NavigationMode.eco:
        return Icons.eco;
      case NavigationMode.scenic:
        return Icons.landscape;
    }
  }

  String _getNavigationModeName(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.fastest:
        return 'Fastest';
      case NavigationMode.efficient:
        return 'Efficient';
      case NavigationMode.eco:
        return 'Eco-Friendly';
      case NavigationMode.scenic:
        return 'Scenic';
    }
  }

  String _getNavigationModeDescription(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.fastest:
        return 'Minimize travel time';
      case NavigationMode.efficient:
        return 'Balance time and efficiency';
      case NavigationMode.eco:
        return 'Minimize fuel consumption and emissions';
      case NavigationMode.scenic:
        return 'Enjoy the journey with scenic routes';
    }
  }

  void _showNavigationAppSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Choose Navigation App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<NavigationApp>>(
                future: ref
                    .read(enhancedLocationServiceProvider)
                    .getAvailableNavigationApps(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final availableApps = snapshot.data ?? [];
                  final allApps = NavigationApp.values
                      .where(
                        (app) => app.isAvailableOnPlatform,
                      )
                      .toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: allApps.length,
                    itemBuilder: (context, index) {
                      final app = allApps[index];
                      final isInstalled = availableApps.contains(app);

                      return ListTile(
                        leading: Icon(
                          _getNavigationAppIcon(app),
                          color: isInstalled ? null : Colors.grey,
                        ),
                        title: Text(
                          app.displayName,
                          style: TextStyle(
                            color: isInstalled ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          isInstalled ? 'Installed' : 'Not installed',
                          style: TextStyle(
                            color: isInstalled ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isInstalled
                            ? const Icon(Icons.chevron_right)
                            : const Icon(Icons.download, color: Colors.grey),
                        onTap: isInstalled
                            ? () => _launchExternalNavigation(app)
                            : () => _showAppStoreDialog(app),
                        enabled: isInstalled,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchExternalNavigation(NavigationApp app) async {
    try {
      // Get destination coordinates - try selected route first, then search destination
      double destinationLat;
      double destinationLng;
      String destinationLabel;

      if (_selectedRoute != null) {
        // For advanced navigation, we'll use a default destination since routes are simulated
        // In a real implementation, this would come from actual route calculation
        destinationLat = 37.7749; // Default: San Francisco
        destinationLng = -122.4194;
        destinationLabel = _selectedRoute!.name;
      } else if (_destination.isNotEmpty) {
        // Try to geocode the destination text
        final locationService = ref.read(enhancedLocationServiceProvider);
        try {
          final locations = await locationService.geocodeAddress(_destination);
          if (locations.isNotEmpty) {
            destinationLat = locations.first.latitude;
            destinationLng = locations.first.longitude;
            destinationLabel = _destination;
          } else {
            throw Exception('Could not geocode destination');
          }
        } catch (e) {
          // Fallback to current location if geocoding fails
          final locationService = ref.read(enhancedLocationServiceProvider);
          if (locationService.currentPosition != null) {
            destinationLat = locationService.currentPosition!.latitude;
            destinationLng = locationService.currentPosition!.longitude;
            destinationLabel = 'Current Location Area';
          } else {
            throw Exception(
              'No destination available and current location unknown',
            );
          }
        }
      } else {
        throw Exception('Please select a route or enter a destination');
      }

      await ref.read(enhancedLocationServiceProvider).launchNavigationApp(
            destinationLatitude: destinationLat,
            destinationLongitude: destinationLng,
            app: app,
            destinationLabel: destinationLabel,
          );

      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${app.displayName}...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch ${app.displayName}: $e')),
      );
    }
  }

  void _showAppStoreDialog(NavigationApp app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${app.displayName}'),
        content: Text(
          '${app.displayName} is not installed on your device. Would you like to install it from the app store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(enhancedLocationServiceProvider)
                    .launchAppStoreForNavigationApp(app);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opening app store for ${app.displayName}...',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to open app store: $e')),
                  );
                }
              }
            },
            child: const Text('Install'),
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

// Data Models
enum NavigationMode { fastest, efficient, eco, scenic }

enum TrafficLevel { light, moderate, heavy }

enum IncidentType { accident, construction, roadwork, weather }

enum IncidentSeverity { low, moderate, high }

enum POIType { restArea, chargingStation, gasStation, restaurant }

enum OptimizationType { trafficAvoidance, fuelEfficiency, timeOptimization }

class RouteOption {
  final String id;
  final String name;
  final int duration; // minutes
  final double distance; // miles
  final TrafficLevel trafficLevel;
  final double fuelConsumption; // gallons
  final double co2Emission; // kg
  final double tolls; // dollars
  final bool highways;
  final int score; // 0-100

  const RouteOption({
    required this.id,
    required this.name,
    required this.duration,
    required this.distance,
    required this.trafficLevel,
    required this.fuelConsumption,
    required this.co2Emission,
    required this.tolls,
    required this.highways,
    required this.score,
  });
}

class TrafficIncident {
  final String id;
  final IncidentType type;
  final String description;
  final String location;
  final IncidentSeverity severity;
  final int estimatedDelay; // minutes
  final double distance; // miles

  const TrafficIncident({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.severity,
    required this.estimatedDelay,
    required this.distance,
  });
}

class POI {
  final String id;
  final String name;
  final POIType type;
  final double distance; // miles
  final double rating;
  final List<String> amenities;

  const POI({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.rating,
    required this.amenities,
  });
}

class RouteOptimization {
  final String id;
  final OptimizationType type;
  final String title;
  final String description;
  final int timeSaved; // minutes (negative means time added)
  final double fuelSaved; // gallons
  final double confidence; // 0.0-1.0

  const RouteOptimization({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timeSaved,
    required this.fuelSaved,
    required this.confidence,
  });
}

