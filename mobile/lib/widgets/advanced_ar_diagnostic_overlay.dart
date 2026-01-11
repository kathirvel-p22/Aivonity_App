import 'package:flutter/material.dart';

/// Advanced AR Diagnostic Overlay
/// Provides augmented reality-style diagnostic information overlay
class AdvancedARDiagnosticOverlay extends StatefulWidget {
  final Map<String, dynamic> vehicleData;
  final VoidCallback? onClose;

  const AdvancedARDiagnosticOverlay({
    super.key,
    required this.vehicleData,
    this.onClose,
  });

  @override
  State<AdvancedARDiagnosticOverlay> createState() =>
      _AdvancedARDiagnosticOverlayState();
}

class _AdvancedARDiagnosticOverlayState
    extends State<AdvancedARDiagnosticOverlay> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showDetailedView = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Stack(
              children: [
                // Main diagnostic overlay
                Positioned.fill(
                  child: _buildDiagnosticOverlay(),
                ),

                // Close button
                Positioned(
                  top: 40,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.red,
                    onPressed: widget.onClose,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),

                // Toggle detailed view
                Positioned(
                  top: 100,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () =>
                        setState(() => _showDetailedView = !_showDetailedView),
                    child: Icon(
                      _showDetailedView
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticOverlay() {
    return Stack(
      children: [
        // Engine diagnostic hotspot
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: MediaQuery.of(context).size.width * 0.4,
          child: _buildDiagnosticHotspot(
            'Engine',
            (widget.vehicleData['engineHealth'] as double?) ?? 0.95,
            Icons.settings,
            Colors.blue,
            _showDetailedView,
          ),
        ),

        // Battery diagnostic hotspot
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: MediaQuery.of(context).size.width * 0.3,
          child: _buildDiagnosticHotspot(
            'Battery',
            (widget.vehicleData['batteryHealth'] as double?) ?? 0.87,
            Icons.battery_charging_full,
            Colors.green,
            _showDetailedView,
          ),
        ),

        // Transmission diagnostic hotspot
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.3,
          left: MediaQuery.of(context).size.width * 0.35,
          child: _buildDiagnosticHotspot(
            'Transmission',
            (widget.vehicleData['transmissionHealth'] as double?) ?? 0.92,
            Icons.drive_eta,
            Colors.orange,
            _showDetailedView,
          ),
        ),

        // Brakes diagnostic hotspot
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.35,
          right: MediaQuery.of(context).size.width * 0.35,
          child: _buildDiagnosticHotspot(
            'Brakes',
            (widget.vehicleData['brakeHealth'] as double?) ?? 0.88,
            Icons.stop,
            Colors.red,
            _showDetailedView,
          ),
        ),

        // Overall health indicator
        Positioned(
          top: 120,
          left: 20,
          child: _buildOverallHealthIndicator(),
        ),

        // Real-time metrics
        if (_showDetailedView)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: _buildRealTimeMetrics(),
          ),
      ],
    );
  }

  Widget _buildDiagnosticHotspot(
    String component,
    double health,
    IconData icon,
    Color color,
    bool showDetails,
  ) {
    final healthColor = health > 0.8
        ? Colors.green
        : health > 0.6
            ? Colors.yellow
            : Colors.red;

    return GestureDetector(
      onTap: () => _showComponentDetails(component, health),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: healthColor.withValues(alpha: 0.2),
          border: Border.all(color: healthColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: healthColor.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: healthColor, size: 24),
            const SizedBox(height: 2),
            Text(
              '${(health * 100).toInt()}%',
              style: TextStyle(
                color: healthColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallHealthIndicator() {
    final overallHealth =
        (widget.vehicleData['healthScore'] as double?) ?? 0.85;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Health',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: overallHealth,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    overallHealth > 0.8
                        ? Colors.green
                        : overallHealth > 0.6
                            ? Colors.yellow
                            : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(overallHealth * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getHealthStatus(overallHealth),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Real-time Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('Engine Temp', '85°C', Colors.blue),
              _buildMetricItem('Oil Pressure', '45 PSI', Colors.green),
              _buildMetricItem('Battery', '12.6V', Colors.yellow),
              _buildMetricItem('Fuel Level', '65%', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getHealthStatus(double health) {
    if (health >= 0.9) return 'Excellent';
    if (health >= 0.8) return 'Good';
    if (health >= 0.7) return 'Fair';
    if (health >= 0.6) return 'Needs Attention';
    return 'Critical';
  }

  void _showComponentDetails(String component, double health) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$component Diagnostics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health Score: ${(health * 100).toInt()}%'),
            const SizedBox(height: 8),
            Text('Status: ${_getHealthStatus(health)}'),
            const SizedBox(height: 8),
            Text('Last Checked: ${DateTime.now().toString().substring(0, 16)}'),
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_getComponentRecommendations(component, health)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Schedule maintenance
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Maintenance scheduled for $component')),
              );
            },
            child: const Text('Schedule Service'),
          ),
        ],
      ),
    );
  }

  String _getComponentRecommendations(String component, double health) {
    if (health > 0.8) {
      return 'Component is in good condition. Continue regular maintenance.';
    } else if (health > 0.6) {
      return 'Monitor this component closely. Schedule inspection soon.';
    } else {
      return 'Immediate attention required. Schedule service appointment.';
    }
  }
}

