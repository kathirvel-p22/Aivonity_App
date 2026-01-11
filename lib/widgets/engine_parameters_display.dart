import 'package:flutter/material.dart';
import 'dart:math' as math;

class EngineParametersDisplay extends StatefulWidget {
  final Map<String, dynamic> engineMetrics;
  final bool isOnline;
  final DateTime? lastUpdate;

  const EngineParametersDisplay({
    super.key,
    required this.engineMetrics,
    required this.isOnline,
    this.lastUpdate,
  });

  @override
  State<EngineParametersDisplay> createState() =>
      _EngineParametersDisplayState();
}

class _EngineParametersDisplayState extends State<EngineParametersDisplay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(EngineParametersDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engineMetrics != oldWidget.engineMetrics) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.engineering,
                  color: widget.isOnline ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Engine Parameters',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.lastUpdate != null)
                  Text(
                    _formatLastUpdate(widget.lastUpdate!),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Engine parameters grid
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Temperature and RPM
                  Row(
                    children: [
                      Expanded(child: _buildTemperatureGauge()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildRPMGauge()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Oil pressure and other metrics
                  Row(
                    children: [
                      Expanded(child: _buildOilPressureIndicator()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEngineStatusIndicator()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Additional metrics
                  _buildAdditionalMetrics(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureGauge() {
    final temperature = (widget.engineMetrics['temperature'] ?? 0.0).toDouble();
    final normalizedTemp = math.min(temperature / 120.0, 1.0); // Max 120°C

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTemperatureColor(temperature).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTemperatureColor(temperature).withValues(alpha:0.3),
        ),
      ),
      child: Column(
        children: [
          // Gauge
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: CircularGaugePainter(
                    value: normalizedTemp,
                    color: _getTemperatureColor(temperature),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${temperature.toInt()}°',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTemperatureColor(temperature),
                      ),
                    ),
                    const Text(
                      'TEMP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getTemperatureStatus(temperature),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getTemperatureColor(temperature),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRPMGauge() {
    final rpm = (widget.engineMetrics['rpm'] ?? 0.0).toDouble();
    final normalizedRPM = math.min(rpm / 8000.0, 1.0); // Max 8000 RPM

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRPMColor(rpm).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRPMColor(rpm).withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          // Gauge
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: CircularGaugePainter(
                    value: normalizedRPM,
                    color: _getRPMColor(rpm),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(rpm / 1000).toStringAsFixed(1)}k',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getRPMColor(rpm),
                      ),
                    ),
                    const Text(
                      'RPM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getRPMStatus(rpm),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getRPMColor(rpm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOilPressureIndicator() {
    final pressure = (widget.engineMetrics['oil_pressure'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getOilPressureColor(pressure).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getOilPressureColor(pressure).withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.oil_barrel,
            color: _getOilPressureColor(pressure),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oil Pressure',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${pressure.toStringAsFixed(1)} PSI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getOilPressureColor(pressure),
                  ),
                ),
                Text(
                  _getOilPressureStatus(pressure),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getOilPressureColor(pressure),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineStatusIndicator() {
    final isRunning = widget.engineMetrics['running'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isRunning ? Colors.green : Colors.grey).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isRunning ? Colors.green : Colors.grey).withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRunning ? Icons.play_circle_filled : Icons.stop_circle,
            color: isRunning ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Engine Status',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  isRunning ? 'RUNNING' : 'STOPPED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isRunning ? Colors.green : Colors.grey,
                  ),
                ),
                Text(
                  isRunning ? 'Normal operation' : 'Engine off',
                  style: TextStyle(
                    fontSize: 11,
                    color: isRunning ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalMetrics() {
    final metrics = [
      {
        'label': 'Coolant Level',
        'value': '${widget.engineMetrics['coolant_level'] ?? 85}%',
        'icon': Icons.thermostat,
        'color': Colors.blue,
      },
      {
        'label': 'Air Filter',
        'value': widget.engineMetrics['air_filter_status'] ?? 'Clean',
        'icon': Icons.air,
        'color': Colors.green,
      },
      {
        'label': 'Fuel Injection',
        'value': widget.engineMetrics['fuel_injection_status'] ?? 'Normal',
        'icon': Icons.local_gas_station,
        'color': Colors.orange,
      },
    ];

    return Column(
      children: metrics.map((metric) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                metric['icon'] as IconData,
                size: 16,
                color: metric['color'] as Color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric['label'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                metric['value'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: metric['color'] as Color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper methods for colors and status
  Color _getTemperatureColor(double temp) {
    if (temp > 110) return Colors.red;
    if (temp > 100) return Colors.orange;
    if (temp > 90) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getTemperatureStatus(double temp) {
    if (temp > 110) return 'CRITICAL';
    if (temp > 100) return 'HIGH';
    if (temp > 90) return 'WARM';
    return 'NORMAL';
  }

  Color _getRPMColor(double rpm) {
    if (rpm > 6000) return Colors.red;
    if (rpm > 4000) return Colors.orange;
    if (rpm > 2000) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getRPMStatus(double rpm) {
    if (rpm > 6000) return 'HIGH';
    if (rpm > 4000) return 'ELEVATED';
    if (rpm > 1000) return 'NORMAL';
    return 'IDLE';
  }

  Color _getOilPressureColor(double pressure) {
    if (pressure < 20) return Colors.red;
    if (pressure < 30) return Colors.orange;
    if (pressure > 70) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _getOilPressureStatus(double pressure) {
    if (pressure < 20) return 'LOW';
    if (pressure < 30) return 'BELOW NORMAL';
    if (pressure > 70) return 'HIGH';
    return 'NORMAL';
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    return '${difference.inHours}h ago';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class CircularGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  CircularGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, // Start angle
      math.pi * 1.5, // Sweep angle (270 degrees)
      false,
      backgroundPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 1.5 * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

