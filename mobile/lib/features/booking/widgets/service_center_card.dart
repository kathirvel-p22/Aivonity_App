import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/service_center.dart';

/// AIVONITY Service Center Card Widget
/// Displays service center information with selection state
class ServiceCenterCard extends StatelessWidget {
  final ServiceCenter serviceCenter;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceCenterCard({
    super.key,
    required this.serviceCenter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Service Center Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              serviceCenter.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (serviceCenter.isAuthorized)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Authorized',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceCenter.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha:0.7),
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // Selection Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha:0.5),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rating and Distance Row
            Row(
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      serviceCenter.rating.toStringAsFixed(1),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${serviceCenter.reviewCount})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                    ),
                  ],
                ),

                const Spacer(),

                // Distance
                if (serviceCenter.distanceKm != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${serviceCenter.distanceKm!.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Services
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: serviceCenter.services.take(4).map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                );
              }).toList(),
            ),

            // Contact Info
            if (serviceCenter.phone != null || serviceCenter.email != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (serviceCenter.phone != null) ...[
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      serviceCenter.phone!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                    ),
                  ],
                  if (serviceCenter.phone != null &&
                      serviceCenter.email != null)
                    const SizedBox(width: 16),
                  if (serviceCenter.email != null) ...[
                    Icon(
                      Icons.email,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        serviceCenter.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha:0.6),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.02, 1.02),
          duration: 200.ms,
        );
  }
}

