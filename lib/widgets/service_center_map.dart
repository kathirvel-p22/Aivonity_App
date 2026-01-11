import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/service_center.dart';
import '../screens/navigation_screen.dart';
import '../screens/booking_screen.dart';

class ServiceCenterMap extends StatefulWidget {
  final List<ServiceCenter> serviceCenters;
  final Coordinates? userLocation;
  final Function(ServiceCenter)? onServiceCenterTap;
  final Function(LatLng)? onMapTap;
  final double initialZoom;

  const ServiceCenterMap({
    super.key,
    required this.serviceCenters,
    this.userLocation,
    this.onServiceCenterTap,
    this.onMapTap,
    this.initialZoom = 12.0,
  });

  @override
  State<ServiceCenterMap> createState() => _ServiceCenterMapState();
}

class _ServiceCenterMapState extends State<ServiceCenterMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(ServiceCenterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceCenters != widget.serviceCenters ||
        oldWidget.userLocation != widget.userLocation) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    final Set<Marker> markers = {};

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
            snippet: 'Current position',
          ),
        ),
      );
    }

    // Add service center markers
    for (final serviceCenter in widget.serviceCenters) {
      markers.add(
        Marker(
          markerId: MarkerId(serviceCenter.id),
          position: LatLng(serviceCenter.latitude, serviceCenter.longitude),
          icon: _getMarkerIcon(serviceCenter),
          infoWindow: InfoWindow(
            title: serviceCenter.name,
            snippet:
                '${serviceCenter.rating}⭐ • ${serviceCenter.distanceKm.toStringAsFixed(1)}km',
            onTap: () => _showServiceCenterDetails(serviceCenter),
          ),
          onTap: () {
            widget.onServiceCenterTap?.call(serviceCenter);
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  BitmapDescriptor _getMarkerIcon(ServiceCenter serviceCenter) {
    // Different marker colors based on rating and availability
    if (!serviceCenter.isOpen) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else if (serviceCenter.rating >= 4.5) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (serviceCenter.rating >= 4.0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _showServiceCenterDetails(ServiceCenter serviceCenter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ServiceCenterDetailsSheet(serviceCenter: serviceCenter),
    );
  }

  LatLng _getInitialCameraPosition() {
    if (widget.userLocation != null) {
      return LatLng(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
      );
    } else if (widget.serviceCenters.isNotEmpty) {
      return LatLng(
        widget.serviceCenters.first.latitude,
        widget.serviceCenters.first.longitude,
      );
    } else {
      // Default to a central location
      return const LatLng(37.7749, -122.4194); // San Francisco
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
      },
      initialCameraPosition: CameraPosition(
        target: _getInitialCameraPosition(),
        zoom: widget.initialZoom,
      ),
      markers: _markers,
      onTap: widget.onMapTap,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: true,
    );
  }

  Future<void> animateToLocation(
    Coordinates location, {
    double zoom = 15.0,
  }) async {
    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: zoom,
          ),
        ),
      );
    }
  }

  Future<void> fitBounds(List<ServiceCenter> centers) async {
    if (_controller == null || centers.isEmpty) return;

    double minLat = centers.first.latitude;
    double maxLat = centers.first.latitude;
    double minLng = centers.first.longitude;
    double maxLng = centers.first.longitude;

    for (final center in centers) {
      minLat = minLat < center.latitude ? minLat : center.latitude;
      maxLat = maxLat > center.latitude ? maxLat : center.latitude;
      minLng = minLng < center.longitude ? minLng : center.longitude;
      maxLng = maxLng > center.longitude ? maxLng : center.longitude;
    }

    // Include user location in bounds if available
    if (widget.userLocation != null) {
      minLat = minLat < widget.userLocation!.latitude
          ? minLat
          : widget.userLocation!.latitude;
      maxLat = maxLat > widget.userLocation!.latitude
          ? maxLat
          : widget.userLocation!.latitude;
      minLng = minLng < widget.userLocation!.longitude
          ? minLng
          : widget.userLocation!.longitude;
      maxLng = maxLng > widget.userLocation!.longitude
          ? maxLng
          : widget.userLocation!.longitude;
    }

    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }
}

class ServiceCenterDetailsSheet extends StatelessWidget {
  final ServiceCenter serviceCenter;

  const ServiceCenterDetailsSheet({super.key, required this.serviceCenter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
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

                  // Service center name and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          serviceCenter.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: serviceCenter.isOpen
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          serviceCenter.isOpen ? 'Open' : 'Closed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating and distance
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${serviceCenter.rating} (${serviceCenter.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${serviceCenter.distanceKm.toStringAsFixed(1)} km away',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          serviceCenter.address,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Services
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: serviceCenter.services.map((service) {
                      return Chip(
                        label: Text(service),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(color: Colors.blue[700]),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Wait time
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated wait: ${serviceCenter.estimatedWaitTimeMinutes} minutes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: serviceCenter.phoneNumber.isNotEmpty
                              ? () {
                                  // TODO: Implement phone call
                                }
                              : null,
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => NavigationScreen(
                                  selectedServiceCenter: serviceCenter,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Navigate'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookingScreen(serviceCenter: serviceCenter),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Book'),
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
}

