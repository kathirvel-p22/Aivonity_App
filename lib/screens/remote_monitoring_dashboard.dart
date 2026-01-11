import 'package:flutter/material.dart';
import '../services/remote_monitoring_service.dart';
import '../widgets/connection_status_widget.dart';
import '../services/websocket_service.dart';
import 'dart:async';

class RemoteMonitoringDashboard extends StatefulWidget {
  final String vehicleId;

  const RemoteMonitoringDashboard({super.key, required this.vehicleId});

  @override
  State<RemoteMonitoringDashboard> createState() =>
      _RemoteMonitoringDashboardState();
}

class _RemoteMonitoringDashboardState extends State<RemoteMonitoringDashboard>
    with TickerProviderStateMixin {
  final RemoteMonitoringService _monitoringService = RemoteMonitoringService();

  late TabController _tabController;
  late StreamSubscription<LocationUpdate> _locationSubscription;
  late StreamSubscription<SecurityAlert> _securitySubscription;
  late StreamSubscription<DiagnosticResult> _diagnosticSubscription;
  late StreamSubscription<GeofenceAlert> _geofenceSubscription;

  LocationUpdate? _currentLocation;
  final List<SecurityAlert> _securityAlerts = [];
  final List<GeofenceAlert> _geofenceAlerts = [];
  DiagnosticResult? _latestDiagnostics;
  List<Geofence> _geofences = [];
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeMonitoring();
  }

  Future<void> _initializeMonitoring() async {
    try {
      await _monitoringService.initialize(widget.vehicleId);

      // Subscribe to streams
      _locationSubscription = _monitoringService.locationStream.listen((
        location,
      ) {
        setState(() {
          _currentLocation = location;
        });
      });

      _securitySubscription = _monitoringService.securityStream.listen((alert) {
        setState(() {
          _securityAlerts.insert(0, alert);
        });
        _showAlertDialog(alert);
      });

      _diagnosticSubscription = _monitoringService.diagnosticStream.listen((
        diagnostic,
      ) {
        setState(() {
          _latestDiagnostics = diagnostic;
        });
      });

      _geofenceSubscription = _monitoringService.geofenceStream.listen((alert) {
        setState(() {
          _geofenceAlerts.insert(0, alert);
        });
        _showGeofenceAlert(alert);
      });

      // Load existing geofences
      _loadGeofences();
    } catch (e) {
      debugPrint('Error initializing monitoring: $e');
      _showErrorSnackBar('Failed to initialize remote monitoring');
    }
  }

  void _loadGeofences() {
    setState(() {
      _geofences = _monitoringService.getGeofences();
    });
  }

  Future<void> _toggleMonitoring() async {
    try {
      if (_isMonitoring) {
        _monitoringService.stopMonitoring();
        setState(() {
          _isMonitoring = false;
        });
        _showSuccessSnackBar('Remote monitoring stopped');
      } else {
        await _monitoringService.startMonitoring();
        setState(() {
          _isMonitoring = true;
        });
        _showSuccessSnackBar('Remote monitoring started');
      }
    } catch (e) {
      debugPrint('Error toggling monitoring: $e');
      _showErrorSnackBar('Failed to toggle monitoring');
    }
  }

  void _showAlertDialog(SecurityAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.severity),
              color: _getAlertColor(alert.severity),
            ),
            const SizedBox(width: 8),
            Text('Security Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Type: ${alert.alertType}'),
            Text('Severity: ${alert.severity.toUpperCase()}'),
            if (alert.threats.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Threats:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...alert.threats.map((threat) => Text('• $threat')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGeofenceAlert(GeofenceAlert alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vehicle ${alert.alertType} ${alert.geofenceName}'),
        backgroundColor: alert.alertType == 'entered'
            ? Colors.green
            : Colors.orange,
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _tabController.animateTo(2), // Go to geofences tab
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  IconData _getAlertIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.notification_important;
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Monitoring'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.location_on), text: 'Location'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.fence), text: 'Geofences'),
            Tab(icon: Icon(Icons.build), text: 'Diagnostics'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleMonitoring,
            tooltip: _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocationTab(),
          _buildSecurityTab(),
          _buildGeofencesTab(),
          _buildDiagnosticsTab(),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConnectionStatusWidget(
            connectionState: _isMonitoring
                ? WebSocketState.connected
                : WebSocketState.disconnected,
            lastUpdate: _currentLocation?.timestamp,
            vehicleId: widget.vehicleId,
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_currentLocation != null) ...[
                    _buildLocationInfo(
                      'Latitude',
                      _currentLocation!.latitude.toStringAsFixed(6),
                    ),
                    _buildLocationInfo(
                      'Longitude',
                      _currentLocation!.longitude.toStringAsFixed(6),
                    ),
                    _buildLocationInfo(
                      'Accuracy',
                      '${_currentLocation!.accuracy.toStringAsFixed(1)}m',
                    ),
                    if (_currentLocation!.speed != null)
                      _buildLocationInfo(
                        'Speed',
                        '${(_currentLocation!.speed! * 3.6).toStringAsFixed(1)} km/h',
                      ),
                    if (_currentLocation!.heading != null)
                      _buildLocationInfo(
                        'Heading',
                        '${_currentLocation!.heading!.toStringAsFixed(0)}°',
                      ),
                    _buildLocationInfo(
                      'Last Update',
                      _formatDateTime(_currentLocation!.timestamp),
                    ),
                  ] else ...[
                    const Text('No location data available'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isMonitoring ? null : _toggleMonitoring,
                      child: const Text('Start Location Tracking'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitoring Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _isMonitoring ? Icons.check_circle : Icons.cancel,
                        color: _isMonitoring ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMonitoring ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: _isMonitoring ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_isMonitoring) ...[
                    const SizedBox(height: 8),
                    const Text('• Location tracking every 30 seconds'),
                    const Text('• Remote diagnostics every 5 minutes'),
                    const Text('• Security monitoring every 2 minutes'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: _securityAlerts.any((a) => a.severity == 'critical')
                        ? Colors.red
                        : Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _securityAlerts.isEmpty
                              ? 'All systems secure'
                              : '${_securityAlerts.length} alerts',
                          style: TextStyle(
                            color: _securityAlerts.isEmpty
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Recent Security Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_securityAlerts.isEmpty) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No security alerts'),
              ),
            ),
          ] else ...[
            ..._securityAlerts
                .take(10)
                .map(
                  (alert) => Card(
                    child: ListTile(
                      leading: Icon(
                        _getAlertIcon(alert.severity),
                        color: _getAlertColor(alert.severity),
                      ),
                      title: Text(alert.message),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${alert.alertType}'),
                          Text('Time: ${_formatDateTime(alert.timestamp)}'),
                          if (alert.threats.isNotEmpty)
                            Text('Threats: ${alert.threats.join(', ')}'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeofencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Geofences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddGeofenceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_geofences.isEmpty) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No geofences configured'),
              ),
            ),
          ] else ...[
            ..._geofences.map(
              (geofence) => Card(
                child: ListTile(
                  leading: Icon(
                    _getGeofenceIcon(geofence.type),
                    color: _getGeofenceColor(geofence.type),
                  ),
                  title: Text(geofence.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${geofence.type}'),
                      Text('Radius: ${geofence.radius.toStringAsFixed(0)}m'),
                      Text(
                        'Status: ${geofence.isVehicleInside ? 'Inside' : 'Outside'}',
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeGeofence(geofence.id),
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          const Text(
            'Recent Geofence Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_geofenceAlerts.isEmpty) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No geofence alerts'),
              ),
            ),
          ] else ...[
            ..._geofenceAlerts
                .take(5)
                .map(
                  (alert) => Card(
                    child: ListTile(
                      leading: Icon(
                        alert.alertType == 'entered'
                            ? Icons.login
                            : Icons.logout,
                        color: alert.alertType == 'entered'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: Text(
                        '${alert.alertType.toUpperCase()} ${alert.geofenceName}',
                      ),
                      subtitle: Text(_formatDateTime(alert.timestamp)),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Diagnostics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_latestDiagnostics != null) ...[
                    _buildDiagnosticInfo(
                      'Overall Health',
                      '${_latestDiagnostics!.overallHealth.toStringAsFixed(1)}%',
                    ),
                    _buildDiagnosticInfo(
                      'Battery Voltage',
                      '${_latestDiagnostics!.batteryVoltage.toStringAsFixed(1)}V',
                    ),
                    _buildDiagnosticInfo(
                      'Engine Temperature',
                      '${_latestDiagnostics!.engineTemperature}°C',
                    ),
                    _buildDiagnosticInfo(
                      'Oil Pressure',
                      '${_latestDiagnostics!.oilPressure} PSI',
                    ),
                    _buildDiagnosticInfo(
                      'Fuel Level',
                      '${_latestDiagnostics!.fuelLevel}%',
                    ),
                    if (_latestDiagnostics!.diagnosticCodes.isNotEmpty)
                      _buildDiagnosticInfo(
                        'Diagnostic Codes',
                        _latestDiagnostics!.diagnosticCodes.join(', '),
                      ),
                    _buildDiagnosticInfo(
                      'Last Update',
                      _formatDateTime(_latestDiagnostics!.timestamp),
                    ),
                  ] else ...[
                    const Text('No diagnostic data available'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDiagnosticInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  IconData _getGeofenceIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'service':
        return Icons.build;
      case 'restricted':
        return Icons.block;
      default:
        return Icons.place;
    }
  }

  Color _getGeofenceColor(String type) {
    switch (type) {
      case 'home':
        return Colors.green;
      case 'work':
        return Colors.blue;
      case 'service':
        return Colors.orange;
      case 'restricted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAddGeofenceDialog() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lonController = TextEditingController();
    final radiusController = TextEditingController(text: '100');
    String selectedType = 'home';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Geofence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: lonController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'home', child: Text('Home')),
                  DropdownMenuItem(value: 'work', child: Text('Work')),
                  DropdownMenuItem(value: 'service', child: Text('Service')),
                  DropdownMenuItem(
                    value: 'restricted',
                    child: Text('Restricted'),
                  ),
                ],
                onChanged: (value) => selectedType = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  latController.text.isNotEmpty &&
                  lonController.text.isNotEmpty) {
                try {
                  final geofence = Geofence(
                    id: 'geo_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    centerLatitude: double.parse(latController.text),
                    centerLongitude: double.parse(lonController.text),
                    radius: double.parse(radiusController.text),
                    type: selectedType,
                  );

                  await _monitoringService.addGeofence(geofence);
                  _loadGeofences();
                  if (mounted) {
                    Navigator.of(context).pop();
                    _showSuccessSnackBar('Geofence added successfully');
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('Invalid geofence data');
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeGeofence(String geofenceId) async {
    try {
      await _monitoringService.removeGeofence(geofenceId);
      _loadGeofences();
      _showSuccessSnackBar('Geofence removed successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to remove geofence');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationSubscription.cancel();
    _securitySubscription.cancel();
    _diagnosticSubscription.cancel();
    _geofenceSubscription.cancel();
    _monitoringService.dispose();
    super.dispose();
  }
}
