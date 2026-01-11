import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/service_center.dart';
import '../services/maps_service.dart';
import '../widgets/service_center_map.dart';
import 'navigation_screen.dart';

class ServiceCenterFinderScreen extends StatefulWidget {
  const ServiceCenterFinderScreen({super.key});

  @override
  State<ServiceCenterFinderScreen> createState() =>
      _ServiceCenterFinderScreenState();
}

class _ServiceCenterFinderScreenState extends State<ServiceCenterFinderScreen> {
  final MapsService _mapsService = GetIt.instance<MapsService>();

  List<ServiceCenter> _serviceCenters = [];
  Coordinates? _userLocation;
  bool _isLoading = false;
  String? _error;
  ServiceCenterFilter _currentFilter = const ServiceCenterFilter();

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndSearch();
  }

  Future<void> _loadUserLocationAndSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _userLocation = await _mapsService.getCurrentLocation();
      await _searchServiceCenters();
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

  Future<void> _searchServiceCenters() async {
    if (_userLocation == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final centers = await _mapsService.findServiceCenters(
        location: _userLocation!,
        radiusKm: _currentFilter.maxDistanceKm ?? 50.0,
        filter: _currentFilter,
      );

      setState(() {
        _serviceCenters = centers;
      });
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceCenterFilterSheet(
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          _searchServiceCenters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Service Centers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _serviceCenters.isNotEmpty ? _planRoutes : null,
            tooltip: 'Plan Routes',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserLocationAndSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search results summary
          if (_serviceCenters.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Found ${_serviceCenters.length} service centers nearby',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),

          // Map view
          Expanded(child: _buildMapContent()),

          // Service centers list
          if (_serviceCenters.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: _serviceCenters.length,
                itemBuilder: (context, index) {
                  final center = _serviceCenters[index];
                  return ServiceCenterCard(
                    serviceCenter: center,
                    onTap: () => _onServiceCenterSelected(center),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding service centers...'),
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
              onPressed: _loadUserLocationAndSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ServiceCenterMap(
      serviceCenters: _serviceCenters,
      userLocation: _userLocation,
      onServiceCenterTap: _onServiceCenterSelected,
    );
  }

  void _onServiceCenterSelected(ServiceCenter serviceCenter) {
    // Handle service center selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${serviceCenter.name}'),
        action: SnackBarAction(
          label: 'Navigate',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    NavigationScreen(selectedServiceCenter: serviceCenter),
              ),
            );
          },
        ),
      ),
    );
  }

  void _planRoutes() {
    if (_serviceCenters.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NavigationScreen(serviceCenters: _serviceCenters),
      ),
    );
  }
}

class ServiceCenterCard extends StatelessWidget {
  final ServiceCenter serviceCenter;
  final VoidCallback? onTap;

  const ServiceCenterCard({super.key, required this.serviceCenter, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        serviceCenter.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: serviceCenter.isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        serviceCenter.isOpen ? 'Open' : 'Closed',
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
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${serviceCenter.rating}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${serviceCenter.distanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  serviceCenter.address,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: serviceCenter.services.take(3).map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service,
                        style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                      ),
                    );
                  }).toList(),
                ),
                if (serviceCenter.services.length > 3)
                  Text(
                    '+${serviceCenter.services.length - 3} more',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceCenterFilterSheet extends StatefulWidget {
  final ServiceCenterFilter currentFilter;
  final Function(ServiceCenterFilter) onFilterChanged;

  const ServiceCenterFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<ServiceCenterFilterSheet> createState() =>
      _ServiceCenterFilterSheetState();
}

class _ServiceCenterFilterSheetState extends State<ServiceCenterFilterSheet> {
  late double _maxDistance;
  late double _minRating;
  late bool _openNow;
  late String _sortBy;
  late List<String> _selectedServices;

  final List<String> _availableServices = [
    'General Repair',
    'Oil Change',
    'Brake Service',
    'Tire Service',
    'Battery Service',
    'AC Repair',
    'Engine Diagnostics',
    'Transmission Service',
    'Car Wash',
    'Inspection',
  ];

  final List<String> _sortOptions = ['distance', 'rating', 'wait_time'];

  @override
  void initState() {
    super.initState();
    _maxDistance = widget.currentFilter.maxDistanceKm ?? 50.0;
    _minRating = widget.currentFilter.minRating ?? 0.0;
    _openNow = widget.currentFilter.openNow ?? false;
    _sortBy = widget.currentFilter.sortBy ?? 'distance';
    _selectedServices = List.from(widget.currentFilter.requiredServices ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
                    'Filter Service Centers',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Distance filter
                  Text(
                    'Maximum Distance: ${_maxDistance.toInt()} km',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rating filter
                  Text(
                    'Minimum Rating: ${_minRating.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _minRating = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Open now filter
                  SwitchListTile(
                    title: const Text('Open Now'),
                    subtitle: const Text(
                      'Show only currently open service centers',
                    ),
                    value: _openNow,
                    onChanged: (value) {
                      setState(() {
                        _openNow = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sort by
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(_getSortDisplayName(option)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Services filter
                  Text(
                    'Required Services',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _availableServices.map((service) {
                      final isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        label: Text(service),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              _selectedServices.remove(service);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          child: const Text('Apply Filters'),
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

  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'distance':
        return 'Distance';
      case 'rating':
        return 'Rating';
      case 'wait_time':
        return 'Wait Time';
      default:
        return sortBy;
    }
  }

  void _resetFilters() {
    setState(() {
      _maxDistance = 50.0;
      _minRating = 0.0;
      _openNow = false;
      _sortBy = 'distance';
      _selectedServices.clear();
    });
  }

  void _applyFilters() {
    final filter = ServiceCenterFilter(
      maxDistanceKm: _maxDistance,
      minRating: _minRating > 0 ? _minRating : null,
      openNow: _openNow ? true : null,
      sortBy: _sortBy,
      requiredServices: _selectedServices.isNotEmpty ? _selectedServices : null,
    );

    widget.onFilterChanged(filter);
    Navigator.of(context).pop();
  }
}
