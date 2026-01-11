import 'package:flutter/material.dart';
import 'dart:async';

/// Remote Control Screen for vehicle operations
class RemoteControlScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const RemoteControlScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  bool _isLocked = true;
  bool _engineRunning = false;
  bool _lightsOn = false;
  bool _hornActive = false;
  double _temperature = 72.0;
  bool _climateControlOn = false;
  bool _isLoading = false;

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        // Simulate real-time status updates
        setState(() {
          // Random status changes for demo
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.vehicleName} - Remote Control',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleStatus(),
            const SizedBox(height: 24),
            _buildSecurityControls(),
            const SizedBox(height: 24),
            _buildEngineControls(),
            const SizedBox(height: 24),
            _buildClimateControls(),
            const SizedBox(height: 24),
            _buildEmergencyControls(),
            const SizedBox(height: 24),
            _buildLocationServices(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: _isLocked ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vehicleName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isLocked ? 'Secured' : 'Unlocked',
                        style: TextStyle(
                          fontSize: 16,
                          color: _isLocked ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _engineRunning
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _engineRunning ? 'Running' : 'Off',
                    style: TextStyle(
                      color: _engineRunning ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator('Battery', '87%', Colors.green),
                _buildStatusIndicator('Fuel', '65%', Colors.orange),
                _buildStatusIndicator('Range', '280 mi', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildControlButton(
                    'Lock',
                    Icons.lock,
                    Colors.green,
                    _isLocked ? null : _toggleLock,
                    disabled: _isLocked,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlButton(
                    'Unlock',
                    Icons.lock_open,
                    Colors.red,
                    _isLocked ? _toggleLock : null,
                    disabled: !_isLocked,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildControlButton(
              'Panic Alarm',
              Icons.warning,
              Colors.red,
              _activatePanicAlarm,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engine Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildControlButton(
                    'Start Engine',
                    Icons.power,
                    Colors.blue,
                    !_engineRunning ? _toggleEngine : null,
                    disabled: _engineRunning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlButton(
                    'Stop Engine',
                    Icons.power_off,
                    Colors.grey,
                    _engineRunning ? _toggleEngine : null,
                    disabled: !_engineRunning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildControlButton(
                    'Lights',
                    _lightsOn ? Icons.lightbulb : Icons.lightbulb_outline,
                    Colors.yellow,
                    _toggleLights,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlButton(
                    'Horn',
                    Icons.volume_up,
                    Colors.orange,
                    _activateHorn,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Climate Control',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _climateControlOn,
                  onChanged: _toggleClimateControl,
                  activeThumbColor: Colors.blue,
                ),
              ],
            ),
            if (_climateControlOn) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  Text(
                    '${_temperature.round()}°F',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _temperature,
                    min: 60,
                    max: 85,
                    divisions: 25,
                    label: '${_temperature.round()}°F',
                    onChanged: (value) {
                      setState(() => _temperature = value);
                    },
                    onChangeEnd: _setTemperature,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => _adjustTemperature(-1),
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _adjustTemperature(1),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildControlButton(
                    'Roadside\nAssistance',
                    Icons.car_repair,
                    Colors.orange,
                    _callRoadsideAssistance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildControlButton(
                    'Emergency\nContact',
                    Icons.emergency,
                    Colors.red,
                    _callEmergency,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationServices() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildControlButton(
              'Find My Vehicle',
              Icons.location_on,
              Colors.blue,
              _locateVehicle,
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            _buildControlButton(
              'Send Location to Contacts',
              Icons.share_location,
              Colors.green,
              _shareLocation,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool disabled = false,
    bool fullWidth = false,
  }) {
    final button = ElevatedButton(
      onPressed: disabled || _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: disabled ? Colors.grey : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    return fullWidth ? button : Expanded(child: button);
  }

  Future<void> _executeCommand(String command, String successMessage) async {
    setState(() => _isLoading = true);

    // Simulate command execution
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
  }

  void _toggleLock() {
    _executeCommand(
      'toggle_lock',
      'Vehicle ${_isLocked ? 'unlocked' : 'locked'} successfully',
    );
    setState(() => _isLocked = !_isLocked);
  }

  void _toggleEngine() {
    _executeCommand(
      'toggle_engine',
      'Engine ${_engineRunning ? 'stopped' : 'started'} successfully',
    );
    setState(() => _engineRunning = !_engineRunning);
  }

  void _toggleLights() {
    _executeCommand(
      'toggle_lights',
      'Lights ${_lightsOn ? 'turned off' : 'turned on'}',
    );
    setState(() => _lightsOn = !_lightsOn);
  }

  void _activateHorn() {
    _executeCommand('horn', 'Horn activated');
    setState(() => _hornActive = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hornActive = false);
    });
  }

  void _activatePanicAlarm() {
    _executeCommand(
      'panic_alarm',
      'Panic alarm activated - help is on the way!',
    );
  }

  void _toggleClimateControl(bool value) {
    setState(() => _climateControlOn = value);
    _executeCommand(
      'climate_control',
      'Climate control ${value ? 'activated' : 'deactivated'}',
    );
  }

  void _setTemperature(double temperature) {
    _executeCommand(
      'set_temperature',
      'Temperature set to ${temperature.round()}°F',
    );
  }

  void _adjustTemperature(double delta) {
    final newTemp = (_temperature + delta).clamp(60.0, 85.0);
    setState(() => _temperature = newTemp);
    _setTemperature(newTemp);
  }

  void _callRoadsideAssistance() {
    _executeCommand(
      'roadside_assistance',
      'Roadside assistance has been notified',
    );
  }

  void _callEmergency() {
    _executeCommand('emergency', 'Emergency services have been contacted');
  }

  void _locateVehicle() {
    _executeCommand('locate', 'Vehicle location sent to your device');
  }

  void _shareLocation() {
    _executeCommand(
      'share_location',
      'Location shared with emergency contacts',
    );
  }
}

