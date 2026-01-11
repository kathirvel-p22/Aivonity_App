import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AIVONITY Vehicle Selector
/// Animated dropdown for selecting active vehicle
class VehicleSelector extends StatefulWidget {
  final String? selectedVehicleId;
  final Function(String) onVehicleSelected;

  const VehicleSelector({
    super.key,
    this.selectedVehicleId,
    required this.onVehicleSelected,
  });

  @override
  State<VehicleSelector> createState() => _VehicleSelectorState();
}

class _VehicleSelectorState extends State<VehicleSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isExpanded = false;

  // Mock vehicle data - in real app, this would come from providers
  final List<VehicleOption> _vehicles = [
    VehicleOption(
      id: '1',
      name: 'Tesla Model 3',
      year: 2023,
      healthScore: 0.92,
      image: 'assets/images/tesla_model3.png',
    ),
    VehicleOption(
      id: '2',
      name: 'BMW X5',
      year: 2022,
      healthScore: 0.87,
      image: 'assets/images/bmw_x5.png',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = _vehicles.firstWhere(
      (v) => v.id == widget.selectedVehicleId,
      orElse: () => _vehicles.first,
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _toggleExpanded,
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
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
                  _buildSelectedVehicle(selectedVehicle),
                  if (_isExpanded) ...[
                    const SizedBox(height: 16),
                    _buildVehicleList(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedVehicle(VehicleOption vehicle) {
    return Row(
      children: [
        // Vehicle image placeholder
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_car,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),

        const SizedBox(width: 16),

        // Vehicle info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${vehicle.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getHealthColor(vehicle.healthScore),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(vehicle.healthScore * 100).toInt()}% Health',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getHealthColor(vehicle.healthScore),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Expand icon
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleList() {
    return Column(
      children: _vehicles.map((vehicle) {
        final isSelected = vehicle.id == widget.selectedVehicleId;

        return GestureDetector(
              onTap: () => _selectVehicle(vehicle.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha:0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${vehicle.year} • ${(vehicle.healthScore * 100).toInt()}% Health',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha:0.6),
                                ),
                          ),
                        ],
                      ),
                    ),

                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 100 * _vehicles.indexOf(vehicle)),
            )
            .slideX(begin: -0.3);
      }).toList(),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectVehicle(String vehicleId) {
    widget.onVehicleSelected(vehicleId);
    setState(() {
      _isExpanded = false;
    });
  }

  Color _getHealthColor(double score) {
    if (score >= 0.9) return Colors.green;
    if (score >= 0.7) return Colors.blue;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

/// Vehicle option data model
class VehicleOption {
  final String id;
  final String name;
  final int year;
  final double healthScore;
  final String image;

  VehicleOption({
    required this.id,
    required this.name,
    required this.year,
    required this.healthScore,
    required this.image,
  });
}

