import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AIVONITY Booking Calendar Widget
/// Calendar with time slot selection for appointments
class BookingCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;

  const BookingCalendar({
    super.key,
    this.selectedDate,
    this.selectedTime,
    required this.onDateSelected,
    required this.onTimeSelected,
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  final List<TimeOfDay> _availableTimeSlots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar Header
        _buildCalendarHeader(),

        const SizedBox(height: 16),

        // Calendar Grid
        _buildCalendarGrid(),

        const SizedBox(height: 24),

        // Time Slots
        if (widget.selectedDate != null) ...[
          _buildTimeSlotHeader(),
          const SizedBox(height: 16),
          _buildTimeSlots(),
        ],
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
          icon: const Icon(Icons.chevron_left),
        ),

        Text(
          _getMonthYearString(_currentMonth),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),

        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weekday Headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha:0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Calendar Days
          ...List.generate(6, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }

                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  dayNumber,
                );
                final isToday = _isSameDay(date, DateTime.now());
                final isSelected =
                    widget.selectedDate != null &&
                    _isSameDay(date, widget.selectedDate!);
                final isPast = date.isBefore(
                  DateTime.now().subtract(const Duration(days: 1)),
                );

                return Expanded(
                  child: GestureDetector(
                    onTap: isPast
                        ? null
                        : () {
                            widget.onDateSelected(date);
                          },
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha:0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          dayNumber.toString(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isPast
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withValues(alpha:0.3)
                                    : isSelected
                                    ? Colors.white
                                    : isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeSlotHeader() {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Available Time Slots',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return SizedBox(
      height: 120,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _availableTimeSlots.length,
        itemBuilder: (context, index) {
          final timeSlot = _availableTimeSlots[index];
          final isSelected =
              widget.selectedTime != null &&
              widget.selectedTime!.hour == timeSlot.hour &&
              widget.selectedTime!.minute == timeSlot.minute;

          return GestureDetector(
                onTap: () => widget.onTimeSelected(timeSlot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha:0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      timeSlot.format(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              )
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.8, 0.8));
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

