import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/navigation.dart';
import '../models/service_center.dart';

class RoutePlanner extends StatefulWidget {
  final List<ServiceCenterRoute> routes;
  final Function(ServiceCenterRoute)? onRouteSelected;
  final Function(ServiceCenter)? onNavigatePressed;
  final Coordinates? userLocation;

  const RoutePlanner({
    super.key,
    required this.routes,
    this.onRouteSelected,
    this.onNavigatePressed,
    this.userLocation,
  });

  @override
  State<RoutePlanner> createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner> {
  ServiceCenterRoute? _selectedRoute;
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.routes.isNotEmpty) {
      _selectedRoute = widget.routes.first;
      _updateMapElements();
    }
  }

  @override
  void didUpdateWidget(RoutePlanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routes != widget.routes) {
      if (widget.routes.isNotEmpty) {
        _selectedRoute = widget.routes.first;
        _updateMapElements();
      }
    }
  }

  void _updateMapElements() {
    if (_selectedRoute == null) return;

    final Set<Polyline> polylines = {};
    final Set<Marker> markers = {};

    // Add route polyline
    final polylinePoints = _selectedRoute!.route.polylinePoints
        .map((coord) => LatLng(coord.latitude, coord.longitude))
        .toList();

    polylines.add(
      Polyline(
        polylineId: PolylineId(_selectedRoute!.route.routeId),
        points: polylinePoints,
        color: Colors.blue,
        width: 5,
        patterns: [],
      ),
    );

    // Add user location marker
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            widget.userLocation!.latitude,
            widget.userLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Starting point',
          ),
        ),
      );
    }

    // Add destination marker
    final serviceCenter = _selectedRoute!.serviceCenter;
    markers.add(
      Marker(
        markerId: MarkerId(serviceCenter.id),
        position: LatLng(serviceCenter.latitude, serviceCenter.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: serviceCenter.name,
          snippet: 'Destination • ${serviceCenter.rating}⭐',
        ),
      ),
    );

    setState(() {
      _polylines = polylines;
      _markers = markers;
    });

    // Fit map to show entire route
    _fitMapToRoute();
  }

  void _fitMapToRoute() async {
    if (_mapController == null || _selectedRoute == null) return;

    final route = _selectedRoute!.route;
    final bounds = _calculateBounds([
      route.startLocation,
      route.endLocation,
      ...route.polylinePoints,
    ]);

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds(List<Coordinates> coordinates) {
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      minLat = minLat < coord.latitude ? minLat : coord.latitude;
      maxLat = maxLat > coord.latitude ? maxLat : coord.latitude;
      minLng = minLng < coord.longitude ? minLng : coord.longitude;
      maxLng = maxLng > coord.longitude ? maxLng : coord.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routes.isEmpty) {
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

    return Column(
      children: [
        // Route selection tabs
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: widget.routes.length,
            itemBuilder: (context, index) {
              final route = widget.routes[index];
              final isSelected = route == _selectedRoute;

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 8),
                child: RouteCard(
                  route: route,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedRoute = route;
                    });
                    _updateMapElements();
                    widget.onRouteSelected?.call(route);
                  },
                  onNavigate: () {
                    widget.onNavigatePressed?.call(route.serviceCenter);
                  },
                ),
              );
            },
          ),
        ),

        // Map view
        Expanded(
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _updateMapElements();
            },
            initialCameraPosition: CameraPosition(
              target: widget.userLocation != null
                  ? LatLng(
                      widget.userLocation!.latitude,
                      widget.userLocation!.longitude,
                    )
                  : LatLng(37.7749, -122.4194),
              zoom: 12.0,
            ),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: true,
          ),
        ),

        // Route details panel
        if (_selectedRoute != null)
          RouteDetailsPanel(
            route: _selectedRoute!,
            onNavigate: () {
              widget.onNavigatePressed?.call(_selectedRoute!.serviceCenter);
            },
          ),
      ],
    );
  }
}

class RouteCard extends StatelessWidget {
  final ServiceCenterRoute route;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;

  const RouteCard({
    super.key,
    required this.route,
    required this.isSelected,
    this.onTap,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.blue[50] : null,
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
                      route.serviceCenter.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue[700] : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getTrafficColor(route.trafficCondition),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      route.trafficCondition.toUpperCase(),
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
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    route.route.formattedDuration,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    route.route.formattedDistance,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.local_gas_station,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${route.fuelCostEstimate.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'ETA: ${_formatTime(route.estimatedArrival)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTrafficColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'light':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'heavy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class RouteDetailsPanel extends StatelessWidget {
  final ServiceCenterRoute route;
  final VoidCallback? onNavigate;

  const RouteDetailsPanel({super.key, required this.route, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route to ${route.serviceCenter.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route.route.summary,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                context,
                Icons.access_time,
                'Duration',
                route.route.formattedDuration,
              ),
              _buildInfoItem(
                context,
                Icons.straighten,
                'Distance',
                route.route.formattedDistance,
              ),
              _buildInfoItem(
                context,
                Icons.local_gas_station,
                'Fuel Cost',
                '\$${route.fuelCostEstimate.toStringAsFixed(2)}',
              ),
              _buildInfoItem(
                context,
                Icons.schedule,
                'ETA',
                _formatTime(route.estimatedArrival),
              ),
            ],
          ),
          if (route.route.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Route Warnings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...route.route.warnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $warning',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

