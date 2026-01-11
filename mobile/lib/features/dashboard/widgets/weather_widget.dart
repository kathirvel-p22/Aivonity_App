import 'package:flutter/material.dart';

/// AIVONITY Weather Widget
/// Animated weather display with driving recommendations
class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _sunController;

  // Mock weather data
  final _weatherData = {
    'temperature': 24,
    'condition': 'sunny',
    'humidity': 65,
    'windSpeed': 12,
    'visibility': 10,
    'uvIndex': 6,
    'drivingCondition': 'excellent',
  };

  @override
  void initState() {
    super.initState();

    _cloudController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _sunController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _getWeatherGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getWeatherColor().withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated Background Elements
          _buildAnimatedBackground(),

          // Weather Content
          Column(
            children: [
              // Main Weather Info
              Row(
                children: [
                  // Temperature and Condition
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_weatherData['temperature']}°',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 48,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'C',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _getConditionText(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Weather Icon
                  AnimatedBuilder(
                    animation: _sunController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _sunController.value * 2 * 3.14159,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getWeatherIcon(),
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Weather Details
              Row(
                children: [
                  Expanded(
                    child: _buildWeatherDetail(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: '${_weatherData['humidity']}%',
                    ),
                  ),
                  Expanded(
                    child: _buildWeatherDetail(
                      icon: Icons.air,
                      label: 'Wind',
                      value: '${_weatherData['windSpeed']} km/h',
                    ),
                  ),
                  Expanded(
                    child: _buildWeatherDetail(
                      icon: Icons.visibility,
                      label: 'Visibility',
                      value: '${_weatherData['visibility']} km',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Driving Recommendation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_getDrivingIcon(), color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDrivingRecommendation(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Floating Clouds
          AnimatedBuilder(
            animation: _cloudController,
            builder: (context, child) {
              return Positioned(
                top: 10,
                right: -50 + (_cloudController.value * 100),
                child: const Opacity(
                  opacity: 0.3,
                  child: Icon(Icons.cloud, size: 60, color: Colors.white),
                ),
              );
            },
          ),

          // Smaller Cloud
          AnimatedBuilder(
            animation: _cloudController,
            builder: (context, child) {
              return Positioned(
                top: 40,
                left: -30 + (_cloudController.value * 80),
                child: const Opacity(
                  opacity: 0.2,
                  child: Icon(Icons.cloud, size: 40, color: Colors.white),
                ),
              );
            },
          ),

          // Sparkles for sunny weather
          if (_weatherData['condition'] == 'sunny') ...[
            Positioned(
              top: 20,
              left: 50,
              child: AnimatedBuilder(
                animation: _sunController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.6 + 0.4 * _sunController.value,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 60,
              right: 80,
              child: AnimatedBuilder(
                animation: _sunController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.4 + 0.3 * _sunController.value,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  LinearGradient _getWeatherGradient() {
    switch (_weatherData['condition']) {
      case 'sunny':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
        );
      case 'cloudy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF78909C), Color(0xFF546E7A)],
        );
      case 'rainy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
        );
    }
  }

  Color _getWeatherColor() {
    switch (_weatherData['condition']) {
      case 'sunny':
        return const Color(0xFF29B6F6);
      case 'cloudy':
        return const Color(0xFF546E7A);
      case 'rainy':
        return const Color(0xFF3F51B5);
      default:
        return const Color(0xFF29B6F6);
    }
  }

  IconData _getWeatherIcon() {
    switch (_weatherData['condition']) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
        return Icons.grain;
      default:
        return Icons.wb_sunny;
    }
  }

  String _getConditionText() {
    switch (_weatherData['condition']) {
      case 'sunny':
        return 'Sunny & Clear';
      case 'cloudy':
        return 'Partly Cloudy';
      case 'rainy':
        return 'Light Rain';
      default:
        return 'Clear';
    }
  }

  IconData _getDrivingIcon() {
    switch (_weatherData['drivingCondition']) {
      case 'excellent':
        return Icons.check_circle;
      case 'good':
        return Icons.thumb_up;
      case 'caution':
        return Icons.warning;
      case 'poor':
        return Icons.error;
      default:
        return Icons.check_circle;
    }
  }

  String _getDrivingRecommendation() {
    switch (_weatherData['drivingCondition']) {
      case 'excellent':
        return 'Perfect driving conditions today!';
      case 'good':
        return 'Good conditions for driving';
      case 'caution':
        return 'Drive with caution - reduced visibility';
      case 'poor':
        return 'Avoid driving if possible';
      default:
        return 'Check conditions before driving';
    }
  }
}

