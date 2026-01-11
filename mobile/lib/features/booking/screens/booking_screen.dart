import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/service_centers_service.dart';

/// Service Booking Screen
/// Allows users to book service appointments with location integration
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  String _selectedServiceType = 'maintenance';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  ServiceCenter? _selectedServiceCenter;
  String _additionalNotes = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _showLocationSelector,
            tooltip: 'Select Service Location',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceTypeSelector(),
            const SizedBox(height: 24),
            _buildDateTimeSelector(),
            const SizedBox(height: 24),
            _buildLocationSelector(),
            const SizedBox(height: 24),
            _buildServiceDetails(),
            const SizedBox(height: 32),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            ..._getServiceTypes().map(
              (service) => RadioListTile<String>(
                title: Text(service['name']!),
                subtitle: Text(service['description']!),
                value: service['id']!,
                groupValue: _selectedServiceType,
                onChanged: (value) =>
                    setState(() => _selectedServiceType = value!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
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

  Widget _buildLocationSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedServiceCenter == null
                        ? 'Select a service center'
                        : _selectedServiceCenter!.name,
                    style: TextStyle(
                      color:
                          _selectedServiceCenter == null ? Colors.grey : null,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectServiceCenter,
                  child: const Text('Browse'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _additionalNotes),
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any specific requirements or issues...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _additionalNotes = value,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current location will be included for mobile service requests',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedServiceCenter == null ? null : _bookService,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Book Service Appointment',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  List<Map<String, String>> _getServiceTypes() {
    return [
      {
        'id': 'maintenance',
        'name': 'Regular Maintenance',
        'description': 'Oil change, tire rotation, inspection',
      },
      {
        'id': 'repair',
        'name': 'Repair Service',
        'description': 'Diagnostics and repairs',
      },
      {
        'id': 'emergency',
        'name': 'Emergency Service',
        'description': 'Roadside assistance and urgent repairs',
      },
      {
        'id': 'mobile',
        'name': 'Mobile Service',
        'description': 'Service at your location',
      },
    ];
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _selectServiceCenter() async {
    final result = await Navigator.pushNamed(context, '/service-centers');
    if (result != null && result is ServiceCenter) {
      setState(() {
        _selectedServiceCenter = result;
      });
    }
  }

  void _showLocationSelector() {
    // Quick location sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use Service Centers to find nearby locations'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _bookService() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service: ${_getServiceTypes().firstWhere((s) => s['id'] == _selectedServiceType)['name']}',
            ),
            Text(
              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            Text('Time: ${_selectedTime.format(context)}'),
            Text('Location: ${_selectedServiceCenter?.name ?? 'Not selected'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmBooking();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmBooking() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service appointment booked successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back to dashboard
    context.go('/dashboard');
  }
}
