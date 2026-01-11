import 'package:flutter/material.dart';
import 'dart:async';
import '../services/service_locator.dart';
import '../services/telemetry_service.dart';

class TelemetryDashboard extends StatefulWidget {
  const TelemetryDashboard({super.key});

  @override
  State<TelemetryDashboard> createState() => _TelemetryDashboardState();
}

class _TelemetryDashboardState extends State<TelemetryDashboard> {
  late TelemetryService _telemetryService;

  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _alertSubscription;

  TelemetryData? _currentTelemetry;
  List<VehicleAlert> _alerts = [];
  bool _isConnected = false;

  final String _testVehicleId = "test-vehicle-123";
  final String _testUserId = "test-user-456";

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _telemetryService = serviceLocator<TelemetryService>();

    // Subscribe to streams
    _telemetrySubscription = _telemetryService.telemetryStream.listen((
      telemetry,
    ) {
      if (mounted) {
        setState(() {
          _currentTelemetry = telemetry;
        });
      }
    });

    _connectionSubscription = _telemetryService.connectionStream.listen((
      connected,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    _alertSubscription = _telemetryService.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _alerts.insert(0, alert);
          // Keep only last 10 alerts
          if (_alerts.length > 10) {
            _alerts = _alerts.take(10).toList();
          }
        });
        _showAlertSnackBar(alert);
      }
    });
  }

  void _showAlertSnackBar(VehicleAlert alert) {
    final color = _getAlertColor(alert.severity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${alert.severity.toUpperCase()}: ${alert.message}'),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Acknowledge',
          textColor: Colors.white,
          onPressed: () => _acknowledgeAlert(alert.id),
        ),
      ),
    );
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Future<void> _connectToVehicle() async {
    try {
      await _telemetryService.subscribeToVehicle(_testVehicleId);
      await _telemetryService.subscribeToAlerts(_testUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to vehicle telemetry'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _telemetryService.disconnect();

      if (mounted) {
        setState(() {
          _currentTelemetry = null;
          _alerts.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from vehicle'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnect failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      await _telemetryService.acknowledgeAlert(alertId);

      setState(() {
        _alerts = _alerts.map((alert) {
          if (alert.id == alertId) {
            return VehicleAlert(
              id: alert.id,
              type: alert.type,
              severity: alert.severity,
              message: alert.message,
              timestamp: alert.timestamp,
              data: alert.data,
              acknowledged: true,
            );
          }
          return alert;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to acknowledge alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIVONITY Telemetry Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
            color: _isConnected ? Colors.green : Colors.red,
            onPressed: _isConnected ? _disconnect : _connectToVehicle,
            tooltip: _isConnected ? 'Disconnect' : 'Connect',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(),
            const SizedBox(height: 16),

            // Real-time Telemetry Card
            _buildTelemetryCard(),
            const SizedBox(height: 16),

            // Alerts Section
            _buildAlertsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isConnected ? null : _connectToVehicle,
        tooltip: 'Connect to Vehicle',
        child: const Icon(Icons.car_rental),
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connection Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected
                  ? 'Connected to vehicle $_testVehicleId'
                  : 'Disconnected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_currentTelemetry != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last update: ${_formatTimestamp(_currentTelemetry!.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Telemetry',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            if (_currentTelemetry == null) ...[
              const Center(child: Text('No telemetry data available')),
            ] else ...[
              // Engine Metrics
              _buildMetricRow(
                'Engine Temperature',
                '${_currentTelemetry!.engineMetrics['temperature'] ?? 0}°C',
              ),
              _buildMetricRow(
                'RPM',
                '${_currentTelemetry!.engineMetrics['rpm'] ?? 0}',
              ),
              _buildMetricRow(
                'Oil Pressure',
                '${_currentTelemetry!.engineMetrics['oil_pressure'] ?? 0} PSI',
              ),

              const Divider(),

              // Battery & Fuel
              _buildMetricRow(
                'Battery Level',
                '${_currentTelemetry!.batteryMetrics['level'] ?? 0}%',
              ),
              _buildMetricRow(
                'Fuel Level',
                '${_currentTelemetry!.fuelMetrics['level'] ?? 0}%',
              ),
              _buildMetricRow('Speed', '${_currentTelemetry!.speed} km/h'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_alerts.isNotEmpty)
                    Chip(
                      label: Text('${_alerts.length}'),
                      backgroundColor: Colors.red.shade100,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _alerts.isEmpty
                    ? const Center(child: Text('No alerts'))
                    : ListView.builder(
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return _buildAlertTile(alert);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertTile(VehicleAlert alert) {
    final color = _getAlertColor(alert.severity);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            _getAlertIcon(alert.severity),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(alert.message),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${alert.type}'),
            Text('Time: ${_formatTimestamp(alert.timestamp)}'),
          ],
        ),
        trailing: alert.acknowledged
            ? const Icon(Icons.check, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _acknowledgeAlert(alert.id),
                tooltip: 'Acknowledge',
              ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getAlertIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _connectionSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }
}
