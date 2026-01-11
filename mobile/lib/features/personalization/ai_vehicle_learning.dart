import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// AI-Powered Vehicle Learning and Personalization System
class AIVehicleLearning extends StatefulWidget {
  const AIVehicleLearning({super.key});

  @override
  State<AIVehicleLearning> createState() => _AIVehicleLearningState();
}

class _AIVehicleLearningState extends State<AIVehicleLearning>
    with TickerProviderStateMixin {
  late AnimationController _learningController;
  late Animation<double> _learningAnimation;

  // Learning state
  final LearningProfile _currentProfile = LearningProfile.adaptive;
  Map<String, dynamic> _learnedPreferences = {};
  List<LearnedPattern> _patterns = [];
  List<Prediction> _predictions = [];
  double _adaptationLevel = 0.0;

  // Personalization data
  final Map<String, double> _featureUsage = {};
  List<UserPreference> _preferences = [];
  List<BehavioralInsight> _insights = [];

  // Real-time learning
  Timer? _learningTimer;
  StreamSubscription? _behaviorSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLearningData();
    _startContinuousLearning();
  }

  void _setupAnimations() {
    _learningController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _learningAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _learningController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeLearningData() {
    _learnedPreferences = {
      'preferredClimateTemp': 72.0,
      'favoriteRoutes': ['home_to_office', 'office_to_home'],
      'drivingStyle': 'moderate',
      'musicGenres': ['rock', 'jazz'],
      'maintenanceReminders': 'gentle',
      'navigationVoice': 'female_en',
      'fuelOptimization': 'eco_focused',
    };

    _patterns = [
      LearnedPattern(
        id: 'pattern_1',
        type: PatternType.driving,
        description: 'Morning commute: Prefers faster routes, cooler climate',
        confidence: 0.89,
        frequency: 0.85,
        lastObserved: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      LearnedPattern(
        id: 'pattern_2',
        type: PatternType.routing,
        description: 'Evening return: Avoids highways, prefers scenic routes',
        confidence: 0.76,
        frequency: 0.92,
        lastObserved: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      LearnedPattern(
        id: 'pattern_3',
        type: PatternType.maintenance,
        description: 'Weekly schedule: Prefers Saturday morning service',
        confidence: 0.95,
        frequency: 0.15,
        lastObserved: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    _predictions = [
      Prediction(
        id: 'pred_1',
        type: PredictionType.route,
        title: 'Morning Route Prediction',
        description:
            'Based on your pattern, you\'ll likely take Route 101 to work',
        confidence: 0.84,
        timestamp: DateTime.now().add(const Duration(hours: 1)),
        actions: ['Prepare Route', 'Adjust Climate'],
      ),
      Prediction(
        id: 'pred_2',
        type: PredictionType.maintenance,
        title: 'Oil Change Reminder',
        description: 'Your driving pattern suggests oil change due in 2 days',
        confidence: 0.91,
        timestamp: DateTime.now().add(const Duration(days: 2)),
        actions: ['Schedule Service', 'Find Nearby Shop'],
      ),
    ];

    _preferences = [
      const UserPreference(
        id: 'pref_1',
        category: 'Climate',
        setting: 'Auto-adjust temperature based on time of day',
        value: 'enabled',
        learned: true,
        confidence: 0.87,
      ),
      const UserPreference(
        id: 'pref_2',
        category: 'Navigation',
        setting: 'Avoid toll roads during peak hours',
        value: 'enabled',
        learned: true,
        confidence: 0.92,
      ),
      const UserPreference(
        id: 'pref_3',
        category: 'Music',
        setting: 'Play upbeat music during morning drives',
        value: 'enabled',
        learned: true,
        confidence: 0.78,
      ),
    ];

    _insights = [
      const BehavioralInsight(
        id: 'insight_1',
        title: 'Eco-Driving Improvement',
        description:
            'Your recent driving shows 15% better fuel efficiency. Keep it up!',
        type: InsightType.positive,
        impact: 0.85,
        recommendation: 'Continue smooth acceleration patterns',
      ),
      const BehavioralInsight(
        id: 'insight_2',
        title: 'Route Optimization Opportunity',
        description: 'Alternative route could save 8 minutes on your commute',
        type: InsightType.suggestion,
        impact: 0.72,
        recommendation: 'Try Route 95 during morning hours',
      ),
    ];

    _calculateAdaptationLevel();
  }

  void _startContinuousLearning() {
    _learningTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _processNewData();
      }
    });
  }

  void _processNewData() {
    // Simulate learning from new driving data
    setState(() {
      _adaptationLevel =
          min(1.0, _adaptationLevel + Random().nextDouble() * 0.02);

      // Add new insights occasionally
      if (Random().nextDouble() < 0.1) {
        final newInsight = BehavioralInsight(
          id: 'insight_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Driving Pattern Detected',
          description: 'AI detected a new route preference pattern',
          type: InsightType.neutral,
          impact: 0.6 + Random().nextDouble() * 0.3,
          recommendation: 'Continue monitoring for consistency',
        );
        _insights.insert(0, newInsight);
        if (_insights.length > 5) {
          _insights.removeLast();
        }
      }
    });
  }

  void _calculateAdaptationLevel() {
    // Calculate how well the system has adapted to user behavior
    final patternConfidence =
        _patterns.fold<double>(0, (sum, p) => sum + p.confidence) /
            _patterns.length;
    final preferenceConfidence = _preferences
            .where((p) => p.learned)
            .fold<double>(0, (sum, p) => sum + p.confidence) /
        max(1, _preferences.where((p) => p.learned).length);

    _adaptationLevel = (patternConfidence + preferenceConfidence) / 2.0;
  }

  void _resetLearning() {
    setState(() {
      _learnedPreferences.clear();
      _patterns.clear();
      _predictions.clear();
      _preferences.clear();
      _insights.clear();
      _adaptationLevel = 0.0;
    });

    // Reinitialize with default data
    _initializeLearningData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI learning data has been reset')),
    );
  }

  @override
  void dispose() {
    _learningController.dispose();
    _learningTimer?.cancel();
    _behaviorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Vehicle Learning'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetConfirmation();
                  break;
                case 'export':
                  _exportLearningData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset Learning Data'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Data'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          _calculateAdaptationLevel();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdaptationOverview(),
              const SizedBox(height: 24),
              _buildLearnedPatterns(),
              const SizedBox(height: 24),
              _buildPredictions(),
              const SizedBox(height: 24),
              _buildPersonalizedPreferences(),
              const SizedBox(height: 24),
              _buildBehavioralInsights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptationOverview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 28, color: Colors.purple),
                const SizedBox(width: 12),
                const Text(
                  'AI Adaptation Level',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentProfile.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentProfile.name,
                    style: TextStyle(
                      color: _currentProfile.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(_adaptationLevel * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const Text(
                        'System Adaptation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: AnimatedBuilder(
                    animation: _learningAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _adaptationLevel,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.purple),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  '${_patterns.length}',
                  'Learned Patterns',
                  Colors.blue,
                ),
                _buildMetricItem(
                  '${_preferences.where((p) => p.learned).length}',
                  'Personalized Settings',
                  Colors.green,
                ),
                _buildMetricItem(
                  '${_predictions.length}',
                  'Active Predictions',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnedPatterns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learned Patterns',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._patterns.map(
          (pattern) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          _getPatternColor(pattern.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPatternIcon(pattern.type),
                      color: _getPatternColor(pattern.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pattern.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Confidence: ${(pattern.confidence * 100).toInt()}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Frequency: ${(pattern.frequency * 100).toInt()}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pattern.confidence > 0.8
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.yellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pattern.confidence > 0.8 ? 'High' : 'Medium',
                      style: TextStyle(
                        color: pattern.confidence > 0.8
                            ? Colors.green
                            : Colors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Predictions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._predictions.map(
          (prediction) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getPredictionColor(prediction.type)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getPredictionIcon(prediction.type),
                          color: _getPredictionColor(prediction.type),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prediction.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(prediction.confidence * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prediction.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: prediction.actions
                        .map(
                          (action) => ActionChip(
                            label: Text(action),
                            onPressed: () => _executePredictionAction(action),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizedPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalized Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._preferences.map(
          (preference) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preference.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preference.setting,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (preference.learned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AI Learned',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Switch(
                        value: preference.value == 'enabled',
                        onChanged: (value) =>
                            _togglePreference(preference.id, value),
                        activeThumbColor: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBehavioralInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Behavioral Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._insights.map(
          (insight) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          _getInsightColor(insight.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getInsightIcon(insight.type),
                      color: _getInsightColor(insight.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.recommendation,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset AI Learning'),
        content: const Text(
          'This will clear all learned patterns and preferences. The AI will need to relearn your behavior from scratch. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetLearning();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _exportLearningData() {
    // Simulate data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Learning data exported successfully')),
    );
  }

  void _executePredictionAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Executed: $action')),
    );
  }

  void _togglePreference(String preferenceId, bool enabled) {
    setState(() {
      final index = _preferences.indexWhere((p) => p.id == preferenceId);
      if (index != -1) {
        _preferences[index] = UserPreference(
          id: _preferences[index].id,
          category: _preferences[index].category,
          setting: _preferences[index].setting,
          value: enabled ? 'enabled' : 'disabled',
          learned: _preferences[index].learned,
          confidence: _preferences[index].confidence,
        );
      }
    });
  }

  Color _getPatternColor(PatternType type) {
    switch (type) {
      case PatternType.driving:
        return Colors.blue;
      case PatternType.routing:
        return Colors.green;
      case PatternType.maintenance:
        return Colors.orange;
    }
  }

  IconData _getPatternIcon(PatternType type) {
    switch (type) {
      case PatternType.driving:
        return Icons.drive_eta;
      case PatternType.routing:
        return Icons.route;
      case PatternType.maintenance:
        return Icons.build;
    }
  }

  Color _getPredictionColor(PredictionType type) {
    switch (type) {
      case PredictionType.route:
        return Colors.blue;
      case PredictionType.maintenance:
        return Colors.orange;
      case PredictionType.driving:
        return Colors.green;
    }
  }

  IconData _getPredictionIcon(PredictionType type) {
    switch (type) {
      case PredictionType.route:
        return Icons.directions;
      case PredictionType.maintenance:
        return Icons.settings;
      case PredictionType.driving:
        return Icons.speed;
    }
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Colors.green;
      case InsightType.negative:
        return Colors.red;
      case InsightType.suggestion:
        return Colors.blue;
      case InsightType.neutral:
        return Colors.grey;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.thumb_up;
      case InsightType.negative:
        return Icons.thumb_down;
      case InsightType.suggestion:
        return Icons.lightbulb;
      case InsightType.neutral:
        return Icons.info;
    }
  }
}

// Data Models
enum LearningProfile { adaptive, conservative, aggressive }

enum PatternType { driving, routing, maintenance }

enum PredictionType { route, maintenance, driving }

enum InsightType { positive, negative, suggestion, neutral }

extension LearningProfileExtension on LearningProfile {
  String get name {
    switch (this) {
      case LearningProfile.adaptive:
        return 'Adaptive';
      case LearningProfile.conservative:
        return 'Conservative';
      case LearningProfile.aggressive:
        return 'Aggressive';
    }
  }

  Color get color {
    switch (this) {
      case LearningProfile.adaptive:
        return Colors.blue;
      case LearningProfile.conservative:
        return Colors.green;
      case LearningProfile.aggressive:
        return Colors.red;
    }
  }
}

class LearnedPattern {
  final String id;
  final PatternType type;
  final String description;
  final double confidence; // 0.0-1.0
  final double frequency; // 0.0-1.0
  final DateTime lastObserved;

  const LearnedPattern({
    required this.id,
    required this.type,
    required this.description,
    required this.confidence,
    required this.frequency,
    required this.lastObserved,
  });
}

class Prediction {
  final String id;
  final PredictionType type;
  final String title;
  final String description;
  final double confidence; // 0.0-1.0
  final DateTime timestamp;
  final List<String> actions;

  const Prediction({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.timestamp,
    required this.actions,
  });
}

class UserPreference {
  final String id;
  final String category;
  final String setting;
  final String value;
  final bool learned;
  final double confidence; // 0.0-1.0

  const UserPreference({
    required this.id,
    required this.category,
    required this.setting,
    required this.value,
    required this.learned,
    required this.confidence,
  });
}

class BehavioralInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final double impact; // 0.0-1.0
  final String recommendation;

  const BehavioralInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.recommendation,
  });
}

