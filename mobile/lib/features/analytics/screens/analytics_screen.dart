import 'package:flutter/material.dart';

/// Analytics Screen
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewCards(context),

            const SizedBox(height: 24),

            // Performance Chart Section
            _buildChartSection(
                context, 'Vehicle Performance', Icons.trending_up,),

            const SizedBox(height: 24),

            // Fuel Efficiency Section
            _buildChartSection(
                context, 'Fuel Efficiency', Icons.local_gas_station,),

            const SizedBox(height: 24),

            // Maintenance History
            _buildMaintenanceHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    final cards = [
      {
        'title': 'Total Miles',
        'value': '15,420',
        'icon': Icons.speed,
        'color': Colors.blue,
      },
      {
        'title': 'Avg MPG',
        'value': '32.5',
        'icon': Icons.local_gas_station,
        'color': Colors.green,
      },
      {
        'title': 'Health Score',
        'value': '92%',
        'icon': Icons.favorite,
        'color': Colors.red,
      },
      {
        'title': 'Service Due',
        'value': '500 mi',
        'icon': Icons.build,
        'color': Colors.orange,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: 24,
              ),
              const Spacer(),
              Text(
                card['value'] as String,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                card['title'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartSection(BuildContext context, String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chart visualization will be displayed here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceHistory(BuildContext context) {
    final history = [
      {
        'date': '2024-01-15',
        'service': 'Oil Change',
        'cost': '\$45.99',
        'mileage': '14,850',
      },
      {
        'date': '2023-12-10',
        'service': 'Tire Rotation',
        'cost': '\$29.99',
        'mileage': '14,200',
      },
      {
        'date': '2023-11-05',
        'service': 'Brake Inspection',
        'cost': '\$89.99',
        'mileage': '13,800',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Maintenance History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return Container(
              margin:
                  EdgeInsets.only(bottom: index < history.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.build,
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
                          item['service'] as String,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['date']} • ${item['mileage']} miles',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item['cost'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

