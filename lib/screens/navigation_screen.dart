import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/navigation.dart';
import '../models/service_center.dart';
import '../services/navigation_service.dart';
import '../services/maps_service.dart';
import '../widgets/route_planner.dart';

class NavigationScreen extends StatefulWidget {
  final List<ServiceCenter>? serviceCenters;
  final ServiceCenter? selectedServiceCenter;

  const NavigationScreen({
    super.key,
    this.serviceCenters,
    this.selectedServiceCenter,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationService _navigationService =
      GetIt.instance<NavigationService>();
  final MapsService _mapsService = GetIt.instance<MapsService>();

  List<ServiceCenterRoute> _routes = [];
  Coordinates? _userLocation;
  bool _isLoading = false;
  String? _error;
  RouteOptions _routeOptions = const RouteOptions();

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndCalculateRoutes();
  }

  Future<void> _loadUserLocationAndCalculateRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _userLocation = await _mapsService.getCurrentLocation();

      if (widget.selectedServiceCenter != null) {
        // Calculate route to single service center
        await _calculateSingleRoute(widget.selectedServiceCenter!);
      } else if (widget.serviceCenters != null &&
          widget.serviceCenters!.isNotEmpty) {
        // Calculate routes to multiple service centers
        await _calculateMultipleRoutes(widget.serviceCenters!);
      } else {
        setState(() {
          _error = 'No service centers provided for navigation';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateSingleRoute(ServiceCenter serviceCenter) async {
    if (_userLocation == null) return;

    try {
      final routes = await _navigationService.calculateServiceCenterRoutes(
        origin: _userLocation!,
        serviceCenters: [serviceCenter],
        options: _routeOptions,
      );

      setState(() {
        _routes = routes;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to calculate route: $e';
      });
    }
  }

  Future<void> _calculateMultipleRoutes(
    List<ServiceCenter> serviceCenters,
  ) async {
    if (_userLocation == null) return;

    try {
      final routes = await _navigationService.calculateServiceCenterRoutes(
        origin: _userLocation!,
        serviceCenters: serviceCenters
            .take(5)
            .toList(), // Limit to 5 for performance
        options: _routeOptions,
      );

      setState(() {
        _routes = routes;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to calculate routes: $e';
      });
    }
  }

  void _showRouteOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteOptionsSheet(
        currentOptions: _routeOptions,
        onOptionsChanged: (options) {
          setState(() {
            _routeOptions = options;
          });
          _loadUserLocationAndCalculateRoutes();
        },
      ),
    );
  }

  void _showNavigationAppSelector(ServiceCenter serviceCenter) {
    final parentContext = context;
    final messenger = ScaffoldMessenger.of(parentContext);
    showModalBottomSheet(
      context: context,
      builder: (context) => NavigationAppSelector(
        serviceCenter: serviceCenter,
        onAppSelected: (app) async {
          Navigator.of(context).pop();

          final destination = Coordinates(
            latitude: serviceCenter.latitude,
            longitude: serviceCenter.longitude,
          );

          try {
            final success = await _navigationService.launchNavigation(
              destination: destination,
              origin: _userLocation,
              preferredApp: app,
              destinationName: serviceCenter.name,
            );

            if (success && mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Opening ${_getAppName(app)}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to open navigation: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _getAppName(NavigationApp app) {
    switch (app) {
      case NavigationApp.googleMaps:
        return 'Google Maps';
      case NavigationApp.appleMaps:
        return 'Apple Maps';
      case NavigationApp.waze:
        return 'Waze';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showRouteOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserLocationAndCalculateRoutes,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calculating routes...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserLocationAndCalculateRoutes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_routes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No routes available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RoutePlanner(
      routes: _routes,
      userLocation: _userLocation,
      onRouteSelected: (route) {
        // Handle route selection
      },
      onNavigatePressed: (serviceCenter) {
        _showNavigationAppSelector(serviceCenter);
      },
    );
  }
}

class RouteOptionsSheet extends StatefulWidget {
  final RouteOptions currentOptions;
  final Function(RouteOptions) onOptionsChanged;

  const RouteOptionsSheet({
    super.key,
    required this.currentOptions,
    required this.onOptionsChanged,
  });

  @override
  State<RouteOptionsSheet> createState() => _RouteOptionsSheetState();
}

class _RouteOptionsSheetState extends State<RouteOptionsSheet> {
  late bool _avoidTolls;
  late bool _avoidHighways;
  late bool _avoidFerries;
  late String _travelMode;

  final List<String> _travelModes = [
    'driving',
    'walking',
    'bicycling',
    'transit',
  ];

  @override
  void initState() {
    super.initState();
    _avoidTolls = widget.currentOptions.avoidTolls;
    _avoidHighways = widget.currentOptions.avoidHighways;
    _avoidFerries = widget.currentOptions.avoidFerries;
    _travelMode = widget.currentOptions.travelMode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Route Options',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Travel mode
                  Text(
                    'Travel Mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _travelMode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _travelModes.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(_getTravelModeDisplayName(mode)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _travelMode = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Avoidance options
                  Text('Avoid', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('Tolls'),
                    subtitle: const Text('Avoid toll roads when possible'),
                    value: _avoidTolls,
                    onChanged: (value) {
                      setState(() {
                        _avoidTolls = value;
                      });
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Highways'),
                    subtitle: const Text('Avoid highways and freeways'),
                    value: _avoidHighways,
                    onChanged: (value) {
                      setState(() {
                        _avoidHighways = value;
                      });
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Ferries'),
                    subtitle: const Text('Avoid ferry crossings'),
                    value: _avoidFerries,
                    onChanged: (value) {
                      setState(() {
                        _avoidFerries = value;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyOptions,
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTravelModeDisplayName(String mode) {
    switch (mode) {
      case 'driving':
        return 'Driving';
      case 'walking':
        return 'Walking';
      case 'bicycling':
        return 'Bicycling';
      case 'transit':
        return 'Public Transit';
      default:
        return mode;
    }
  }

  void _applyOptions() {
    final options = RouteOptions(
      avoidTolls: _avoidTolls,
      avoidHighways: _avoidHighways,
      avoidFerries: _avoidFerries,
      travelMode: _travelMode,
    );

    widget.onOptionsChanged(options);
    Navigator.of(context).pop();
  }
}

class NavigationAppSelector extends StatelessWidget {
  final ServiceCenter serviceCenter;
  final Function(NavigationApp) onAppSelected;

  const NavigationAppSelector({
    super.key,
    required this.serviceCenter,
    required this.onAppSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Navigation App',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Navigate to ${serviceCenter.name}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.map, color: Colors.blue),
            title: const Text('Google Maps'),
            subtitle: const Text('Default navigation app'),
            onTap: () => onAppSelected(NavigationApp.googleMaps),
          ),

          ListTile(
            leading: const Icon(Icons.map, color: Colors.grey),
            title: const Text('Apple Maps'),
            subtitle: const Text('iOS native navigation'),
            onTap: () => onAppSelected(NavigationApp.appleMaps),
          ),

          ListTile(
            leading: const Icon(Icons.navigation, color: Colors.purple),
            title: const Text('Waze'),
            subtitle: const Text('Community-based navigation'),
            onTap: () => onAppSelected(NavigationApp.waze),
          ),
        ],
      ),
    );
  }
}
