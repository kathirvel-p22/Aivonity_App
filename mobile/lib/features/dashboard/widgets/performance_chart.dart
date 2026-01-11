import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// AIVONITY Performance Chart
/// Animated chart displaying vehicle performance metrics
class PerformanceChart extends StatefulWidget {
  final Map<String, dynamic> data;

  const PerformanceChart({super.key, required this.data});

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  int _selectedTab = 0;
  final List<String> _tabs = ['Health', 'Efficiency', 'Usage'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
          // Tab Selector
          _buildTabSelector(),

          const SizedBox(height: 20),

          // Chart Container
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return _buildChart();
              },
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTab;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
                _animationController.reset();
                _animationController.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha:0.6),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    switch (_selectedTab) {
      case 0:
        return _buildHealthChart();
      case 1:
        return _buildEfficiencyChart();
      case 2:
        return _buildUsageChart();
      default:
        return _buildHealthChart();
    }
  }

  Widget _buildHealthChart() {
    final healthData = _generateHealthData();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha:0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha:0.6),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: healthData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value * _animation.value,
              );
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.2),
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _generateEfficiencyData().asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value * _animation.value,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.green, Colors.green.withValues(alpha:0.7)],
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha:0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    final usageData = _generateUsageData();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: usageData.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final colors = [
            Theme.of(context).colorScheme.primary,
            Colors.orange,
            Colors.green,
            Colors.purple,
          ];

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: value * _animation.value,
            title: '${(value * _animation.value).toInt()}%',
            radius: 50,
            titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    switch (_selectedTab) {
      case 0:
        return _buildHealthLegend();
      case 1:
        return _buildEfficiencyLegend();
      case 2:
        return _buildUsageLegend();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHealthLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: Theme.of(context).colorScheme.primary,
          label: 'Overall Health',
        ),
      ],
    );
  }

  Widget _buildEfficiencyLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(color: Colors.green, label: 'Fuel Efficiency'),
      ],
    );
  }

  Widget _buildUsageLegend() {
    final labels = ['City', 'Highway', 'Idle', 'Other'];
    final colors = [
      Theme.of(context).colorScheme.primary,
      Colors.orange,
      Colors.green,
      Colors.purple,
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      children: labels.asMap().entries.map((entry) {
        return _buildLegendItem(color: colors[entry.key], label: entry.value);
      }).toList(),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
          ),
        ),
      ],
    );
  }

  // Mock data generators
  List<double> _generateHealthData() {
    return [85, 88, 82, 90, 87, 85, 89];
  }

  List<double> _generateEfficiencyData() {
    return [75, 82, 78, 85, 80, 77, 83];
  }

  List<double> _generateUsageData() {
    return [45, 30, 15, 10];
  }
}

