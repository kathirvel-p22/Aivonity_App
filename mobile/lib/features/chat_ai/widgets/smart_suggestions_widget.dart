import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/multilingual_chat_provider.dart';

/// Smart Suggestions Widget
/// Provides contextual suggestions based on conversation history and vehicle data
class SmartSuggestionsWidget extends ConsumerStatefulWidget {
  final Function(String)? onSuggestionTap;
  final bool showVehicleContext;
  final bool showSeasonalSuggestions;
  final int maxSuggestions;

  const SmartSuggestionsWidget({
    super.key,
    this.onSuggestionTap,
    this.showVehicleContext = true,
    this.showSeasonalSuggestions = true,
    this.maxSuggestions = 6,
  });

  @override
  ConsumerState<SmartSuggestionsWidget> createState() =>
      _SmartSuggestionsWidgetState();
}

class _SmartSuggestionsWidgetState extends ConsumerState<SmartSuggestionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ),);

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);

    final suggestions = _generateSmartSuggestions(messages, currentLanguage);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSuggestionsList(suggestions),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.lightbulb_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Suggestions for you',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList(List<SmartSuggestion> suggestions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;

          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 100)),
            margin: const EdgeInsets.only(right: 12),
            child: _buildSuggestionCard(suggestion, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionCard(SmartSuggestion suggestion, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () => _handleSuggestionTap(suggestion),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    suggestion.color.withValues(alpha:0.1),
                    suggestion.color.withValues(alpha:0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: suggestion.color.withValues(alpha:0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: suggestion.color.withValues(alpha:0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: suggestion.color.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          suggestion.icon,
                          color: suggestion.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: suggestion.color,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (suggestion.priority !=
                                SuggestionPriority.normal)
                              _buildPriorityBadge(suggestion.priority),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    suggestion.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha:0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    suggestion.query,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: suggestion.color,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityBadge(SuggestionPriority priority) {
    Color badgeColor;
    String label;

    switch (priority) {
      case SuggestionPriority.urgent:
        badgeColor = Colors.red;
        label = 'URGENT';
        break;
      case SuggestionPriority.high:
        badgeColor = Colors.orange;
        label = 'HIGH';
        break;
      case SuggestionPriority.normal:
        badgeColor = Colors.blue;
        label = 'NORMAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<SmartSuggestion> _generateSmartSuggestions(
    List<dynamic> messages,
    String currentLanguage,
  ) {
    final suggestions = <SmartSuggestion>[];

    // Vehicle health suggestions
    suggestions.addAll(_getVehicleHealthSuggestions(currentLanguage));

    // Maintenance suggestions
    suggestions.addAll(_getMaintenanceSuggestions(currentLanguage));

    // Seasonal suggestions
    if (widget.showSeasonalSuggestions) {
      suggestions.addAll(_getSeasonalSuggestions(currentLanguage));
    }

    // Context-based suggestions
    suggestions.addAll(_getContextualSuggestions(messages, currentLanguage));

    // Sort by priority and limit
    suggestions.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return suggestions.take(widget.maxSuggestions).toList();
  }

  List<SmartSuggestion> _getVehicleHealthSuggestions(String language) {
    switch (language) {
      case 'es-ES':
        return [
          const SmartSuggestion(
            title: 'Revisar Salud',
            description: 'Verificar el estado general del vehículo',
            query: 'Revisar la salud de mi vehículo',
            icon: Icons.health_and_safety,
            color: Colors.green,
            priority: SuggestionPriority.high,
            category: SuggestionCategory.health,
          ),
        ];
      case 'fr-FR':
        return [
          const SmartSuggestion(
            title: 'Vérifier Santé',
            description: 'Vérifier l\'état général du véhicule',
            query: 'Vérifier la santé de mon véhicule',
            icon: Icons.health_and_safety,
            color: Colors.green,
            priority: SuggestionPriority.high,
            category: SuggestionCategory.health,
          ),
        ];
      default:
        return [
          const SmartSuggestion(
            title: 'Health Check',
            description: 'Check your vehicle\'s overall condition',
            query: 'Check my vehicle health',
            icon: Icons.health_and_safety,
            color: Colors.green,
            priority: SuggestionPriority.high,
            category: SuggestionCategory.health,
          ),
        ];
    }
  }

  List<SmartSuggestion> _getMaintenanceSuggestions(String language) {
    switch (language) {
      case 'es-ES':
        return [
          const SmartSuggestion(
            title: 'Mantenimiento',
            description: 'Programar servicio de mantenimiento',
            query: 'Programar mantenimiento para mi vehículo',
            icon: Icons.build,
            color: Colors.blue,
            priority: SuggestionPriority.normal,
            category: SuggestionCategory.maintenance,
          ),
        ];
      case 'fr-FR':
        return [
          const SmartSuggestion(
            title: 'Entretien',
            description: 'Programmer un service d\'entretien',
            query: 'Programmer l\'entretien de mon véhicule',
            icon: Icons.build,
            color: Colors.blue,
            priority: SuggestionPriority.normal,
            category: SuggestionCategory.maintenance,
          ),
        ];
      default:
        return [
          const SmartSuggestion(
            title: 'Maintenance',
            description: 'Schedule your next service appointment',
            query: 'Schedule maintenance for my vehicle',
            icon: Icons.build,
            color: Colors.blue,
            priority: SuggestionPriority.normal,
            category: SuggestionCategory.maintenance,
          ),
        ];
    }
  }

  List<SmartSuggestion> _getSeasonalSuggestions(String language) {
    final now = DateTime.now();
    final month = now.month;

    // Winter suggestions (Dec, Jan, Feb)
    if (month == 12 || month == 1 || month == 2) {
      switch (language) {
        case 'es-ES':
          return [
            const SmartSuggestion(
              title: 'Preparación Invernal',
              description: 'Consejos para el cuidado invernal del vehículo',
              query: 'Cómo preparar mi vehículo para el invierno',
              icon: Icons.ac_unit,
              color: Colors.lightBlue,
              priority: SuggestionPriority.high,
              category: SuggestionCategory.seasonal,
            ),
          ];
        default:
          return [
            const SmartSuggestion(
              title: 'Winter Prep',
              description: 'Get your vehicle ready for winter',
              query: 'How to prepare my vehicle for winter',
              icon: Icons.ac_unit,
              color: Colors.lightBlue,
              priority: SuggestionPriority.high,
              category: SuggestionCategory.seasonal,
            ),
          ];
      }
    }

    // Summer suggestions (Jun, Jul, Aug)
    if (month >= 6 && month <= 8) {
      switch (language) {
        case 'es-ES':
          return [
            const SmartSuggestion(
              title: 'Cuidado Veraniego',
              description: 'Mantener el vehículo fresco en verano',
              query: 'Consejos para el cuidado del vehículo en verano',
              icon: Icons.wb_sunny,
              color: Colors.orange,
              priority: SuggestionPriority.normal,
              category: SuggestionCategory.seasonal,
            ),
          ];
        default:
          return [
            const SmartSuggestion(
              title: 'Summer Care',
              description: 'Keep your vehicle cool in summer',
              query: 'Summer vehicle care tips',
              icon: Icons.wb_sunny,
              color: Colors.orange,
              priority: SuggestionPriority.normal,
              category: SuggestionCategory.seasonal,
            ),
          ];
      }
    }

    return [];
  }

  List<SmartSuggestion> _getContextualSuggestions(
    List<dynamic> messages,
    String language,
  ) {
    // Analyze recent messages for context
    if (messages.isEmpty) {
      return _getFirstTimeSuggestions(language);
    }

    // If user asked about problems, suggest diagnostics
    final recentMessages = messages.take(5).toList();
    final hasProblems = recentMessages.any((msg) =>
        msg.toString().toLowerCase().contains('problem') ||
        msg.toString().toLowerCase().contains('issue') ||
        msg.toString().toLowerCase().contains('error'),);

    if (hasProblems) {
      return _getDiagnosticSuggestions(language);
    }

    return [];
  }

  List<SmartSuggestion> _getFirstTimeSuggestions(String language) {
    switch (language) {
      case 'es-ES':
        return [
          const SmartSuggestion(
            title: 'Comenzar',
            description: 'Aprende qué puedo hacer por ti',
            query: '¿Qué puedes hacer por mí?',
            icon: Icons.help_outline,
            color: Colors.purple,
            priority: SuggestionPriority.normal,
            category: SuggestionCategory.help,
          ),
        ];
      default:
        return [
          const SmartSuggestion(
            title: 'Get Started',
            description: 'Learn what I can help you with',
            query: 'What can you help me with?',
            icon: Icons.help_outline,
            color: Colors.purple,
            priority: SuggestionPriority.normal,
            category: SuggestionCategory.help,
          ),
        ];
    }
  }

  List<SmartSuggestion> _getDiagnosticSuggestions(String language) {
    switch (language) {
      case 'es-ES':
        return [
          const SmartSuggestion(
            title: 'Diagnóstico',
            description: 'Ejecutar diagnóstico completo del sistema',
            query: 'Ejecutar diagnóstico completo de mi vehículo',
            icon: Icons.search,
            color: Colors.red,
            priority: SuggestionPriority.urgent,
            category: SuggestionCategory.diagnostic,
          ),
        ];
      default:
        return [
          const SmartSuggestion(
            title: 'Diagnostics',
            description: 'Run comprehensive system diagnostics',
            query: 'Run full diagnostics on my vehicle',
            icon: Icons.search,
            color: Colors.red,
            priority: SuggestionPriority.urgent,
            category: SuggestionCategory.diagnostic,
          ),
        ];
    }
  }

  void _handleSuggestionTap(SmartSuggestion suggestion) {
    widget.onSuggestionTap?.call(suggestion.query);
  }
}

/// Smart Suggestion Model
class SmartSuggestion {
  final String title;
  final String description;
  final String query;
  final IconData icon;
  final Color color;
  final SuggestionPriority priority;
  final SuggestionCategory category;

  const SmartSuggestion({
    required this.title,
    required this.description,
    required this.query,
    required this.icon,
    required this.color,
    required this.priority,
    required this.category,
  });
}

/// Suggestion Priority Levels
enum SuggestionPriority {
  normal,
  high,
  urgent,
}

/// Suggestion Categories
enum SuggestionCategory {
  health,
  maintenance,
  diagnostic,
  seasonal,
  help,
  service,
}

