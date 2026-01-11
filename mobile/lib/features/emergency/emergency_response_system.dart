import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/enhanced_location_service.dart';

/// Advanced Emergency Response Integration System with Enhanced Location Sharing
class EmergencyResponseSystem extends ConsumerStatefulWidget {
  const EmergencyResponseSystem({super.key});

  @override
  ConsumerState<EmergencyResponseSystem> createState() =>
      _EmergencyResponseSystemState();
}

class _EmergencyResponseSystemState extends ConsumerState<EmergencyResponseSystem>
    with TickerProviderStateMixin {
  late AnimationController _emergencyController;
  late Animation<double> _emergencyAnimation;

  // Emergency state
  EmergencyStatus _emergencyStatus = EmergencyStatus.standby;
  EmergencyType? _activeEmergency;
  List<EmergencyContact> _emergencyContacts = [];
  List<EmergencyProtocol> _activeProtocols = [];
  Map<String, dynamic> _emergencyData = {};

  // Response systems
  bool _autoEmergencyCall = true;
  bool _locationSharing = true;
  bool _vehicleDataTransmission = true;
  bool _medicalInfoSharing = false;

  // Real-time monitoring
  Timer? _monitoringTimer;
  StreamSubscription? _sensorSubscription;

  // Emergency history
  List<EmergencyIncident> _incidentHistory = [];

  // Enhanced location service
  late EnhancedLocationService _locationService;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeEmergencySystem();
    _initializeLocationService();
    _startEmergencyMonitoring();
  }

  void _initializeLocationService() {
    _locationService = ref.read(enhancedLocationServiceProvider);
    _locationService.initialize();
  }

  void _setupAnimations() {
    _emergencyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _emergencyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _emergencyController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeEmergencySystem() {
    _emergencyContacts = [
      const EmergencyContact(
        id: 'contact_1',
        name: 'Emergency Services',
        phoneNumber: '911',
        type: ContactType.emergency,
        priority: 1,
        autoCall: true,
      ),
      const EmergencyContact(
        id: 'contact_2',
        name: 'Roadside Assistance',
        phoneNumber: '1-800-HELP',
        type: ContactType.roadside,
        priority: 2,
        autoCall: false,
      ),
      const EmergencyContact(
        id: 'contact_3',
        name: 'Emergency Contact',
        phoneNumber: '+1-555-0123',
        type: ContactType.personal,
        priority: 3,
        autoCall: true,
      ),
    ];

    _incidentHistory = [
      EmergencyIncident(
        id: 'incident_1',
        type: EmergencyType.breakdown,
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        location: 'Highway 101, Mile 45',
        responseTime: 15,
        resolution: 'Tow service dispatched',
        severity: IncidentSeverity.low,
      ),
      EmergencyIncident(
        id: 'incident_2',
        type: EmergencyType.medical,
        timestamp: DateTime.now().subtract(const Duration(days: 15)),
        location: 'Downtown Medical Center',
        responseTime: 8,
        resolution: 'Medical assistance provided',
        severity: IncidentSeverity.medium,
      ),
    ];

    _emergencyData = {
      'vehicleLocation': {'lat': 37.7749, 'lng': -122.4194},
      'vehicleSpeed': 0.0,
      'impactDetected': false,
      'airbagDeployed': false,
      'fuelLevel': 0.25,
      'batteryVoltage': 12.1,
      'lastUpdate': DateTime.now(),
    };
  }

  void _startEmergencyMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _monitorEmergencyConditions();
      }
    });
  }

  void _monitorEmergencyConditions() {
    // Simulate emergency condition detection
    final random = Random();
    final crashDetected = random.nextDouble() < 0.001; // Very rare
    final breakdownDetected = random.nextDouble() < 0.005; // Rare
    final medicalEmergency = random.nextDouble() < 0.0005; // Extremely rare

    if (crashDetected) {
      _triggerEmergency(EmergencyType.crash);
    } else if (breakdownDetected) {
      _triggerEmergency(EmergencyType.breakdown);
    } else if (medicalEmergency) {
      _triggerEmergency(EmergencyType.medical);
    }

    // Update emergency data
    setState(() {
      _emergencyData['vehicleSpeed'] = 25.0 + random.nextDouble() * 30.0;
      _emergencyData['lastUpdate'] = DateTime.now();
    });
  }

  void _triggerEmergency(EmergencyType type) {
    if (_emergencyStatus != EmergencyStatus.standby) return;

    setState(() {
      _emergencyStatus = EmergencyStatus.active;
      _activeEmergency = type;
    });

    _emergencyController.repeat(reverse: true);

    // Execute emergency protocols
    _executeEmergencyProtocols(type);

    // Auto-call emergency services if enabled
    if (_autoEmergencyCall) {
      final emergencyContact = _emergencyContacts.firstWhere(
        (contact) => contact.type == ContactType.emergency,
        orElse: () => _emergencyContacts.first,
      );
      _callEmergencyContact(emergencyContact);
    }

    // Show emergency dialog
    _showEmergencyDialog(type);
  }

  void _executeEmergencyProtocols(EmergencyType type) {
    _activeProtocols = [];

    switch (type) {
      case EmergencyType.crash:
        _activeProtocols.addAll([
          const EmergencyProtocol(
            id: 'protocol_1',
            name: 'Crash Response',
            description: 'Deploy airbags, cut fuel, unlock doors',
            status: ProtocolStatus.executing,
            priority: 1,
          ),
          const EmergencyProtocol(
            id: 'protocol_2',
            name: 'Emergency Broadcast',
            description: 'Send location and vehicle data to emergency services',
            status: ProtocolStatus.executing,
            priority: 1,
          ),
        ]);
        _shareEmergencyLocation(type);
        break;

      case EmergencyType.breakdown:
        _activeProtocols.add(
          const EmergencyProtocol(
            id: 'protocol_3',
            name: 'Breakdown Assistance',
            description: 'Contact roadside assistance and provide location',
            status: ProtocolStatus.executing,
            priority: 2,
          ),
        );
        _shareEmergencyLocation(type);
        break;

      case EmergencyType.medical:
        _activeProtocols.addAll([
          const EmergencyProtocol(
            id: 'protocol_4',
            name: 'Medical Emergency',
            description: 'Contact emergency services with medical information',
            status: ProtocolStatus.executing,
            priority: 1,
          ),
          const EmergencyProtocol(
            id: 'protocol_5',
            name: 'Vehicle Safety',
            description:
                'Enable hazard lights and prepare for medical response',
            status: ProtocolStatus.executing,
            priority: 2,
          ),
        ]);
        _shareEmergencyLocation(type);
        break;

      case EmergencyType.fire:
        _activeProtocols.add(
          const EmergencyProtocol(
            id: 'protocol_6',
            name: 'Fire Response',
            description: 'Activate fire suppression and emergency evacuation',
            status: ProtocolStatus.executing,
            priority: 1,
          ),
        );
        _shareEmergencyLocation(type);
        break;
    }
  }

  /// Share emergency location with enhanced functionality
  void _shareEmergencyLocation(EmergencyType type) async {
    if (!_locationSharing) return;

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        _showErrorSnackBar('Unable to get current location');
        return;
      }

      // Create emergency message
      final emergencyMessages = {
        EmergencyType.crash: 'Vehicle crash detected',
        EmergencyType.breakdown: 'Vehicle breakdown assistance needed',
        EmergencyType.medical: 'Medical emergency',
        EmergencyType.fire: 'Vehicle fire emergency',
      };

      final message = emergencyMessages[type] ?? 'Emergency situation';
      
      // Share with emergency contacts
      await _locationService.shareLocationWithEmergencyContacts(
        emergencyType: message,
        customMessage: '$message - Immediate assistance required',
      );

      // Update emergency data with real location
      setState(() {
        _emergencyData['vehicleLocation'] = {
          'lat': position.latitude,
          'lng': position.longitude,
          'accuracy': position.accuracy,
          'address': _locationService.currentAddress,
        };
      });

      _showSuccessSnackBar('Emergency location shared successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to share location: ${e.toString()}');
    }
  }

  /// Manual location sharing
  void _manualLocationSharing() async {
    try {
      await _locationService.shareCurrentLocation(
        message: 'Sharing my location from AIVONITY Vehicle Assistant',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share location: ${e.toString()}');
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _callEmergencyContact(EmergencyContact contact) {
    // Simulate emergency call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${contact.name}...'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEmergencyDialog(EmergencyType type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(_getEmergencyTitle(type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getEmergencyMessage(type)),
            const SizedBox(height: 16),
            const Text(
              'Emergency protocols activated:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._activeProtocols.map(
              (protocol) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      _getProtocolStatusIcon(protocol.status),
                      size: 16,
                      color: _getProtocolStatusColor(protocol.status),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        protocol.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel Alert'),
          ),
          ElevatedButton(
            onPressed: _resolveEmergency,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Emergency Resolved'),
          ),
        ],
      ),
    );
  }

  void _resolveEmergency() {
    setState(() {
      _emergencyStatus = EmergencyStatus.resolved;
      _activeEmergency = null;
      _activeProtocols.clear();
    });

    _emergencyController.stop();
    _emergencyController.value = 0.0;

    Navigator.of(context).pop();

    // Add to incident history
    final incident = EmergencyIncident(
      id: 'incident_${DateTime.now().millisecondsSinceEpoch}',
      type: _activeEmergency!,
      timestamp: DateTime.now(),
      location: 'Current Location',
      responseTime: 5 + Random().nextInt(15),
      resolution: 'Emergency resolved by user',
      severity: IncidentSeverity.low,
    );

    setState(() {
      _incidentHistory.insert(0, incident);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency resolved. System returning to standby.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _emergencyController.dispose();
    _monitoringTimer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Response'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_emergencyStatus == EmergencyStatus.active)
            AnimatedBuilder(
              animation: _emergencyAnimation,
              builder: (context, child) {
                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        Colors.red.withValues(alpha: _emergencyAnimation.value),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyStatus(),
            const SizedBox(height: 24),
            _buildEmergencyControls(),
            const SizedBox(height: 24),
            _buildEmergencyContacts(),
            const SizedBox(height: 24),
            _buildActiveProtocols(),
            const SizedBox(height: 24),
            _buildIncidentHistory(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _manualEmergencyTrigger,
        backgroundColor: Colors.red,
        tooltip: 'Manual Emergency',
        child: const Icon(Icons.warning),
      ),
    );
  }

  Widget _buildEmergencyStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getEmergencyStatusIcon(_emergencyStatus),
                  size: 28,
                  color: _getEmergencyStatusColor(_emergencyStatus),
                ),
                const SizedBox(width: 12),
                Text(
                  'System Status: ${_getEmergencyStatusText(_emergencyStatus)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_activeEmergency != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getEmergencyTitle(_activeEmergency!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'Emergency response protocols active',
                            style: TextStyle(
                              color: Colors.red.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusMetric('Monitoring', 'Active', Colors.green),
                _buildStatusMetric('Response Time', '< 5s', Colors.blue),
                _buildStatusMetric('Coverage', '24/7', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Emergency Call'),
              subtitle: const Text('Automatically call emergency services'),
              value: _autoEmergencyCall,
              onChanged: (value) => setState(() => _autoEmergencyCall = value),
            ),
            SwitchListTile(
              title: const Text('Location Sharing'),
              subtitle: const Text('Share location with emergency services'),
              value: _locationSharing,
              onChanged: (value) => setState(() => _locationSharing = value),
            ),
            SwitchListTile(
              title: const Text('Vehicle Data Transmission'),
              subtitle: const Text('Send vehicle diagnostics to responders'),
              value: _vehicleDataTransmission,
              onChanged: (value) =>
                  setState(() => _vehicleDataTransmission = value),
            ),
            SwitchListTile(
              title: const Text('Medical Information Sharing'),
              subtitle:
                  const Text('Share medical info with emergency services'),
              value: _medicalInfoSharing,
              onChanged: (value) => setState(() => _medicalInfoSharing = value),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _manualLocationSharing,
              icon: const Icon(Icons.share_location),
              label: const Text('Share Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._emergencyContacts.map(
          (contact) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    _getContactTypeColor(contact.type).withValues(alpha: 0.1),
                child: Icon(
                  _getContactTypeIcon(contact.type),
                  color: _getContactTypeColor(contact.type),
                ),
              ),
              title: Text(contact.name),
              subtitle: Text(contact.phoneNumber),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (contact.autoCall)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Auto',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () => _callEmergencyContact(contact),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveProtocols() {
    if (_activeProtocols.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No active emergency protocols',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Emergency Protocols',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._activeProtocols.map(
          (protocol) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getProtocolStatusColor(protocol.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getProtocolStatusIcon(protocol.status),
                      color: _getProtocolStatusColor(protocol.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          protocol.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          protocol.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getProtocolStatusColor(protocol.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getProtocolStatusText(protocol.status),
                      style: TextStyle(
                        color: _getProtocolStatusColor(protocol.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._incidentHistory.map(
          (incident) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getEmergencyTypeIcon(incident.type),
                        color: _getIncidentSeverityColor(incident.severity),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getEmergencyTypeText(incident.type),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getIncidentSeverityColor(incident.severity)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          incident.severity.name.toUpperCase(),
                          style: TextStyle(
                            color: _getIncidentSeverityColor(incident.severity),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    incident.location,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${incident.timestamp.day}/${incident.timestamp.month}/${incident.timestamp.year}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Response: ${incident.responseTime}min',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Resolution: ${incident.resolution}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMetric(String label, String value, Color color) {
    return Column(
      children: [
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
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _manualEmergencyTrigger() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Emergency'),
        content: const Text('Select the type of emergency:'),
        actions: [
          ...EmergencyType.values.map(
            (type) => TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _triggerEmergency(type);
              },
              child: Text(_getEmergencyTypeText(type)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getEmergencyStatusIcon(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.standby:
        return Icons.shield;
      case EmergencyStatus.active:
        return Icons.warning;
      case EmergencyStatus.resolved:
        return Icons.check_circle;
    }
  }

  Color _getEmergencyStatusColor(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.standby:
        return Colors.green;
      case EmergencyStatus.active:
        return Colors.red;
      case EmergencyStatus.resolved:
        return Colors.blue;
    }
  }

  String _getEmergencyStatusText(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.standby:
        return 'Standby';
      case EmergencyStatus.active:
        return 'Active Emergency';
      case EmergencyStatus.resolved:
        return 'Resolved';
    }
  }

  String _getEmergencyTitle(EmergencyType type) {
    switch (type) {
      case EmergencyType.crash:
        return 'Vehicle Crash Detected!';
      case EmergencyType.breakdown:
        return 'Vehicle Breakdown';
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.fire:
        return 'Vehicle Fire';
    }
  }

  String _getEmergencyMessage(EmergencyType type) {
    switch (type) {
      case EmergencyType.crash:
        return 'A crash has been detected. Emergency services have been notified.';
      case EmergencyType.breakdown:
        return 'Vehicle breakdown detected. Roadside assistance is being contacted.';
      case EmergencyType.medical:
        return 'Medical emergency detected. Emergency services are being dispatched.';
      case EmergencyType.fire:
        return 'Vehicle fire detected. Emergency response protocols activated.';
    }
  }

  IconData _getEmergencyTypeIcon(EmergencyType type) {
    switch (type) {
      case EmergencyType.crash:
        return Icons.car_crash;
      case EmergencyType.breakdown:
        return Icons.car_repair;
      case EmergencyType.medical:
        return Icons.medical_services;
      case EmergencyType.fire:
        return Icons.fire_truck;
    }
  }

  String _getEmergencyTypeText(EmergencyType type) {
    switch (type) {
      case EmergencyType.crash:
        return 'Vehicle Crash';
      case EmergencyType.breakdown:
        return 'Breakdown';
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.fire:
        return 'Fire Emergency';
    }
  }

  Color _getIncidentSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.yellow;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.red;
    }
  }

  Color _getContactTypeColor(ContactType type) {
    switch (type) {
      case ContactType.emergency:
        return Colors.red;
      case ContactType.roadside:
        return Colors.blue;
      case ContactType.personal:
        return Colors.green;
    }
  }

  IconData _getContactTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.emergency:
        return Icons.local_hospital;
      case ContactType.roadside:
        return Icons.car_repair;
      case ContactType.personal:
        return Icons.person;
    }
  }

  IconData _getProtocolStatusIcon(ProtocolStatus status) {
    switch (status) {
      case ProtocolStatus.pending:
        return Icons.schedule;
      case ProtocolStatus.executing:
        return Icons.play_arrow;
      case ProtocolStatus.completed:
        return Icons.check_circle;
      case ProtocolStatus.failed:
        return Icons.error;
    }
  }

  Color _getProtocolStatusColor(ProtocolStatus status) {
    switch (status) {
      case ProtocolStatus.pending:
        return Colors.grey;
      case ProtocolStatus.executing:
        return Colors.blue;
      case ProtocolStatus.completed:
        return Colors.green;
      case ProtocolStatus.failed:
        return Colors.red;
    }
  }

  String _getProtocolStatusText(ProtocolStatus status) {
    switch (status) {
      case ProtocolStatus.pending:
        return 'Pending';
      case ProtocolStatus.executing:
        return 'Executing';
      case ProtocolStatus.completed:
        return 'Completed';
      case ProtocolStatus.failed:
        return 'Failed';
    }
  }
}

// Data Models
enum EmergencyStatus { standby, active, resolved }

enum EmergencyType { crash, breakdown, medical, fire }

enum IncidentSeverity { low, medium, high }

enum ContactType { emergency, roadside, personal }

enum ProtocolStatus { pending, executing, completed, failed }

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final ContactType type;
  final int priority;
  final bool autoCall;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.type,
    required this.priority,
    required this.autoCall,
  });
}

class EmergencyProtocol {
  final String id;
  final String name;
  final String description;
  final ProtocolStatus status;
  final int priority;

  const EmergencyProtocol({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
  });
}

class EmergencyIncident {
  final String id;
  final EmergencyType type;
  final DateTime timestamp;
  final String location;
  final int responseTime; // minutes
  final String resolution;
  final IncidentSeverity severity;

  const EmergencyIncident({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.location,
    required this.responseTime,
    required this.resolution,
    required this.severity,
  });
}

