import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analytics.dart';

class InteractiveLineChart extends StatefulWidget {
  final ChartData chartData;
  final double height;
  final Function(DataPoint?)? onPointTap;

  const InteractiveLineChart({
    super.key,
    required this.chartData,
    this.height = 300,
    this.onPointTap,
  });

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? touchedIndex;
  DataPoint? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chartData.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: widget.chartData.configuration.showGrid,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(color: Colors.grey, strokeWidth: 0.5);
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(color: Colors.grey, strokeWidth: 0.5);
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
                    axisNameWidget: Text(
                      widget.chartData.configuration.xAxisLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return _buildBottomTitle(value.toInt());
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      widget.chartData.configuration.yAxisLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: _getMaxX(),
                minY: widget.chartData.configuration.minY ?? _getMinY(),
                maxY: widget.chartData.configuration.maxY ?? _getMaxY(),
                lineBarsData: _buildLineBarsData(),
                lineTouchData: LineTouchData(
                  enabled: widget.chartData.configuration.enableInteraction,
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? response) {
                        if (response != null && response.lineBarSpots != null) {
                          final spot = response.lineBarSpots!.first;
                          final seriesIndex = spot.barIndex;
                          final pointIndex = spot.spotIndex;

                          if (seriesIndex < widget.chartData.series.length &&
                              pointIndex <
                                  widget
                                      .chartData
                                      .series[seriesIndex]
                                      .data
                                      .length) {
                            selectedPoint = widget
                                .chartData
                                .series[seriesIndex]
                                .data[pointIndex];
                            widget.onPointTap?.call(selectedPoint);
                            setState(() {
                              touchedIndex = pointIndex;
                            });
                          }
                        }
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final series =
                            widget.chartData.series[touchedSpot.barIndex];
                        final dataPoint = series.data[touchedSpot.spotIndex];

                        return LineTooltipItem(
                          '${series.name}\n${dataPoint.value.toStringAsFixed(1)}\n${DateFormat('MMM dd').format(dataPoint.timestamp)}',
                          TextStyle(
                            color: _parseColor(series.color),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          if (widget.chartData.configuration.showLegend) _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildBottomTitle(int index) {
    if (widget.chartData.series.isEmpty ||
        index >= widget.chartData.series.first.data.length) {
      return const Text('');
    }

    final dataPoint = widget.chartData.series.first.data[index];
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        DateFormat('MM/dd').format(dataPoint.timestamp),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 16,
        children: widget.chartData.series.map((series) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _parseColor(series.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(series.name, style: const TextStyle(fontSize: 12)),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    return widget.chartData.series.asMap().entries.map((entry) {
      final series = entry.value;

      return LineChartBarData(
        spots: series.data.asMap().entries.map((dataEntry) {
          return FlSpot(dataEntry.key.toDouble(), dataEntry.value.value);
        }).toList(),
        isCurved: true,
        color: _parseColor(series.color),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: touchedIndex == index ? 6 : 4,
              color: _parseColor(series.color),
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: series.type == SeriesType.area,
          color: _parseColor(series.color).withValues(alpha:0.2),
        ),
      );
    }).toList();
  }

  double _getMaxX() {
    if (widget.chartData.series.isEmpty) return 10;
    return widget.chartData.series.first.data.length.toDouble() - 1;
  }

  double _getMinY() {
    double min = double.infinity;
    for (final series in widget.chartData.series) {
      for (final point in series.data) {
        if (point.value < min) min = point.value;
      }
    }
    return min * 0.9; // Add some padding
  }

  double _getMaxY() {
    double max = double.negativeInfinity;
    for (final series in widget.chartData.series) {
      for (final point in series.data) {
        if (point.value > max) max = point.value;
      }
    }
    return max * 1.1; // Add some padding
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue; // Default color
    }
  }
}

