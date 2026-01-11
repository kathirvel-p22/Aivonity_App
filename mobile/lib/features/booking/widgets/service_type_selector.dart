import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AIVONITY Service Type Selector Widget
/// Grid of service type options with icons and descriptions
class ServiceTypeSelector extends StatelessWidget {
  final String? selectedType;
  final Function(String) onTypeSelected;

  const ServiceTypeSelector({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
  });

  static const List<Map<String, dynamic>> _serviceTypes = [
    {
      'type': 'maintenance',
      'title': 'General Maintenance',
      'description': 'Regular check-up and maintenance',
      'icon': Icons.build_circle,
      'color': Colors.blue,
    },
    {
      'type': 'repair',
      'title': 'Repair Service',
      'description': 'Fix specific issues or problems',
      'icon': Icons.handyman,
      'color': Colors.orange,
    },
    {
      'type': 'inspection',
      'title': 'Vehicle Inspection',
      'description': 'Safety and emissions inspection',
      'icon': Icons.search,
      'color': Colors.green,
    },
    {
      'type': 'oilChange',
      'title': 'Oil Change',
      'description': 'Engine oil and filter replacement',
      'icon': Icons.opacity,
      'color': Colors.amber,
    },
    {
      'type': 'tireService',
      'title': 'Tire Service',
      'description': 'Tire rotation, balancing, replacement',
      'icon': Icons.tire_repair,
      'color': Colors.grey,
    },
    {
      'type': 'batteryService',
      'title': 'Battery Service',
      'description': 'Battery testing and replacement',
      'icon': Icons.battery_charging_full,
      'color': Colors.red,
    },
    {
      'type': 'brakeService',
      'title': 'Brake Service',
      'description': 'Brake pad and system service',
      'icon': Icons.disc_full,
      'color': Colors.deepOrange,
    },
    {
      'type': 'engineService',
      'title': 'Engine Service',
      'description': 'Engine diagnostics and repair',
      'icon': Icons.settings,
      'color': Colors.purple,
    },
    {
      'type': 'transmission',
      'title': 'Transmission Service',
      'description': 'Transmission service and repair',
      'icon': Icons.sync,
      'color': Colors.indigo,
    },
    {
      'type': 'airConditioning',
      'title': 'A/C Service',
      'description': 'A/C system service and repair',
      'icon': Icons.ac_unit,
      'color': Colors.cyan,
    },
    {
      'type': 'electrical',
      'title': 'Electrical Service',
      'description': 'Electrical system diagnostics',
      'icon': Icons.electrical_services,
      'color': Colors.yellow,
    },
    {
      'type': 'other',
      'title': 'Other Service',
      'description': 'Custom or specialized service',
      'icon': Icons.more_horiz,
      'color': Colors.blueGrey,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _serviceTypes.length,
      itemBuilder: (context, index) {
        final serviceType = _serviceTypes[index];
        final isSelected = selectedType == serviceType['type'];

        return _buildServiceTypeCard(context, serviceType, isSelected, index);
      },
    );
  }

  Widget _buildServiceTypeCard(
    BuildContext context,
    Map<String, dynamic> serviceType,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => onTypeSelected(serviceType['type'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (serviceType['color'] as Color).withValues(alpha:0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (serviceType['color'] as Color)
                : Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? (serviceType['color'] as Color)
                    : (serviceType['color'] as Color).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                serviceType['icon'] as IconData,
                color:
                    isSelected ? Colors.white : (serviceType['color'] as Color),
                size: 24,
              ),
            ).animate(target: isSelected ? 1 : 0).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: 200.ms,
                ),

            const SizedBox(height: 12),

            // Title
            Text(
              serviceType['title'] as String,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (serviceType['color'] as Color)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Description
            Text(
              serviceType['description'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha:0.6),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Selection Indicator
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: serviceType['color'] as Color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(begin: const Offset(0.5, 0.5)),
            ],
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3);
  }
}

