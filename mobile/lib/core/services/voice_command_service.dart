import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Voice Command Recognition and Processing Service
/// Processes voice input to identify and execute specific vehicle-related commands
class VoiceCommandService extends ChangeNotifier {
  static VoiceCommandService? _instance;
  static VoiceCommandService get instance =>
      _instance ??= VoiceCommandService._();

  VoiceCommandService._();

  final Logger _logger = Logger();

  // Command patterns and their associated actions
  final Map<VoiceCommandType, List<String>> _commandPatterns = {
    VoiceCommandType.checkHealth: [
      'check health',
      'vehicle health',
      'how is my car',
      'car status',
      'health status',
      'diagnostic check',
      'check diagnostics',
      'vehicle condition',
    ],
    VoiceCommandType.lockDoors: [
      'lock the doors',
      'lock doors',
      'lock car',
      'secure vehicle',
      'lock vehicle',
      'doors lock',
    ],
    VoiceCommandType.unlockDoors: [
      'unlock the doors',
      'unlock doors',
      'unlock car',
      'unlock vehicle',
      'doors unlock',
      'open doors',
    ],
    VoiceCommandType.startEngine: [
      'start the engine',
      'start engine',
      'turn on car',
      'start vehicle',
      'engine start',
      'ignition on',
    ],
    VoiceCommandType.stopEngine: [
      'stop the engine',
      'stop engine',
      'turn off car',
      'stop vehicle',
      'engine stop',
      'ignition off',
    ],
    VoiceCommandType.climateControl: [
      'turn on ac',
      'turn off ac',
      'air conditioning',
      'climate control',
      'heat on',
      'heat off',
      'temperature',
      'set temperature',
      'cool the car',
      'warm the car',
    ],
    VoiceCommandType.lightsControl: [
      'turn on lights',
      'turn off lights',
      'lights on',
      'lights off',
      'headlights',
      'parking lights',
      'interior lights',
    ],
    VoiceCommandType.emergencyCall: [
      'emergency',
      'call emergency',
      'emergency call',
      'help me',
      'accident',
      'breakdown',
      'emergency services',
      'call for help',
    ],
    VoiceCommandType.hazardLights: [
      'hazard lights',
      'flashers on',
      'flashers off',
      'emergency lights',
      'warning lights',
    ],
    VoiceCommandType.scheduleMaintenance: [
      'schedule maintenance',
      'book service',
      'maintenance appointment',
      'service appointment',
      'schedule service',
      'book maintenance',
      'need service',
      'maintenance due',
    ],
    VoiceCommandType.checkFuelEfficiency: [
      'fuel efficiency',
      'gas mileage',
      'fuel consumption',
      'mpg',
      'fuel economy',
      'how much fuel',
      'fuel usage',
      'efficiency report',
    ],
    VoiceCommandType.findServiceCenter: [
      'find service center',
      'nearest garage',
      'service centers nearby',
      'find mechanic',
      'repair shop',
      'auto service',
      'car service near me',
      'closest service',
    ],
    VoiceCommandType.navigate: [
      'navigate to',
      'directions to',
      'take me to',
      'route to',
      'how to get to',
      'drive to',
      'go to',
      'navigation',
    ],
    VoiceCommandType.checkAlerts: [
      'check alerts',
      'any alerts',
      'warning lights',
      'notifications',
      'problems',
      'issues',
      'error messages',
      'alerts status',
    ],
    VoiceCommandType.fuelLevel: [
      'fuel level',
      'gas level',
      'how much fuel',
      'fuel remaining',
      'gas remaining',
      'fuel tank',
      'gas tank',
      'fuel status',
    ],
    VoiceCommandType.batteryStatus: [
      'battery status',
      'battery level',
      'battery health',
      'battery charge',
      'electrical system',
      'battery condition',
      'charging status',
    ],
    VoiceCommandType.tireStatus: [
      'tire pressure',
      'tire status',
      'tire condition',
      'wheel pressure',
      'tire health',
      'check tires',
      'tire monitoring',
    ],
    VoiceCommandType.engineStatus: [
      'engine status',
      'engine health',
      'engine condition',
      'motor status',
      'engine performance',
      'engine diagnostics',
      'engine check',
    ],
    VoiceCommandType.maintenanceHistory: [
      'maintenance history',
      'service history',
      'repair history',
      'past maintenance',
      'previous service',
      'maintenance records',
      'service records',
    ],
    VoiceCommandType.help: [
      'help',
      'what can you do',
      'commands',
      'assistance',
      'how to use',
      'voice commands',
      'available commands',
    ],
  };

  /// Process voice input and identify commands
  Future<VoiceCommandResult> processVoiceInput(String input) async {
    try {
      _logger.i('Processing voice input: $input');

      final normalizedInput = _normalizeInput(input);
      final command = _identifyCommand(normalizedInput);
      final parameters = _extractParameters(normalizedInput, command);

      final result = VoiceCommandResult(
        command: command,
        originalInput: input,
        normalizedInput: normalizedInput,
        parameters: parameters,
        confidence: _calculateConfidence(normalizedInput, command),
        timestamp: DateTime.now(),
      );

      _logger.i(
        'Command identified: ${command.name} (confidence: ${result.confidence})',
      );
      return result;
    } catch (e) {
      _logger.e('Error processing voice input: $e');
      return VoiceCommandResult(
        command: VoiceCommandType.unknown,
        originalInput: input,
        normalizedInput: input.toLowerCase(),
        parameters: {},
        confidence: 0.0,
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Normalize input text for better matching
  String _normalizeInput(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Identify the command type from normalized input
  VoiceCommandType _identifyCommand(String normalizedInput) {
    double bestScore = 0.0;
    VoiceCommandType bestCommand = VoiceCommandType.unknown;

    for (final entry in _commandPatterns.entries) {
      final commandType = entry.key;
      final patterns = entry.value;

      for (final pattern in patterns) {
        final score = _calculateMatchScore(normalizedInput, pattern);
        if (score > bestScore) {
          bestScore = score;
          bestCommand = commandType;
        }
      }
    }

    // Require minimum confidence threshold
    return bestScore >= 0.6 ? bestCommand : VoiceCommandType.unknown;
  }

  /// Calculate match score between input and pattern
  double _calculateMatchScore(String input, String pattern) {
    // Exact match
    if (input == pattern) return 1.0;

    // Contains pattern
    if (input.contains(pattern)) return 0.9;

    // Pattern contains input (partial match)
    if (pattern.contains(input)) return 0.7;

    // Word-based matching
    final inputWords = input.split(' ');
    final patternWords = pattern.split(' ');

    int matchingWords = 0;
    for (final word in patternWords) {
      if (inputWords.contains(word)) {
        matchingWords++;
      }
    }

    if (matchingWords == 0) return 0.0;

    // Calculate score based on matching words ratio
    final score = matchingWords / patternWords.length;
    return score >= 0.5 ? score * 0.8 : 0.0; // Reduce score for partial matches
  }

  /// Extract parameters from the input based on command type
  Map<String, dynamic> _extractParameters(
    String input,
    VoiceCommandType command,
  ) {
    final parameters = <String, dynamic>{};

    switch (command) {
      case VoiceCommandType.navigate:
        // Extract destination
        final destination = _extractDestination(input);
        if (destination != null) {
          parameters['destination'] = destination;
        }
        break;

      case VoiceCommandType.scheduleMaintenance:
        // Extract service type and timing
        final serviceType = _extractServiceType(input);
        final timing = _extractTiming(input);
        if (serviceType != null) parameters['serviceType'] = serviceType;
        if (timing != null) parameters['timing'] = timing;
        break;

      case VoiceCommandType.findServiceCenter:
        // Extract service type and location
        final serviceType = _extractServiceType(input);
        final location = _extractLocation(input);
        if (serviceType != null) parameters['serviceType'] = serviceType;
        if (location != null) parameters['location'] = location;
        break;

      case VoiceCommandType.climateControl:
        // Extract temperature or action
        final temperature = _extractTemperature(input);
        final action = _extractClimateAction(input);
        if (temperature != null) parameters['temperature'] = temperature;
        if (action != null) parameters['action'] = action;
        break;

      case VoiceCommandType.lightsControl:
        // Extract light type and action
        final lightType = _extractLightType(input);
        final action = _extractOnOffAction(input);
        if (lightType != null) parameters['lightType'] = lightType;
        if (action != null) parameters['action'] = action;
        break;

      case VoiceCommandType.emergencyCall:
        // Extract emergency type
        final emergencyType = _extractEmergencyType(input);
        if (emergencyType != null) parameters['emergencyType'] = emergencyType;
        break;

      default:
        // No specific parameters for other commands
        break;
    }

    return parameters;
  }

  /// Extract destination from navigation command
  String? _extractDestination(String input) {
    final patterns = [
      RegExp(
        r'(?:navigate to|directions to|take me to|route to|go to)\s+(.+)',
        caseSensitive: false,
      ),
      RegExp(r'(?:how to get to|drive to)\s+(.+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }

  /// Extract service type from maintenance/service commands
  String? _extractServiceType(String input) {
    final serviceTypes = {
      'oil change': ['oil change', 'oil service', 'change oil'],
      'tire service': ['tire', 'wheel', 'tire pressure', 'tire rotation'],
      'brake service': ['brake', 'brakes', 'brake pad', 'brake check'],
      'battery service': ['battery', 'electrical', 'charging'],
      'engine service': ['engine', 'motor', 'engine check'],
      'general maintenance': [
        'maintenance',
        'service',
        'checkup',
        'inspection',
      ],
    };

    for (final entry in serviceTypes.entries) {
      final serviceType = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (input.contains(keyword)) {
          return serviceType;
        }
      }
    }

    return null;
  }

  /// Extract timing information
  String? _extractTiming(String input) {
    final timingPatterns = [
      RegExp(
        r'\b(today|tomorrow|this week|next week|asap|urgent|emergency)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        caseSensitive: false,
      ),
      RegExp(r'\b(\d{1,2}:\d{2})\b'), // Time format
    ];

    for (final pattern in timingPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null && match.group(0) != null) {
        return match.group(0)!.toLowerCase();
      }
    }

    return null;
  }

  /// Extract location information
  String? _extractLocation(String input) {
    final locationPatterns = [
      RegExp(r'(?:near|nearby|close to|around)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:in|at)\s+([a-zA-Z\s]+)', caseSensitive: false),
    ];

    for (final pattern in locationPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }

  /// Extract temperature from climate control commands
  int? _extractTemperature(String input) {
    final tempPattern =
        RegExp(r'(\d{1,2})\s*(?:degrees?|°|deg)', caseSensitive: false);
    final match = tempPattern.firstMatch(input);
    if (match != null && match.group(1) != null) {
      final temp = int.tryParse(match.group(1)!);
      if (temp != null && temp >= 60 && temp <= 85) {
        // Reasonable temperature range
        return temp;
      }
    }
    return null;
  }

  /// Extract climate action (on/off/set)
  String? _extractClimateAction(String input) {
    if (input.contains('turn on') ||
        input.contains('start') ||
        input.contains('enable')) {
      return 'on';
    } else if (input.contains('turn off') ||
        input.contains('stop') ||
        input.contains('disable')) {
      return 'off';
    } else if (input.contains('set') || input.contains('change')) {
      return 'set';
    }
    return null;
  }

  /// Extract light type from lights control commands
  String? _extractLightType(String input) {
    if (input.contains('headlight') || input.contains('headlights')) {
      return 'headlights';
    } else if (input.contains('parking') || input.contains('park')) {
      return 'parking';
    } else if (input.contains('interior') || input.contains('inside')) {
      return 'interior';
    } else if (input.contains('fog')) {
      return 'fog';
    }
    return 'all'; // Default to all lights
  }

  /// Extract on/off action
  String? _extractOnOffAction(String input) {
    if (input.contains('turn on') || input.contains('on')) {
      return 'on';
    } else if (input.contains('turn off') || input.contains('off')) {
      return 'off';
    }
    return null;
  }

  /// Extract emergency type
  String? _extractEmergencyType(String input) {
    if (input.contains('accident') || input.contains('crash')) {
      return 'accident';
    } else if (input.contains('breakdown') || input.contains('broken')) {
      return 'breakdown';
    } else if (input.contains('medical') || input.contains('health')) {
      return 'medical';
    } else if (input.contains('theft') || input.contains('stolen')) {
      return 'theft';
    }
    return 'general';
  }

  /// Calculate confidence score for the identified command
  double _calculateConfidence(String input, VoiceCommandType command) {
    if (command == VoiceCommandType.unknown) return 0.0;

    final patterns = _commandPatterns[command] ?? [];
    double maxScore = 0.0;

    for (final pattern in patterns) {
      final score = _calculateMatchScore(input, pattern);
      if (score > maxScore) {
        maxScore = score;
      }
    }

    return maxScore;
  }

  /// Get available commands with descriptions
  List<VoiceCommandInfo> getAvailableCommands() {
    return [
      const VoiceCommandInfo(
        type: VoiceCommandType.checkHealth,
        name: 'Check Vehicle Health',
        description: 'Check your vehicle\'s overall health and diagnostics',
        examples: ['Check health', 'How is my car', 'Vehicle status'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.scheduleMaintenance,
        name: 'Schedule Maintenance',
        description: 'Schedule or book a maintenance appointment',
        examples: ['Schedule maintenance', 'Book service', 'Need oil change'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.checkFuelEfficiency,
        name: 'Check Fuel Efficiency',
        description: 'Get information about fuel consumption and efficiency',
        examples: ['Fuel efficiency', 'Gas mileage', 'MPG report'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.findServiceCenter,
        name: 'Find Service Center',
        description: 'Locate nearby service centers and repair shops',
        examples: [
          'Find service center',
          'Nearest garage',
          'Auto service near me',
        ],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.navigate,
        name: 'Navigation',
        description: 'Get directions to a specific location',
        examples: [
          'Navigate to downtown',
          'Directions to the mall',
          'Take me home',
        ],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.checkAlerts,
        name: 'Check Alerts',
        description: 'Review current alerts and notifications',
        examples: ['Check alerts', 'Any problems', 'Warning lights'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.lockDoors,
        name: 'Lock Doors',
        description: 'Lock all vehicle doors remotely',
        examples: ['Lock the doors', 'Secure vehicle', 'Lock car'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.unlockDoors,
        name: 'Unlock Doors',
        description: 'Unlock all vehicle doors remotely',
        examples: ['Unlock the doors', 'Open doors', 'Unlock car'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.startEngine,
        name: 'Start Engine',
        description: 'Start the vehicle engine remotely',
        examples: ['Start the engine', 'Turn on car', 'Start vehicle'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.stopEngine,
        name: 'Stop Engine',
        description: 'Stop the vehicle engine remotely',
        examples: ['Stop the engine', 'Turn off car', 'Stop vehicle'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.climateControl,
        name: 'Climate Control',
        description: 'Control air conditioning and heating',
        examples: ['Turn on AC', 'Set temperature to 72', 'Heat on'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.lightsControl,
        name: 'Lights Control',
        description: 'Control vehicle lights',
        examples: ['Turn on lights', 'Headlights on', 'Parking lights off'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.emergencyCall,
        name: 'Emergency Call',
        description: 'Make emergency call for assistance',
        examples: ['Emergency', 'Call for help', 'Accident'],
      ),
      const VoiceCommandInfo(
        type: VoiceCommandType.hazardLights,
        name: 'Hazard Lights',
        description: 'Control hazard warning lights',
        examples: ['Hazard lights on', 'Flashers on', 'Emergency lights'],
      ),
    ];
  }

  /// Get command suggestions based on partial input
  List<String> getCommandSuggestions(String partialInput) {
    final suggestions = <String>[];
    final normalizedInput = _normalizeInput(partialInput);

    if (normalizedInput.isEmpty) {
      return [
        'Check vehicle health',
        'Schedule maintenance',
        'Find service center',
        'Check fuel efficiency',
      ];
    }

    for (final entry in _commandPatterns.entries) {
      final patterns = entry.value;
      for (final pattern in patterns) {
        if (pattern.startsWith(normalizedInput) ||
            pattern.contains(normalizedInput)) {
          suggestions.add(pattern);
        }
      }
    }

    return suggestions.take(5).toList();
  }
}

/// Voice Command Types
enum VoiceCommandType {
  checkHealth,
  scheduleMaintenance,
  checkFuelEfficiency,
  findServiceCenter,
  navigate,
  checkAlerts,
  fuelLevel,
  batteryStatus,
  tireStatus,
  engineStatus,
  maintenanceHistory,
  help,
  // Vehicle control commands
  lockDoors,
  unlockDoors,
  startEngine,
  stopEngine,
  climateControl,
  lightsControl,
  emergencyCall,
  hazardLights,
  unknown,
}

/// Voice Command Result
class VoiceCommandResult {
  final VoiceCommandType command;
  final String originalInput;
  final String normalizedInput;
  final Map<String, dynamic> parameters;
  final double confidence;
  final DateTime timestamp;
  final String? error;

  const VoiceCommandResult({
    required this.command,
    required this.originalInput,
    required this.normalizedInput,
    required this.parameters,
    required this.confidence,
    required this.timestamp,
    this.error,
  });

  bool get isSuccess => error == null && command != VoiceCommandType.unknown;

  @override
  String toString() {
    return 'VoiceCommandResult(command: ${command.name}, confidence: $confidence, parameters: $parameters)';
  }
}

/// Voice Command Information
class VoiceCommandInfo {
  final VoiceCommandType type;
  final String name;
  final String description;
  final List<String> examples;

  const VoiceCommandInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.examples,
  });
}

