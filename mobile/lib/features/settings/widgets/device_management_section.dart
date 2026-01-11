import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_models.dart';
import '../../../providers/auth_provider.dart';

/// Device Management Section Widget
/// Allows users to view and manage their registered devices
class DeviceManagementSection extends ConsumerStatefulWidget {
  const DeviceManagementSection({super.key});

  @override
  ConsumerState<DeviceManagementSection> createState() =>
      _DeviceManagementSectionState();
}

class _DeviceManagementSectionState
    extends ConsumerState<DeviceManagementSection> {
  List<DeviceInfo> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final devices = await authNotifier.getRegisteredDevices();

      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage devices that have access to your account.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_devices.isEmpty) ...[
              const Center(child: Text('No registered devices found')),
            ] else ...[
              Text('Registered Devices (${_devices.length})'),
              const SizedBox(height: 8),
              ...(_devices.map((device) => ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(device.name),
                    subtitle: Text(
                        '${device.platform} • ${device.model ?? 'Unknown'}',),
                  ),)),
            ],
          ],
        ),
      ),
    );
  }
}

