import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/booking.dart';
import '../models/service_center.dart';
import '../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final ServiceCenter serviceCenter;

  const BookingScreen({super.key, required this.serviceCenter});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = GetIt.instance<BookingService>();

  late TabController _tabController;
  final PageController _pageController = PageController();

  // Form controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  // Form state
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedTimeSlot;
  final List<String> _selectedServices = [];
  String _selectedFuelType = 'gasoline';

  // Loading states
  bool _isLoadingAvailability = false;
  bool _isBooking = false;
  String? _error;

  // Availability data
  ServiceCenterAvailability? _availability;
  double? _estimatedCost;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPreferences();
    _loadAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _licensePlateController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  void _loadPreferences() {
    final preferences = _bookingService.getPreferences();

    if (preferences.defaultCustomerInfo != null) {
      _customerNameController.text = preferences.defaultCustomerInfo!.name;
      _customerPhoneController.text = preferences.defaultCustomerInfo!.phone;
      _customerEmailController.text = preferences.defaultCustomerInfo!.email;
    }

    if (preferences.defaultVehicleInfo != null) {
      _vehicleMakeController.text = preferences.defaultVehicleInfo!.make;
      _vehicleModelController.text = preferences.defaultVehicleInfo!.model;
      _vehicleYearController.text = preferences.defaultVehicleInfo!.year
          .toString();
      _licensePlateController.text =
          preferences.defaultVehicleInfo!.licensePlate ?? '';
      _selectedFuelType = preferences.defaultVehicleInfo!.fuelType;
    }
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoadingAvailability = true;
      _error = null;
    });

    try {
      final availability = await _bookingService.getAvailability(
        serviceCenterId: widget.serviceCenter.id,
        date: _selectedDate,
      );

      setState(() {
        _availability = availability;
      });

      if (_selectedServices.isNotEmpty) {
        _updateCostEstimate();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingAvailability = false;
      });
    }
  }

  Future<void> _updateCostEstimate() async {
    if (_selectedServices.isEmpty) return;

    try {
      final cost = await _bookingService.getServiceEstimate(
        serviceCenterId: widget.serviceCenter.id,
        services: _selectedServices,
      );

      setState(() {
        _estimatedCost = cost;
      });
    } catch (e) {
      // Handle error silently for cost estimation
    }
  }

  Future<void> _bookAppointment() async {
    if (!_validateForm()) return;

    setState(() {
      _isBooking = true;
      _error = null;
    });

    try {
      final request = BookingRequest(
        serviceCenterId: widget.serviceCenter.id,
        preferredDate: _selectedDate,
        preferredTimeSlot: _selectedTimeSlot?.displayTime,
        requestedServices: _selectedServices,
        customerInfo: CustomerInfo(
          name: _customerNameController.text,
          phone: _customerPhoneController.text,
          email: _customerEmailController.text,
        ),
        vehicleInfo: VehicleInfo(
          make: _vehicleMakeController.text,
          model: _vehicleModelController.text,
          year: int.parse(_vehicleYearController.text),
          licensePlate: _licensePlateController.text.isNotEmpty
              ? _licensePlateController.text
              : null,
          fuelType: _selectedFuelType,
        ),
        specialRequests: _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
      );

      final confirmation = await _bookingService.bookAppointment(request);

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                BookingConfirmationScreen(confirmation: confirmation),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  bool _validateForm() {
    if (_selectedServices.isEmpty) {
      setState(() {
        _error = 'Please select at least one service';
      });
      return false;
    }

    if (_selectedTimeSlot == null) {
      setState(() {
        _error = 'Please select a time slot';
      });
      return false;
    }

    if (_customerNameController.text.isEmpty ||
        _customerPhoneController.text.isEmpty ||
        _customerEmailController.text.isEmpty) {
      setState(() {
        _error = 'Please fill in all customer information';
      });
      return false;
    }

    if (_vehicleMakeController.text.isEmpty ||
        _vehicleModelController.text.isEmpty ||
        _vehicleYearController.text.isEmpty) {
      setState(() {
        _error = 'Please fill in all vehicle information';
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Appointment'),
            Text(
              widget.serviceCenter.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < 4; i++) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: i <= _currentStep
                        ? Colors.blue
                        : Colors.grey[300],
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i <= _currentStep
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < _currentStep
                            ? Colors.blue
                            : Colors.grey[300],
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildServiceSelectionStep(),
                _buildDateTimeSelectionStep(),
                _buildCustomerInfoStep(),
                _buildReviewStep(),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBooking
                        ? null
                        : () {
                            if (_currentStep < 3) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _bookAppointment();
                            }
                          },
                    child: _isBooking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep < 3 ? 'Next' : 'Book Appointment'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionStep() {
    if (_availability == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Services',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ...widget.serviceCenter.services.map((service) {
            final isSelected = _selectedServices.contains(service);
            final price = _availability!.servicePrices[service];
            final duration = _availability!.serviceDurations[service];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                title: Text(service),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (price != null)
                      Text('Price: \$${price.toStringAsFixed(2)}'),
                    if (duration != null) Text('Duration: $duration minutes'),
                  ],
                ),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                  _updateCostEstimate();
                },
              ),
            );
          }),

          if (_estimatedCost != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Total:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${_estimatedCost!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date & Time',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Date selection
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Appointment Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );

                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTimeSlot = null;
                  });
                  _loadAvailability();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Time slot selection
          if (_isLoadingAvailability)
            const Center(child: CircularProgressIndicator())
          else if (_availability != null) ...[
            Text(
              'Available Time Slots',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_availability!.availableTimeSlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No available time slots for this date. Please select a different date.',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availability!.availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final slot = _availability!.availableTimeSlots[index];
                  final isSelected = _selectedTimeSlot?.id == slot.id;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slot.displayTime,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer & Vehicle Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Customer Information
          Text(
            'Customer Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _customerPhoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _customerEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Address *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          // Vehicle Information
          Text(
            'Vehicle Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vehicleMakeController,
                  decoration: const InputDecoration(
                    labelText: 'Make *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(
                    labelText: 'Model *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vehicleYearController,
                  decoration: const InputDecoration(
                    labelText: 'Year *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _licensePlateController,
                  decoration: const InputDecoration(
                    labelText: 'License Plate',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _selectedFuelType,
            decoration: const InputDecoration(
              labelText: 'Fuel Type *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'gasoline', child: Text('Gasoline')),
              DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
              DropdownMenuItem(value: 'electric', child: Text('Electric')),
              DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFuelType = value;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Special Requests
          Text(
            'Special Requests (Optional)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _specialRequestsController,
            decoration: const InputDecoration(
              labelText: 'Any special requests or notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Appointment',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Service Center
          Card(
            child: ListTile(
              leading: const Icon(Icons.build),
              title: Text(widget.serviceCenter.name),
              subtitle: Text(widget.serviceCenter.address),
            ),
          ),
          const SizedBox(height: 8),

          // Date & Time
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              subtitle: Text(
                _selectedTimeSlot?.displayTime ?? 'No time selected',
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Services
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list),
                      const SizedBox(width: 8),
                      Text(
                        'Selected Services',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._selectedServices.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(service),
                          if (_availability?.servicePrices[service] != null)
                            Text(
                              '\$${_availability!.servicePrices[service]!.toStringAsFixed(2)}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_estimatedCost != null) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${_estimatedCost!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Customer Info
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(_customerNameController.text),
              subtitle: Text(
                '${_customerPhoneController.text}\n${_customerEmailController.text}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 8),

          // Vehicle Info
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text(
                '${_vehicleYearController.text} ${_vehicleMakeController.text} ${_vehicleModelController.text}',
              ),
              subtitle: Text(
                '${_selectedFuelType.toUpperCase()}${_licensePlateController.text.isNotEmpty ? ' • ${_licensePlateController.text}' : ''}',
              ),
            ),
          ),

          if (_specialRequestsController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Special Requests'),
                subtitle: Text(_specialRequestsController.text),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BookingConfirmationScreen extends StatelessWidget {
  final BookingConfirmation confirmation;

  const BookingConfirmationScreen({super.key, required this.confirmation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),

            Text(
              confirmation.confirmationMessage,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Confirmation details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      'Confirmation Code',
                      confirmation.appointment.confirmationCode ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Service Center',
                      confirmation.appointment.serviceCenterName,
                    ),
                    _buildDetailRow(
                      'Date',
                      '${confirmation.appointment.appointmentDate.day}/${confirmation.appointment.appointmentDate.month}/${confirmation.appointment.appointmentDate.year}',
                    ),
                    _buildDetailRow('Time', confirmation.appointment.timeSlot),
                    _buildDetailRow(
                      'Services',
                      confirmation.appointment.requestedServices.join(', '),
                    ),
                    if (confirmation.appointment.estimatedCost != null)
                      _buildDetailRow(
                        'Estimated Cost',
                        '\$${confirmation.appointment.estimatedCost!.toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preparation instructions
            if (confirmation.preparationInstructions.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preparation Instructions',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...confirmation.preparationInstructions.map(
                        (instruction) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(instruction)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // What to bring
            if (confirmation.whatToBring.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What to Bring',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...confirmation.whatToBring.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/appointments',
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('View My Appointments'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
