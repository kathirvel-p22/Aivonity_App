import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AIVONITY Quick Suggestions Widget
/// Contextual quick action buttons for common queries
class QuickSuggestions extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const QuickSuggestions({super.key, required this.onSuggestionTap});

  static const List<Map<String, dynamic>> _suggestions = [
    {
      'text': 'Check vehicle health',
      'icon': Icons.health_and_safety,
      'color': Colors.green,
    },
    {
      'text': 'Schedule maintenance',
      'icon': Icons.schedule,
      'color': Colors.blue,
    },
    {
      'text': 'Find service centers',
      'icon': Icons.location_on,
      'color': Colors.orange,
    },
    {'text': 'Explain alerts', 'icon': Icons.warning, 'color': Colors.red},
    {'text': 'Fuel efficiency tips', 'icon': Icons.eco, 'color': Colors.teal},
    {
      'text': 'Driving insights',
      'icon': Icons.insights,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick suggestions',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha:0.6),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value;

                return _buildSuggestionChip(
                  context,
                  suggestion['text'] as String,
                  suggestion['icon'] as IconData,
                  suggestion['color'] as Color,
                  index,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.only(right: index < _suggestions.length - 1 ? 12 : 0),
      child:
          GestureDetector(
                onTap: () => onSuggestionTap(text),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha:0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: color),

                      const SizedBox(width: 8),

                      Text(
                        text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: Duration(milliseconds: index * 100))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.3),
    );
  }
}

