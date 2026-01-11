import 'package:flutter/material.dart';
import 'dart:async';
import '../services/service_locator.dart';
import '../services/telemetry_service.dart';
import '../services/websocket_service.dart';
import '../services/alert_service.dart';
import '../widgets/vehicle_health_score.dart';
import '../widgets/engine_parameters_display.dart';
import '../widgets/connection_status_widget.dart';

class ComprehensiveTelemetryDashboard extends StatefulWidget {
  const ComprehensiveTelemetryDashboard({super.key});

  @override
  State<ComprehensiveTelemetryDashboard> createState() =>
      _ComprehensiveTelemetryDashboardState();
}

class _ComprehensiveTelemetryDashboardState
    extends State<ComprehensiveTelemetryDashboard>
    with TickerProviderStateMixin {
  late TelemetryService _telemetryService;
  late WebSocketService _webSocketService;
  late AlertService _alertService;
  late TabController _tabController;

  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _alertSubscription;

  TelemetryData? _currentTelemetry;
  List<VehicleAlert> _alerts = [];
  WebSocketState _connectionState = WebSocketState.disconnected;

  final String _testVehicleId = "test-vehicle-123";
  final String _testUserId = "test-user-456";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  void _initializeServices() {
    _telemetryService = serviceLocator<TelemetryService>();
    _webSocketService = serviceLocator<WebSocketService>();
    _alertService = serviceLocator<AlertService>();

    // Initialize alert service
    _alertService.initialize();

    // Subscribe to telemetry updates
    _telemetrySubscription = _telemetryService.telemetryStream.listen((
      telemetry,
    ) {
      if (mounted) {
        setState(() {
          _currentTelemetry = telemetry;
        });
      }
    });

    // Subscribe to connection state changes
    _connectionSubscription = _webSocketService.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
      }
    });

    // Subscribe to alerts
    _alertSubscription = _telemetryService.alertStream.listen((alert) {
      if (mounted) {
        setState(() {
          _alerts.insert(0, alert);
          // Keep only last 20 alerts
          if (_alerts.length > 20) {
            _alerts = _alerts.take(20).toList();
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
        content: Row(
          children: [
            Icon(_getAlertIcon(alert.severity), color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${alert.severity.toUpperCase()} ALERT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(alert.message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'ACK',
          textColor: Colors.white,
          onPressed: () => _acknowledgeAlert(alert.id),
        ),
      ),
    );
  }

  Future<void> _connectToVehicle() async {
    try {
      await _telemetryService.subscribeToVehicle(_testVehicleId);
      await _telemetryService.subscribeToAlerts(_testUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connected to vehicle telemetry'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connection failed: $e'),
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
            content: Text('🔌 Disconnected from vehicle'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Disconnect failed: $e'),
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
        title: const Text('AIVONITY Vehicle Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.engineering), text: 'Engine'),
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _connectionState == WebSocketState.connected
                  ? Icons.wifi
                  : Icons.wifi_off,
              color: _connectionState == WebSocketState.connected
                  ? Colors.green
                  : Colors.red,
            ),
            onPressed: _connectionState == WebSocketState.connected
                ? _disconnect
                : _connectToVehicle,
            tooltip: _connectionState == WebSocketState.connected
                ? 'Disconnect'
                : 'Connect',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildEngineTab(), _buildAlertsTab()],
      ),
      floatingActionButton: _connectionState != WebSocketState.connected
          ? FloatingActionButton.extended(
              onPressed: _connectToVehicle,
              icon: const Icon(Icons.car_rental),
              label: const Text('Connect Vehicle'),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Connection Status
          ConnectionStatusWidget(
            connectionState: _connectionState,
            lastUpdate: _currentTelemetry?.timestamp,
            vehicleId: _testVehicleId,
            onReconnect: _connectToVehicle,
            onDisconnect: _disconnect,
          ),

          const SizedBox(height: 16),

          // Vehicle Health Score
          VehicleHealthScore(
            healthScore: _calculateHealthScore(),
            isOnline: _connectionState == WebSocketState.connected,
            lastUpdate: _currentTelemetry?.timestamp,
            vehicleId: _testVehicleId,
          ),

          const SizedBox(height: 16),

          // Quick Stats
          _buildQuickStats(),

          const SizedBox(height: 16),

          // Recent Alerts Summary
          _buildRecentAlertsSummary(),
        ],
      ),
    );
  }

  Widget _buildEngineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Engine Parameters Display
          EngineParametersDisplay(
            engineMetrics: _currentTelemetry?.engineMetrics ?? {},
            isOnline: _connectionState == WebSocketState.connected,
            lastUpdate: _currentTelemetry?.timestamp,
          ),

          const SizedBox(height: 16),

          // Additional Engine Metrics
          _buildAdditionalEngineMetrics(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      children: [
        // Alerts header
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle Alerts',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_alerts.isNotEmpty)
                Chip(
                  label: Text(
                    '${_alerts.where((a) => !a.acknowledged).length}',
                  ),
                  backgroundColor: Colors.red.shade100,
                ),
            ],
          ),
        ),

        // Alerts list
        Expanded(
          child: _alerts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text('Your vehicle is running smoothly'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return _buildAlertCard(alert);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    if (_currentTelemetry == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No telemetry data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Speed',
                    '${_currentTelemetry!.speed.toStringAsFixed(1)} km/h',
                    Icons.speed,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Battery',
                    '${_currentTelemetry!.batteryMetrics['level'] ?? 0}%',
                    Icons.battery_full,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Fuel',
                    '${_currentTelemetry!.fuelMetrics['level'] ?? 0}%',
                    Icons.local_gas_station,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Engine Temp',
                    '${_currentTelemetry!.engineMetrics['temperature'] ?? 0}°C',
                    Icons.thermostat,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildRecentAlertsSummary() {
    final recentAlerts = _alerts.take(3).toList();

    return Card(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_alerts.isNotEmpty)
                  TextButton(
                    onPressed: () => _tabController.animateTo(2),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (recentAlerts.isEmpty)
              const Center(child: Text('No recent alerts'))
            else
              ...recentAlerts.map((alert) => _buildAlertSummaryTile(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSummaryTile(VehicleAlert alert) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: _getAlertColor(alert.severity),
        child: Icon(
          _getAlertIcon(alert.severity),
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(alert.message, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        _formatTimestamp(alert.timestamp),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: alert.acknowledged
          ? const Icon(Icons.check, color: Colors.green, size: 16)
          : null,
    );
  }

  Widget _buildAdditionalEngineMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostic Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_currentTelemetry?.diagnosticCodes.isNotEmpty == true) ...[
              Text(
                'Active Diagnostic Codes:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _currentTelemetry!.diagnosticCodes.map((code) {
                  return Chip(
                    label: Text(code),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No diagnostic codes detected',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(VehicleAlert alert) {
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
        title: Text(
          alert.message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${alert.type}'),
            Text('Severity: ${alert.severity.toUpperCase()}'),
            Text('Time: ${_formatTimestamp(alert.timestamp)}'),
          ],
        ),
        trailing: alert.acknowledged
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _acknowledgeAlert(alert.id),
                tooltip: 'Acknowledge',
              ),
        isThreeLine: true,
      ),
    );
  }

  double _calculateHealthScore() {
    if (_currentTelemetry == null) return 0.0;

    // Simple health score calculation based on various metrics
    double score = 1.0;

    // Engine temperature factor
    final temp = _currentTelemetry!.engineMetrics['temperature'] ?? 90.0;
    if (temp > 110) {
      score -= 0.3;
    } else if (temp > 100) {
      score -= 0.1;
    }

    // Oil pressure factor
    final pressure = _currentTelemetry!.engineMetrics['oil_pressure'] ?? 40.0;
    if (pressure < 20) {
      score -= 0.4;
    } else if (pressure < 30) {
      score -= 0.2;
    }

    // Battery level factor
    final batteryLevel = _currentTelemetry!.batteryMetrics['level'] ?? 80.0;
    if (batteryLevel < 20) {
      score -= 0.2;
    } else if (batteryLevel < 40) {
      score -= 0.1;
    }

    // Diagnostic codes factor
    if (_currentTelemetry!.diagnosticCodes.isNotEmpty) {
      score -= 0.2 * _currentTelemetry!.diagnosticCodes.length;
    }

    return (score * 100).clamp(0.0, 100.0) / 100.0;
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
    _tabController.dispose();
    super.dispose();
  }
}
