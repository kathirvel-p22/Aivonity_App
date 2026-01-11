import 'package:flutter/material.dart';
import 'dart:async';

/// Service Scheduler for vehicle maintenance appointments
class ServiceScheduler extends StatefulWidget {
  final String? vehicleId;
  final String? serviceType;

  const ServiceScheduler({
    super.key,
    this.vehicleId,
    this.serviceType,
  });

  @override
  State<ServiceScheduler> createState() => _ServiceSchedulerState();
}

class _ServiceSchedulerState extends State<ServiceScheduler> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _selectedService = 'Oil Change';
  String _selectedLocation = 'Preferred Dealer';
  String _notes = '';
  bool _isScheduling = false;

  final List<String> _serviceTypes = [
    'Oil Change',
    'Tire Rotation',
    'Brake Service',
    'Battery Replacement',
    'Transmission Service',
    'Engine Tune-up',
    'Air Filter Replacement',
    'Cooling System Service',
    'Wheel Alignment',
    'General Inspection',
  ];

  final List<String> _locations = [
    'Preferred Dealer',
    'Quick Lube Center',
    'Independent Shop',
    'Mobile Service',
    'Emergency Service',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceType != null) {
      _selectedService = widget.serviceType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Service'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceSelection(),
            const SizedBox(height: 24),
            _buildDateTimeSelection(),
            const SizedBox(height: 24),
            _buildLocationSelection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 32),
            _buildScheduleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedService,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _serviceTypes.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text(service),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedService = value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferred Date & Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocation,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedLocation = value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any specific instructions or concerns...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              onChanged: (value) => _notes = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isScheduling ? null : _scheduleService,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isScheduling
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Schedule Service',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleService() async {
    setState(() => _isScheduling = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isScheduling = false);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Service Scheduled!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service: $_selectedService'),
              Text(
                'Date: ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
              ),
              Text('Time: ${_selectedTime.format(context)}'),
              Text('Location: $_selectedLocation'),
              if (_notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Notes: $_notes'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}

