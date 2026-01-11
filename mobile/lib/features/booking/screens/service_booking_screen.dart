import 'package:flutter/material.dart';

/// AIVONITY Service Booking Screen
/// Advanced booking interface with calendar and service center selection
class ServiceBookingScreen extends StatefulWidget {
  final String? vehicleId;

  const ServiceBookingScreen({super.key, this.vehicleId});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();

  int _currentStep = 0;
  String? _selectedServiceCenter;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedServiceType;
  String _description = '';

  final List<String> _steps = [
    'Service Type',
    'Service Center',
    'Date & Time',
    'Confirmation',
  ];

  final List<String> _serviceTypes = [
    'Regular Maintenance',
    'Oil Change',
    'Brake Service',
    'Tire Service',
    'Engine Diagnostics',
    'Battery Service',
  ];

  final List<Map<String, dynamic>> _serviceCenters = [
    {
      'id': '1',
      'name': 'Downtown Service Center',
      'address': '123 Main St, Downtown',
      'rating': 4.8,
      'distance': '2.5 km',
    },
    {
      'id': '2',
      'name': 'North Side Auto Care',
      'address': '456 North Ave, North Side',
      'rating': 4.6,
      'distance': '5.2 km',
    },
    {
      'id': '3',
      'name': 'Express Service Hub',
      'address': '789 Express Way, City Center',
      'rating': 4.9,
      'distance': '3.1 km',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _steps.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
                _tabController.animateTo(index);
              },
              children: [
                _buildServiceTypeStep(),
                _buildServiceCenterStep(),
                _buildDateTimeStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),

          // Navigation Buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Text(
        'Book Service',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Step Indicator
          Row(
            children: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = index <= _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step Circle
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: isActive ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),

                    // Connector Line
                    if (index < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Step Labels
          Row(
            children: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Text(
                  step,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What service do you need?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the type of service for your vehicle',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _serviceTypes.length,
              itemBuilder: (context, index) {
                final serviceType = _serviceTypes[index];
                final isSelected = _selectedServiceType == serviceType;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      _getServiceIcon(serviceType),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    title: Text(
                      serviceType,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedServiceType = serviceType;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCenterStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a service center',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select from nearby authorized service centers',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _serviceCenters.length,
              itemBuilder: (context, index) {
                final center = _serviceCenters[index];
                final isSelected = _selectedServiceCenter == center['id'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                      child: Icon(
                        Icons.location_on,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                    title: Text(
                      center['name'] as String,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(center['address'] as String),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text('${center['rating']}'),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.directions_car,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(center['distance'] as String),
                          ],
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedServiceCenter = center['id'] as String;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select date and time',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred appointment slot',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                // Date Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Select Date'),
                    subtitle: Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'No date selected',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectDate(),
                  ),
                ),

                const SizedBox(height: 16),

                // Time Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Select Time'),
                    subtitle: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'No time selected',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectTime(),
                  ),
                ),

                const SizedBox(height: 24),

                // Available Time Slots
                if (_selectedDate != null) ...[
                  Text(
                    'Available Time Slots',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _getAvailableTimeSlots().length,
                      itemBuilder: (context, index) {
                        final timeSlot = _getAvailableTimeSlots()[index];
                        final isSelected = _selectedTime == timeSlot;

                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedTime = timeSlot;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            foregroundColor: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            elevation: isSelected ? 4 : 1,
                          ),
                          child: Text(timeSlot.format(context)),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm your booking',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your booking details before confirming',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildConfirmationCard(),
                  const SizedBox(height: 24),
                  _buildDescriptionField(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    final selectedCenter = _serviceCenters.firstWhere(
      (center) => center['id'] == _selectedServiceCenter,
      orElse: () => {'name': 'Not selected'},
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfirmationItem(
            'Service Type',
            _selectedServiceType ?? 'Not selected',
            Icons.build,
          ),
          const Divider(height: 32),
          _buildConfirmationItem(
            'Service Center',
            selectedCenter['name'] as String,
            Icons.location_on,
          ),
          const Divider(height: 32),
          _buildConfirmationItem(
            'Date & Time',
            _selectedDate != null && _selectedTime != null
                ? '${_formatDate(_selectedDate!)} at ${_selectedTime!.format(context)}'
                : 'Not selected',
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Notes (Optional)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe any specific issues or requirements...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _description = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back Button
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToPreviousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),

            if (_currentStep > 0) const SizedBox(width: 16),

            // Next/Confirm Button
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _canProceed() ? _goToNextStep : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == _steps.length - 1
                      ? 'Confirm Booking'
                      : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedServiceType != null;
      case 1:
        return _selectedServiceCenter != null;
      case 2:
        return _selectedDate != null && _selectedTime != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmBooking();
    }
  }

  void _confirmBooking() async {
    if (!_canProceed()) return;

    try {
      // Simulate booking creation
      await Future.delayed(const Duration(seconds: 1));

      // Log booking details including description
      debugPrint('Booking confirmed with description: $_description');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  List<TimeOfDay> _getAvailableTimeSlots() {
    return [
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 11, minute: 0),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
      const TimeOfDay(hour: 16, minute: 0),
    ];
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Help'),
        content: const Text(
          'Follow these steps to book your service:\n\n'
          '1. Select the type of service you need\n'
          '2. Choose a nearby service center\n'
          '3. Pick your preferred date and time\n'
          '4. Review and confirm your booking\n\n'
          'You can go back to any step to make changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'Regular Maintenance':
        return Icons.build;
      case 'Oil Change':
        return Icons.oil_barrel;
      case 'Brake Service':
        return Icons.disc_full;
      case 'Tire Service':
        return Icons.tire_repair;
      case 'Engine Diagnostics':
        return Icons.settings;
      case 'Battery Service':
        return Icons.battery_charging_full;
      default:
        return Icons.build;
    }
  }
}
