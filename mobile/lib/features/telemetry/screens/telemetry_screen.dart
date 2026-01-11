import 'package:flutter/material.dart';

/// AIVONITY Telemetry Screen
/// Real-time vehicle telemetry and sensor data visualization
class TelemetryScreen extends StatefulWidget {
  final String? vehicleId;

  const TelemetryScreen({super.key, this.vehicleId});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRealTimeEnabled = true;

  // Mock telemetry data
  final Map<String, double> _telemetryData = {
    'engineTemp': 85.0,
    'oilPressure': 45.0,
    'batteryVoltage': 12.6,
    'fuelLevel': 75.0,
    'speed': 65.0,
    'rpm': 2500.0,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.repeat();
    _loadTelemetryData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadTelemetryData() {
    // Simulate real-time data updates
    if (_isRealTimeEnabled) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            // Simulate data changes
            _telemetryData['engineTemp'] =
                85.0 + (DateTime.now().millisecond % 10);
            _telemetryData['oilPressure'] =
                45.0 + (DateTime.now().millisecond % 5);
            _telemetryData['batteryVoltage'] =
                12.6 + (DateTime.now().millisecond % 2) * 0.1;
          });
          _loadTelemetryData(); // Continue updating
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 24),
              _buildGaugesGrid(),
              const SizedBox(height: 24),
              _buildChartsSection(),
              const SizedBox(height: 24),
              _buildSensorGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildRealTimeToggle(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: const Text('Vehicle Telemetry'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showTelemetrySettings(),
        ),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Real-time Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isRealTimeEnabled ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isRealTimeEnabled ? 'LIVE' : 'PAUSED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'All systems operational',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().toString().substring(11, 19)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildGaugeCard(
              'Engine Temp',
              _telemetryData['engineTemp']!,
              '°C',
              0,
              120,
              Colors.orange,
            ),
            _buildGaugeCard(
              'Oil Pressure',
              _telemetryData['oilPressure']!,
              'PSI',
              0,
              80,
              Colors.blue,
            ),
            _buildGaugeCard(
              'Battery',
              _telemetryData['batteryVoltage']!,
              'V',
              10,
              15,
              Colors.green,
            ),
            _buildGaugeCard(
              'Fuel Level',
              _telemetryData['fuelLevel']!,
              '%',
              0,
              100,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGaugeCard(
    String title,
    double value,
    String unit,
    double min,
    double max,
    Color color,
  ) {
    final percentage = (value - min) / (max - min);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withValues(alpha: 0.2),
                  ),
                ),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    );
                  },
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                      Text(
                        unit,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historical Data',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chart visualization coming soon',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Historical telemetry data will be displayed here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGrid() {
    final sensors = [
      {
        'name': 'Speed',
        'value': '${_telemetryData['speed']!.toInt()} mph',
        'icon': Icons.speed,
      },
      {
        'name': 'RPM',
        'value': '${_telemetryData['rpm']!.toInt()}',
        'icon': Icons.rotate_right,
      },
      {'name': 'Throttle', 'value': '45%', 'icon': Icons.local_gas_station},
      {'name': 'Brake', 'value': '0%', 'icon': Icons.disc_full},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Sensors',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: sensors.length,
          itemBuilder: (context, index) {
            final sensor = sensors[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    sensor['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          sensor['name'] as String,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        Text(
                          sensor['value'] as String,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRealTimeToggle() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _isRealTimeEnabled = !_isRealTimeEnabled;
        });
        if (_isRealTimeEnabled) {
          _loadTelemetryData();
        }
      },
      backgroundColor: _isRealTimeEnabled
          ? Theme.of(context).colorScheme.primary
          : Colors.grey,
      child: Icon(
        _isRealTimeEnabled ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh telemetry data
      _telemetryData['engineTemp'] = 85.0 + (DateTime.now().millisecond % 10);
      _telemetryData['oilPressure'] = 45.0 + (DateTime.now().millisecond % 5);
      _telemetryData['batteryVoltage'] =
          12.6 + (DateTime.now().millisecond % 2) * 0.1;
    });
  }

  void _showTelemetrySettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Rate'),
              subtitle: const Text('Change data update frequency'),
              onTap: () {
                Navigator.pop(context);
                _showRefreshRateDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download telemetry data'),
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('Telemetry information'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRefreshRateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refresh Rate'),
        content: const Text('Choose how often telemetry data updates'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Telemetry data export feature coming soon'),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telemetry Information'),
        content: const Text(
          'This screen displays real-time vehicle telemetry data including:\n\n'
          '• Engine temperature\n'
          '• Oil pressure\n'
          '• Battery voltage\n'
          '• Fuel level\n'
          '• Speed and RPM\n'
          '• Additional sensor data',
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
}

