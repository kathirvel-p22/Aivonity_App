import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/offline/offline_manager.dart';
import '../../design_system/design_system.dart';
import 'offline_indicator.dart';

/// Widget for viewing vehicle data offline
class OfflineVehicleDataWidget extends StatefulWidget {
  final String vehicleId;
  final String dataType;

  const OfflineVehicleDataWidget({
    super.key,
    required this.vehicleId,
    required this.dataType,
  });

  @override
  State<OfflineVehicleDataWidget> createState() =>
      _OfflineVehicleDataWidgetState();
}

class _OfflineVehicleDataWidgetState extends State<OfflineVehicleDataWidget> {
  final OfflineManager _offlineManager = OfflineManager();

  List<VehicleDataPoint> _dataPoints = [];
  bool _isLoading = false;
  DateTime? _lastUpdate;
  String _selectedTimeRange = '24h';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final endTime = DateTime.now();
      final startTime = _getStartTimeForRange(_selectedTimeRange, endTime);

      final rawData = await _offlineManager.getOfflineVehicleData(
        vehicleId: widget.vehicleId,
        dataType: widget.dataType,
        startTime: startTime,
        endTime: endTime,
        limit: 1000,
      );

      setState(() {
        _dataPoints = rawData
            .map((data) => VehicleDataPoint.fromJson(data))
            .toList();
        _lastUpdate = rawData.isNotEmpty
            ? DateTime.fromMillisecondsSinceEpoch(rawData.first['timestamp'])
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  DateTime _getStartTimeForRange(String range, DateTime endTime) {
    switch (range) {
      case '1h':
        return endTime.subtract(const Duration(hours: 1));
      case '6h':
        return endTime.subtract(const Duration(hours: 6));
      case '24h':
        return endTime.subtract(const Duration(hours: 24));
      case '7d':
        return endTime.subtract(const Duration(days: 7));
      case '30d':
        return endTime.subtract(const Duration(days: 30));
      default:
        return endTime.subtract(const Duration(hours: 24));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline indicators
        const OfflineCapabilityIndicator(
          featureName: 'vehicle_data',
          requiredActions: ['view', 'export'],
        ),

        OfflineDataStatus(lastUpdate: _lastUpdate, dataType: widget.dataType),

        // Time range selector
        _buildTimeRangeSelector(),

        // Data visualization
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _dataPoints.isEmpty
              ? _buildEmptyState()
              : _buildDataVisualization(),
        ),

        // Data summary
        _buildDataSummary(),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: AivonitySpacing.paddingMD,
      child: Row(
        children: [
          Text('Time Range:', style: Theme.of(context).textTheme.titleSmall),
          AivonitySpacing.hGapMD,
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['1h', '6h', '24h', '7d', '30d'].map((range) {
                  final isSelected = _selectedTimeRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(range),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTimeRange = range);
                          _loadData();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
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
            Icons.data_usage_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AivonitySpacing.vGapMD,
          Text(
            'No ${widget.dataType} data available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          AivonitySpacing.vGapSM,
          Text(
            _offlineManager.isOffline
                ? 'Data will be available when your vehicle is connected and online'
                : 'Connect your vehicle to start collecting data',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataVisualization() {
    return Container(
      padding: AivonitySpacing.paddingMD,
      child: Column(
        children: [
          // Chart
          Expanded(flex: 3, child: _buildChart()),

          AivonitySpacing.vGapMD,

          // Recent values grid
          Expanded(flex: 1, child: _buildRecentValuesGrid()),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_dataPoints.isEmpty) return const SizedBox.shrink();

    final spots = _dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: spots.length / 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _dataPoints.length) return const Text('');
                final dataPoint = _dataPoints[value.toInt()];
                return Text(
                  _formatChartTime(dataPoint.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: null,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatValue(value),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
          ),
        ),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) * 0.9,
        maxY: spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentValuesGrid() {
    if (_dataPoints.isEmpty) return const SizedBox.shrink();

    final recentPoints = _dataPoints.take(6).toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: recentPoints.length,
      itemBuilder: (context, index) {
        final point = recentPoints[index];
        return AivonityCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatValue(point.value),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatTime(point.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataSummary() {
    if (_dataPoints.isEmpty) return const SizedBox.shrink();

    final values = _dataPoints.map((p) => p.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: AivonitySpacing.paddingMD,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Average', _formatValue(average)),
          _buildSummaryItem('Min', _formatValue(min)),
          _buildSummaryItem('Max', _formatValue(max)),
          _buildSummaryItem('Points', '${_dataPoints.length}'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _formatValue(double value) {
    switch (widget.dataType) {
      case 'speed':
        return '${value.toStringAsFixed(1)} mph';
      case 'fuel':
        return '${value.toStringAsFixed(1)}%';
      case 'temperature':
        return '${value.toStringAsFixed(1)}°F';
      case 'rpm':
        return '${value.toStringAsFixed(0)} RPM';
      default:
        return value.toStringAsFixed(2);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatChartTime(DateTime time) {
    switch (_selectedTimeRange) {
      case '1h':
      case '6h':
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      case '24h':
        return '${time.hour}:00';
      case '7d':
      case '30d':
        return '${time.month}/${time.day}';
      default:
        return '${time.hour}:00';
    }
  }
}

/// Vehicle data point model
class VehicleDataPoint {
  final String id;
  final String vehicleId;
  final DateTime timestamp;
  final String dataType;
  final double value;
  final Map<String, dynamic>? metadata;

  VehicleDataPoint({
    required this.id,
    required this.vehicleId,
    required this.timestamp,
    required this.dataType,
    required this.value,
    this.metadata,
  });

  factory VehicleDataPoint.fromJson(Map<String, dynamic> json) {
    final dataJson = Map<String, dynamic>.from(
      json['data_json'] is String
          ? Map<String, dynamic>.from(
              // Parse JSON string if needed
              {},
            )
          : json['data_json'] ?? {},
    );

    return VehicleDataPoint(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      dataType: json['data_type'] ?? '',
      value: (dataJson['value'] ?? 0).toDouble(),
      metadata: dataJson,
    );
  }
}

