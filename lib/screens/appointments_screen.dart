import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = GetIt.instance<BookingService>();

  late TabController _tabController;
  List<ServiceAppointment> _allAppointments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAppointments() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _allAppointments = _bookingService.getAppointments();
        _isLoading = false;
      });
    });
  }

  List<ServiceAppointment> get _upcomingAppointments {
    final now = DateTime.now();
    return _allAppointments.where((appointment) {
      return appointment.appointmentDate.isAfter(now) &&
          (appointment.status == AppointmentStatus.pending ||
              appointment.status == AppointmentStatus.confirmed);
    }).toList();
  }

  List<ServiceAppointment> get _pastAppointments {
    final now = DateTime.now();
    return _allAppointments.where((appointment) {
      return appointment.appointmentDate.isBefore(now) ||
          appointment.status == AppointmentStatus.completed ||
          appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.noShow;
    }).toList();
  }

  List<ServiceAppointment> get _pendingAppointments {
    return _allAppointments.where((appointment) {
      return appointment.status == AppointmentStatus.pending;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.schedule),
              text: 'Upcoming (${_upcomingAppointments.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Past (${_pastAppointments.length})',
            ),
            Tab(
              icon: const Icon(Icons.pending),
              text: 'Pending (${_pendingAppointments.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(_upcomingAppointments, isUpcoming: true),
                _buildAppointmentsList(_pastAppointments, isUpcoming: false),
                _buildAppointmentsList(_pendingAppointments, isUpcoming: true),
              ],
            ),
    );
  }

  Widget _buildAppointmentsList(
    List<ServiceAppointment> appointments, {
    required bool isUpcoming,
  }) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming appointments' : 'No past appointments',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Book your first appointment to get started'
                  : 'Your appointment history will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadAppointments();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return AppointmentCard(
            appointment: appointment,
            onCancel: isUpcoming ? () => _cancelAppointment(appointment) : null,
            onReschedule: isUpcoming
                ? () => _rescheduleAppointment(appointment)
                : null,
            onViewDetails: () => _viewAppointmentDetails(appointment),
          );
        },
      ),
    );
  }

  Future<void> _cancelAppointment(ServiceAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel your appointment on ${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year} at ${appointment.timeSlot}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Appointment'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingService.cancelAppointment(appointment.id);
        if (mounted) {
          _loadAppointments();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rescheduleAppointment(ServiceAppointment appointment) async {
    // Show reschedule dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RescheduleDialog(appointment: appointment),
    );

    if (result == true) {
      _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _viewAppointmentDetails(ServiceAppointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentDetailsSheet(appointment: appointment),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final ServiceAppointment appointment;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onViewDetails;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
    this.onReschedule,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.serviceCenterName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(appointment.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  appointment.timeSlot,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.build, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    appointment.requestedServices.join(', '),
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (appointment.confirmationCode != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Code: ${appointment.confirmationCode}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            if (appointment.estimatedCost != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Estimated: \$${appointment.estimatedCost!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                ),
                if (onReschedule != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReschedule,
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Reschedule'),
                    ),
                  ),
                ],
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.teal;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'PENDING';
      case AppointmentStatus.confirmed:
        return 'CONFIRMED';
      case AppointmentStatus.inProgress:
        return 'IN PROGRESS';
      case AppointmentStatus.completed:
        return 'COMPLETED';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.noShow:
        return 'NO SHOW';
    }
  }
}

class AppointmentDetailsSheet extends StatelessWidget {
  final ServiceAppointment appointment;

  const AppointmentDetailsSheet({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Appointment Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildDetailSection('Service Center', [
                    _buildDetailRow('Name', appointment.serviceCenterName),
                    if (appointment.confirmationCode != null)
                      _buildDetailRow(
                        'Confirmation Code',
                        appointment.confirmationCode!,
                      ),
                  ]),

                  _buildDetailSection('Appointment', [
                    _buildDetailRow(
                      'Date',
                      '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                    ),
                    _buildDetailRow('Time', appointment.timeSlot),
                    _buildDetailRow(
                      'Status',
                      _getStatusText(appointment.status),
                    ),
                    if (appointment.estimatedDurationMinutes != null)
                      _buildDetailRow(
                        'Duration',
                        '${appointment.estimatedDurationMinutes} minutes',
                      ),
                  ]),

                  _buildDetailSection('Services', [
                    ...appointment.requestedServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• '),
                            Expanded(child: Text(service)),
                          ],
                        ),
                      ),
                    ),
                  ]),

                  _buildDetailSection('Customer', [
                    _buildDetailRow('Name', appointment.customerName),
                    _buildDetailRow('Phone', appointment.customerPhone),
                    _buildDetailRow('Email', appointment.customerEmail),
                  ]),

                  _buildDetailSection('Vehicle', [
                    _buildDetailRow('Vehicle', appointment.vehicleInfo),
                  ]),

                  if (appointment.specialRequests != null)
                    _buildDetailSection('Special Requests', [
                      Text(appointment.specialRequests!),
                    ]),

                  if (appointment.estimatedCost != null)
                    _buildDetailSection('Cost', [
                      _buildDetailRow(
                        'Estimated Total',
                        '\$${appointment.estimatedCost!.toStringAsFixed(2)}',
                      ),
                    ]),

                  _buildDetailSection('Booking Info', [
                    _buildDetailRow(
                      'Booked On',
                      '${appointment.createdAt.day}/${appointment.createdAt.month}/${appointment.createdAt.year}',
                    ),
                    if (appointment.confirmedAt != null)
                      _buildDetailRow(
                        'Confirmed On',
                        '${appointment.confirmedAt!.day}/${appointment.confirmedAt!.month}/${appointment.confirmedAt!.year}',
                      ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending Confirmation';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

class RescheduleDialog extends StatefulWidget {
  final ServiceAppointment appointment;

  const RescheduleDialog({super.key, required this.appointment});

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  final BookingService _bookingService = GetIt.instance<BookingService>();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedTimeSlot;
  ServiceCenterAvailability? _availability;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availability = await _bookingService.getAvailability(
        serviceCenterId: widget.appointment.serviceCenterId,
        date: _selectedDate,
      );

      setState(() {
        _availability = availability;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reschedule Appointment'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date selection
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('New Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
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

            // Time slot selection
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_availability != null) ...[
              const SizedBox(height: 16),
              const Text('Available Time Slots:'),
              const SizedBox(height: 8),

              if (_availability!.availableTimeSlots.isEmpty)
                const Text('No available slots for this date')
              else
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
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
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[300]!,
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
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedTimeSlot != null
              ? () async {
                  final currentContext = context;
                  try {
                    await _bookingService.rescheduleAppointment(
                      appointmentId: widget.appointment.id,
                      newDate: _selectedDate,
                      newTimeSlot: _selectedTimeSlot!.displayTime,
                    );
                    Navigator.of(currentContext).pop(true);
                  } catch (e) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reschedule appointment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
          child: const Text('Reschedule'),
        ),
      ],
    );
  }
}
