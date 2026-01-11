import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Advanced Vehicle Management System
class VehicleManagementSystem extends StatefulWidget {
  const VehicleManagementSystem({super.key});

  @override
  State<VehicleManagementSystem> createState() =>
      _VehicleManagementSystemState();
}

class _VehicleManagementSystemState extends State<VehicleManagementSystem>
    with TickerProviderStateMixin {
  late AnimationController _vehicleController;
  late Animation<double> _vehicleAnimation;

  // Vehicle data
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  final bool _isAddingVehicle = false;

  // Fleet management
  Map<String, FleetGroup> _fleetGroups = {};
  final List<VehicleComparison> _comparisons = [];

  // Real-time monitoring
  Timer? _monitoringTimer;
  final Map<String, VehicleStatus> _vehicleStatuses = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeVehicles();
    _startMonitoring();
  }

  void _setupAnimations() {
    _vehicleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _vehicleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _vehicleController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _initializeVehicles() {
    _vehicles = [
      Vehicle(
        id: 'vehicle_1',
        name: 'Tesla Model 3',
        make: 'Tesla',
        model: 'Model 3',
        year: 2023,
        vin: '5YJ3E1EA7JF000001',
        licensePlate: 'ABC-1234',
        color: 'Pearl White',
        fuelType: FuelType.electric,
        transmission: Transmission.automatic,
        mileage: 15420,
        purchaseDate: DateTime(2023, 6, 15),
        warrantyExpiry: DateTime(2026, 6, 15),
        insuranceProvider: 'Tesla Insurance',
        insuranceExpiry: DateTime(2024, 12, 31),
        lastService: DateTime(2024, 10, 15),
        nextServiceDue: DateTime(2025, 4, 15),
        healthScore: 0.92,
        imageUrl: 'assets/images/tesla_model3.jpg',
        features: ['Autopilot', 'Supercharger Access', 'Mobile App Control'],
        customizations: ['Tire Upgrade', 'Paint Protection'],
      ),
      Vehicle(
        id: 'vehicle_2',
        name: 'BMW X5',
        make: 'BMW',
        model: 'X5',
        year: 2022,
        vin: 'WBAWZ3C53NCK12345',
        licensePlate: 'XYZ-5678',
        color: 'Alpine White',
        fuelType: FuelType.gasoline,
        transmission: Transmission.automatic,
        mileage: 28150,
        purchaseDate: DateTime(2022, 3, 20),
        warrantyExpiry: DateTime(2025, 3, 20),
        insuranceProvider: 'Progressive',
        insuranceExpiry: DateTime(2024, 9, 15),
        lastService: DateTime(2024, 8, 10),
        nextServiceDue: DateTime(2025, 2, 10),
        healthScore: 0.78,
        imageUrl: 'assets/images/bmw_x5.jpg',
        features: ['All-Wheel Drive', 'Premium Sound', 'Heated Seats'],
        customizations: ['Roof Rack', 'Tinted Windows'],
      ),
    ];

    _selectedVehicle = _vehicles[0];

    // Initialize fleet groups
    _fleetGroups = {
      'personal': FleetGroup(
        id: 'personal',
        name: 'Personal Vehicles',
        description: 'Family cars and daily drivers',
        vehicles: [_vehicles[0].id, _vehicles[1].id],
        color: Colors.blue,
      ),
      'work': const FleetGroup(
        id: 'work',
        name: 'Work Vehicles',
        description: 'Company vehicles and business use',
        vehicles: [],
        color: Colors.green,
      ),
    };

    // Initialize vehicle statuses
    for (final vehicle in _vehicles) {
      _vehicleStatuses[vehicle.id] = VehicleStatus(
        vehicleId: vehicle.id,
        isOnline: Random().nextBool(),
        lastUpdate:
            DateTime.now().subtract(Duration(minutes: Random().nextInt(60))),
        location: 'Current Location',
        fuelLevel: Random().nextDouble() * 100,
        batteryLevel: vehicle.fuelType == FuelType.electric
            ? Random().nextDouble() * 100
            : null,
        engineRunning: Random().nextBool(),
        locked: Random().nextBool(),
        alarmActive: Random().nextDouble() < 0.1,
      );
    }
  }

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateVehicleStatuses();
      }
    });
  }

  void _updateVehicleStatuses() {
    setState(() {
      for (final vehicle in _vehicles) {
        final status = _vehicleStatuses[vehicle.id]!;
        // Simulate real-time updates
        status.lastUpdate = DateTime.now();
        status.fuelLevel = max(
          0,
          min(100, status.fuelLevel + (Random().nextDouble() - 0.5) * 5),
        );
        if (status.batteryLevel != null) {
          status.batteryLevel = max(
            0,
            min(
              100,
              status.batteryLevel! + (Random().nextDouble() - 0.5) * 3,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _monitoringTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddVehicleDialog,
            tooltip: 'Add Vehicle',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'compare':
                  _showVehicleComparison();
                  break;
                case 'groups':
                  _showFleetManagement();
                  break;
                case 'export':
                  _exportVehicleData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'compare',
                child: Text('Compare Vehicles'),
              ),
              const PopupMenuItem(
                value: 'groups',
                child: Text('Fleet Groups'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Data'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildVehicleSwitcher(),
          Expanded(
            child: _selectedVehicle != null
                ? _buildVehicleDetails(_selectedVehicle!)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSwitcher() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          final isSelected = vehicle.id == _selectedVehicle?.id;
          final status = _vehicleStatuses[vehicle.id];

          return AnimatedBuilder(
            animation: _vehicleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    isSelected ? 1.0 + (_vehicleAnimation.value * 0.05) : 1.0,
                child: GestureDetector(
                  onTap: () => _selectVehicle(vehicle),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Icon(
                              _getVehicleIcon(vehicle.fuelType),
                              size: 32,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            if (status?.isOnline == true)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vehicle.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: vehicle.healthScore,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getHealthColor(vehicle.healthScore),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVehicleDetails(Vehicle vehicle) {
    final status = _vehicleStatuses[vehicle.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle header
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getVehicleIcon(vehicle.fuelType),
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            Text(
                              '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatusIndicator(
                                  'Online',
                                  status?.isOnline ?? false,
                                  Colors.green,
                                ),
                                const SizedBox(width: 12),
                                _buildStatusIndicator(
                                  'Locked',
                                  status?.locked ?? true,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                _buildStatusIndicator(
                                  'Engine',
                                  status?.engineRunning ?? false,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Mileage',
                          '${vehicle.mileage.toStringAsFixed(0)} mi',
                          Icons.speed,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Health Score',
                          '${(vehicle.healthScore * 100).toInt()}%',
                          Icons.favorite,
                          _getHealthColor(vehicle.healthScore),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          vehicle.fuelType == FuelType.electric
                              ? 'Battery'
                              : 'Fuel',
                          vehicle.fuelType == FuelType.electric
                              ? '${status?.batteryLevel?.toStringAsFixed(0) ?? 0}%'
                              : '${status?.fuelLevel.toStringAsFixed(0) ?? 0}%',
                          vehicle.fuelType == FuelType.electric
                              ? Icons.battery_charging_full
                              : Icons.local_gas_station,
                          vehicle.fuelType == FuelType.electric
                              ? (status?.batteryLevel ?? 0) > 20
                                  ? Colors.green
                                  : Colors.red
                              : (status?.fuelLevel ?? 0) > 25
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Lock/Unlock',
                  Icons.lock,
                  () => _toggleVehicleLock(vehicle.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Start Engine',
                  Icons.power,
                  () => _toggleEngine(vehicle.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Find Location',
                  Icons.location_on,
                  () => _locateVehicle(vehicle.id),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Vehicle information
          _buildVehicleInfoSection(vehicle),

          const SizedBox(height: 24),

          // Maintenance schedule
          _buildMaintenanceSection(vehicle),

          const SizedBox(height: 24),

          // Features and customizations
          _buildFeaturesSection(vehicle),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No vehicle selected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showAddVehicleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool active, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? color : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? color : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoSection(Vehicle vehicle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('VIN', vehicle.vin),
            _buildInfoRow('License Plate', vehicle.licensePlate),
            _buildInfoRow('Color', vehicle.color),
            _buildInfoRow('Fuel Type', vehicle.fuelType.name.toUpperCase()),
            _buildInfoRow(
              'Transmission',
              vehicle.transmission.name.toUpperCase(),
            ),
            _buildInfoRow('Purchase Date', _formatDate(vehicle.purchaseDate)),
            _buildInfoRow(
              'Warranty Expires',
              _formatDate(vehicle.warrantyExpiry),
            ),
            _buildInfoRow(
              'Insurance',
              '${vehicle.insuranceProvider} (${_formatDate(vehicle.insuranceExpiry)})',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(Vehicle vehicle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Last Service', _formatDate(vehicle.lastService)),
            _buildInfoRow(
              'Next Service Due',
              _formatDate(vehicle.nextServiceDue),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _scheduleMaintenance(vehicle.id),
              icon: const Icon(Icons.schedule),
              label: const Text('Schedule Service'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(Vehicle vehicle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Features & Customizations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (vehicle.features.isNotEmpty) ...[
              const Text(
                'Standard Features',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vehicle.features.map((feature) {
                  return Chip(
                    label: Text(feature),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (vehicle.customizations.isNotEmpty) ...[
              const Text(
                'Customizations',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vehicle.customizations.map((customization) {
                  return Chip(
                    label: Text(customization),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() => _selectedVehicle = vehicle);
    _vehicleController.forward(from: 0.0);
  }

  void _showAddVehicleDialog() {
    // Implementation for adding new vehicle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add vehicle feature coming soon!')),
    );
  }

  void _showVehicleComparison() {
    // Implementation for vehicle comparison
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle comparison feature coming soon!')),
    );
  }

  void _showFleetManagement() {
    // Implementation for fleet management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fleet management feature coming soon!')),
    );
  }

  void _exportVehicleData() {
    // Implementation for data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export feature coming soon!')),
    );
  }

  void _toggleVehicleLock(String vehicleId) {
    setState(() {
      final status = _vehicleStatuses[vehicleId]!;
      status.locked = !status.locked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehicle ${(_vehicleStatuses[vehicleId]?.locked ?? true) ? 'locked' : 'unlocked'}',
        ),
      ),
    );
  }

  void _toggleEngine(String vehicleId) {
    setState(() {
      final status = _vehicleStatuses[vehicleId]!;
      status.engineRunning = !status.engineRunning;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Engine ${(_vehicleStatuses[vehicleId]?.engineRunning ?? false) ? 'started' : 'stopped'}',
        ),
      ),
    );
  }

  void _locateVehicle(String vehicleId) {
    final status = _vehicleStatuses[vehicleId];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vehicle located at: ${status?.location ?? 'Unknown'}'),
      ),
    );
  }

  void _scheduleMaintenance(String vehicleId) {
    // Implementation for scheduling maintenance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maintenance scheduling feature coming soon!'),
      ),
    );
  }

  IconData _getVehicleIcon(FuelType fuelType) {
    switch (fuelType) {
      case FuelType.gasoline:
        return Icons.local_gas_station;
      case FuelType.diesel:
        return Icons.local_shipping;
      case FuelType.electric:
        return Icons.electric_car;
      case FuelType.hybrid:
        return Icons.battery_charging_full;
    }
  }

  Color _getHealthColor(double health) {
    if (health >= 0.8) return Colors.green;
    if (health >= 0.6) return Colors.yellow;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// Data Models
enum FuelType { gasoline, diesel, electric, hybrid }

enum Transmission { manual, automatic, cvt }

class Vehicle {
  final String id;
  final String name;
  final String make;
  final String model;
  final int year;
  final String vin;
  final String licensePlate;
  final String color;
  final FuelType fuelType;
  final Transmission transmission;
  final int mileage;
  final DateTime purchaseDate;
  final DateTime warrantyExpiry;
  final String insuranceProvider;
  final DateTime insuranceExpiry;
  final DateTime lastService;
  final DateTime nextServiceDue;
  final double healthScore;
  final String imageUrl;
  final List<String> features;
  final List<String> customizations;

  const Vehicle({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.licensePlate,
    required this.color,
    required this.fuelType,
    required this.transmission,
    required this.mileage,
    required this.purchaseDate,
    required this.warrantyExpiry,
    required this.insuranceProvider,
    required this.insuranceExpiry,
    required this.lastService,
    required this.nextServiceDue,
    required this.healthScore,
    required this.imageUrl,
    required this.features,
    required this.customizations,
  });
}

class VehicleStatus {
  final String vehicleId;
  bool isOnline;
  DateTime lastUpdate;
  String location;
  double fuelLevel;
  double? batteryLevel;
  bool engineRunning;
  bool locked;
  bool alarmActive;

  VehicleStatus({
    required this.vehicleId,
    required this.isOnline,
    required this.lastUpdate,
    required this.location,
    required this.fuelLevel,
    this.batteryLevel,
    required this.engineRunning,
    required this.locked,
    required this.alarmActive,
  });
}

class FleetGroup {
  final String id;
  final String name;
  final String description;
  final List<String> vehicles;
  final Color color;

  const FleetGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.vehicles,
    required this.color,
  });
}

class VehicleComparison {
  final String id;
  final List<String> vehicleIds;
  final Map<String, dynamic> metrics;
  final DateTime createdAt;

  const VehicleComparison({
    required this.id,
    required this.vehicleIds,
    required this.metrics,
    required this.createdAt,
  });
}

