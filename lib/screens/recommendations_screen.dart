import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/location_recommendations.dart';
import '../models/service_center.dart';
import '../services/location_recommendations_service.dart';
import '../services/maps_service.dart';
import 'navigation_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with TickerProviderStateMixin {
  final LocationRecommendationsService _recommendationsService =
      GetIt.instance<LocationRecommendationsService>();
  final MapsService _mapsService = GetIt.instance<MapsService>();

  late TabController _tabController;

  List<RouteRecommendation> _gpsRecommendations = [];
  List<SmartRecommendation> _smartRecommendations = [];
  List<FavoriteLocation> _favoriteLocations = [];
  Coordinates? _userLocation;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current location
      _userLocation = await _mapsService.getCurrentLocation();

      // Create sample vehicle context for demonstration
      final vehicleContext = VehicleContext(
        vehicleId: 'vehicle_001',
        fuelLevel: 0.3, // 30% fuel
        mileage: 45000,
        lastServiceDate: DateTime.now().subtract(const Duration(days: 90)),
        upcomingMaintenanceItems: ['Oil Change', 'Tire Rotation'],
        currentIssues: [],
        vehicleType: 'sedan',
      );

      // Load GPS-based recommendations
      final gpsRecs = await _recommendationsService.getGPSBasedRecommendations(
        currentLocation: _userLocation!,
        vehicleContext: vehicleContext,
      );

      // Load smart recommendations
      final smartRecs = await _recommendationsService.getSmartRecommendations(
        currentLocation: _userLocation!,
        vehicleContext: vehicleContext,
      );

      // Load favorite locations
      final favorites = _recommendationsService.getFavoriteLocations();

      setState(() {
        _gpsRecommendations = gpsRecs;
        _smartRecommendations = smartRecs;
        _favoriteLocations = favorites;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Nearby'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Smart'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPreferencesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFavoriteDialog,
        tooltip: 'Add Favorite Location',
        child: const Icon(Icons.add_location),
      ),
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
            Text('Loading recommendations...'),
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
              onPressed: _loadRecommendations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildGPSRecommendationsTab(),
        _buildSmartRecommendationsTab(),
        _buildFavoritesTab(),
      ],
    );
  }

  Widget _buildGPSRecommendationsTab() {
    if (_gpsRecommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No nearby recommendations found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _gpsRecommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _gpsRecommendations[index];
        return RecommendationCard(
          recommendation: recommendation,
          onTap: () => _navigateToServiceCenter(recommendation.serviceCenter),
          onAddToFavorites: () =>
              _addServiceCenterToFavorites(recommendation.serviceCenter),
        );
      },
    );
  }

  Widget _buildSmartRecommendationsTab() {
    if (_smartRecommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No smart recommendations available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _smartRecommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _smartRecommendations[index];
        return SmartRecommendationCard(
          recommendation: recommendation,
          onActionTap: (action) =>
              _handleSmartRecommendationAction(recommendation, action),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteLocations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No favorite locations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add favorites',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteLocations.length,
      itemBuilder: (context, index) {
        final favorite = _favoriteLocations[index];
        return FavoriteLocationCard(
          favorite: favorite,
          userLocation: _userLocation,
          onNavigate: () => _navigateToFavorite(favorite),
          onEdit: () => _editFavorite(favorite),
          onDelete: () => _deleteFavorite(favorite),
        );
      },
    );
  }

  void _navigateToServiceCenter(ServiceCenter serviceCenter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            NavigationScreen(selectedServiceCenter: serviceCenter),
      ),
    );
  }

  void _navigateToFavorite(FavoriteLocation favorite) {
    // Create a temporary service center for navigation
    final serviceCenter = ServiceCenter(
      id: favorite.id,
      name: favorite.name,
      address: favorite.address,
      latitude: favorite.location.latitude,
      longitude: favorite.location.longitude,
      services: [],
      rating: 0.0,
      reviewCount: 0,
      phoneNumber: '',
      email: '',
      workingHours: [],
      isOpen: true,
      distanceKm: 0.0,
      estimatedWaitTimeMinutes: 0,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            NavigationScreen(selectedServiceCenter: serviceCenter),
      ),
    );
  }

  Future<void> _addServiceCenterToFavorites(ServiceCenter serviceCenter) async {
    await _recommendationsService.addFavoriteLocation(
      name: serviceCenter.name,
      location: Coordinates(
        latitude: serviceCenter.latitude,
        longitude: serviceCenter.longitude,
      ),
      address: serviceCenter.address,
      category: 'service_center',
      notes: 'Added from recommendations',
      tags: serviceCenter.services,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${serviceCenter.name} added to favorites'),
          backgroundColor: Colors.green,
        ),
      );
    }

    _loadRecommendations();
  }

  void _handleSmartRecommendationAction(
    SmartRecommendation recommendation,
    String action,
  ) {
    switch (action.toLowerCase()) {
      case 'find fuel station':
      case 'find service center':
      case 'find emergency service':
        _loadRecommendations();
        break;
      case 'navigate to location':
        if (recommendation.serviceCenter != null) {
          _navigateToServiceCenter(recommendation.serviceCenter!);
        } else if (recommendation.favoriteLocation != null) {
          _navigateToFavorite(recommendation.favoriteLocation!);
        }
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action: $action')));
    }
  }

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => RecommendationPreferencesDialog(
        currentPreferences: _recommendationsService.getPreferences(),
        onSave: (preferences) async {
          await _recommendationsService.updatePreferences(preferences);
          _loadRecommendations();
        },
      ),
    );
  }

  void _showAddFavoriteDialog() {
    if (_userLocation == null) return;

    showDialog(
      context: context,
      builder: (context) => AddFavoriteDialog(
        currentLocation: _userLocation!,
        onSave: (name, category, notes, tags) async {
          await _recommendationsService.addFavoriteLocation(
            name: name,
            location: _userLocation!,
            address: 'Current Location',
            category: category,
            notes: notes,
            tags: tags,
          );
          _loadRecommendations();
        },
      ),
    );
  }

  void _editFavorite(FavoriteLocation favorite) {
    // TODO: Implement edit favorite dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit favorite - Coming soon')),
    );
  }

  Future<void> _deleteFavorite(FavoriteLocation favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Favorite'),
        content: Text('Are you sure you want to delete "${favorite.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recommendationsService.removeFavoriteLocation(favorite.id);
      _loadRecommendations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${favorite.name} deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class RecommendationCard extends StatelessWidget {
  final RouteRecommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onAddToFavorites;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.onAddToFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final serviceCenter = recommendation.serviceCenter;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      serviceCenter.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      color: _getRecommendationTypeColor(
                        recommendation.recommendationType,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recommendation.recommendationType.toUpperCase(),
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

              // Relevance score
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Relevance: ${(recommendation.relevanceScore * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${recommendation.distanceFromRoute.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reasons
              Text(
                'Why recommended:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...recommendation.reasons.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reason,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onAddToFavorites,
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Add to Favorites',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRecommendationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'on_route':
        return Colors.green;
      case 'nearby':
        return Colors.blue;
      case 'preferred':
        return Colors.purple;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class SmartRecommendationCard extends StatelessWidget {
  final SmartRecommendation recommendation;
  final Function(String) onActionTap;

  const SmartRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: recommendation.isUrgent ? Colors.red[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(recommendation.category),
                  color: recommendation.isUrgent ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: recommendation.isUrgent ? Colors.red[700] : null,
                    ),
                  ),
                ),
                if (recommendation.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
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
              recommendation.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Priority indicator
            Row(
              children: [
                Text(
                  'Priority: ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: recommendation.priority,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getPriorityColor(recommendation.priority),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(recommendation.priority * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: recommendation.actionItems.map((action) {
                return ElevatedButton(
                  onPressed: () => onActionTap(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recommendation.isUrgent
                        ? Colors.red
                        : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(action),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance':
        return Icons.build;
      case 'fuel':
        return Icons.local_gas_station;
      case 'emergency':
        return Icons.warning;
      case 'convenience':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }

  Color _getPriorityColor(double priority) {
    if (priority >= 0.8) return Colors.red;
    if (priority >= 0.6) return Colors.orange;
    if (priority >= 0.4) return Colors.yellow;
    return Colors.green;
  }
}

class FavoriteLocationCard extends StatelessWidget {
  final FavoriteLocation favorite;
  final Coordinates? userLocation;
  final VoidCallback? onNavigate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FavoriteLocationCard({
    super.key,
    required this.favorite,
    this.userLocation,
    this.onNavigate,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final distance = userLocation != null
        ? _calculateDistance(userLocation!, favorite.location)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCategoryIcon(favorite.category)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    favorite.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              favorite.address,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            if (distance != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${distance.toStringAsFixed(1)} km away',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],

            if (favorite.notes != null && favorite.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                favorite.notes!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],

            if (favorite.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: favorite.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue[50],
                    labelStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation),
              label: const Text('Navigate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'service_center':
        return Icons.build;
      case 'fuel_station':
        return Icons.local_gas_station;
      case 'parking':
        return Icons.local_parking;
      case 'custom':
        return Icons.place;
      default:
        return Icons.location_on;
    }
  }

  double _calculateDistance(Coordinates point1, Coordinates point2) {
    // Simple distance calculation (you might want to use a more accurate method)
    final lat1 = point1.latitude * (3.14159 / 180);
    final lat2 = point2.latitude * (3.14159 / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (3.14159 / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (3.14159 / 180);

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);

    final c = 2 * asin(sqrt(a));

    return 6371 * c; // Earth's radius in km
  }
}

// Placeholder dialogs - these would be implemented with full functionality
class RecommendationPreferencesDialog extends StatelessWidget {
  final RecommendationPreferences currentPreferences;
  final Function(RecommendationPreferences) onSave;

  const RecommendationPreferencesDialog({
    super.key,
    required this.currentPreferences,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recommendation Preferences'),
      content: const Text('Preferences dialog - Coming soon'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onSave(currentPreferences);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AddFavoriteDialog extends StatelessWidget {
  final Coordinates currentLocation;
  final Function(String, String, String?, List<String>) onSave;

  const AddFavoriteDialog({
    super.key,
    required this.currentLocation,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Favorite Location'),
      content: const Text('Add favorite dialog - Coming soon'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onSave('Current Location', 'custom', 'Added manually', []);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

