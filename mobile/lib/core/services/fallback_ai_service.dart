import 'dart:math';

/// Fallback AI Service for when external AI APIs are unavailable
/// Provides rule-based responses for common vehicle-related queries
class FallbackAIService {
  static FallbackAIService? _instance;
  static FallbackAIService get instance => _instance ??= FallbackAIService._();

  FallbackAIService._();

  final Random _random = Random();

  /// Get a fallback response for a user message
  String getFallbackResponse(String message, {String language = 'en'}) {
    final lowerMessage = message.toLowerCase();

    // Maintenance related queries
    if (_containsKeywords(
      lowerMessage,
      ['maintenance', 'service', 'oil', 'tire', 'brake', 'check'],
    )) {
      return _getMaintenanceResponse(language);
    }

    // Fuel related queries
    if (_containsKeywords(
      lowerMessage,
      ['fuel', 'gas', 'mileage', 'efficiency', 'mpg', 'consumption'],
    )) {
      return _getFuelResponse(language);
    }

    // Navigation related queries
    if (_containsKeywords(
      lowerMessage,
      ['navigation', 'route', 'directions', 'map', 'location'],
    )) {
      return _getNavigationResponse(language);
    }

    // Emergency related queries
    if (_containsKeywords(
      lowerMessage,
      ['emergency', 'breakdown', 'help', 'accident', 'tow'],
    )) {
      return _getEmergencyResponse(language);
    }

    // Vehicle health queries
    if (_containsKeywords(
      lowerMessage,
      ['health', 'status', 'diagnostic', 'problem', 'issue'],
    )) {
      return _getHealthResponse(language);
    }

    // General greetings
    if (_containsKeywords(
      lowerMessage,
      ['hello', 'hi', 'hey', 'good morning', 'good afternoon'],
    )) {
      return _getGreetingResponse(language);
    }

    // Default response
    return _getDefaultResponse(language);
  }

  /// Get maintenance related response
  String _getMaintenanceResponse(String language) {
    final responses = {
      'en': [
        'For vehicle maintenance, I recommend checking your oil level regularly and scheduling service appointments every 5,000-7,500 miles. Would you like me to help you schedule a maintenance reminder?',
        "Regular maintenance is crucial for your vehicle's longevity. Key items include oil changes, tire rotations, brake inspections, and fluid checks. How can I assist with your maintenance needs?",
        "I can help you track your vehicle's maintenance schedule. Common services include oil changes every 3-6 months, tire rotations every 5,000 miles, and brake inspections annually.",
      ],
      'es': [
        'Para el mantenimiento del vehículo, recomiendo verificar el nivel de aceite regularmente y programar citas de servicio cada 8,000-12,000 km. ¿Le gustaría que le ayude a programar un recordatorio de mantenimiento?',
        'El mantenimiento regular es crucial para la longevidad de su vehículo. Los elementos clave incluyen cambios de aceite, rotación de neumáticos, inspecciones de frenos y verificaciones de fluidos.',
      ],
      'fr': [
        "Pour l'entretien du véhicule, je recommande de vérifier régulièrement le niveau d'huile et de programmer des rendez-vous de service tous les 8 000-12 000 km. Souhaitez-vous que je vous aide à programmer un rappel d'entretien?",
        "L'entretien régulier est crucial pour la longévité de votre véhicule. Les éléments clés incluent les vidanges d'huile, la rotation des pneus, les inspections de freins et les vérifications de fluides.",
      ],
    };

    return _getRandomResponse(responses, language);
  }

  /// Get fuel related response
  String _getFuelResponse(String language) {
    final responses = {
      'en': [
        'To improve fuel efficiency, maintain steady speeds, keep tires properly inflated, and ensure regular maintenance. Your vehicle should get approximately 25-35 MPG depending on driving conditions.',
        'Fuel efficiency tips: avoid rapid acceleration, maintain proper tire pressure, use the correct grade of motor oil, and remove unnecessary weight from your vehicle.',
        'I can help you track your fuel consumption and provide tips to improve mileage. Current average fuel efficiency for similar vehicles is around 28 MPG.',
      ],
      'es': [
        'Para mejorar la eficiencia de combustible, mantenga velocidades constantes, mantenga los neumáticos correctamente inflados y asegure el mantenimiento regular. Su vehículo debería obtener aproximadamente 12-16 km/l dependiendo de las condiciones de conducción.',
        'Consejos de eficiencia de combustible: evite aceleraciones rápidas, mantenga la presión correcta de los neumáticos, use el grado correcto de aceite de motor y remueva peso innecesario de su vehículo.',
      ],
      'fr': [
        "Pour améliorer l'efficacité énergétique, maintenez des vitesses constantes, gardez les pneus correctement gonflés et assurez-vous de l'entretien régulier. Votre véhicule devrait obtenir environ 10-14 l/100km selon les conditions de conduite.",
        "Conseils d'efficacité énergétique : évitez les accélérations rapides, maintenez la pression correcte des pneus, utilisez le bon grade d'huile moteur et retirez le poids inutile de votre véhicule.",
      ],
    };

    return _getRandomResponse(responses, language);
  }

  /// Get navigation related response
  String _getNavigationResponse(String language) {
    final responses = {
      'en': [
        "I can help you with navigation! Please provide your destination and current location, and I'll guide you to the best route. You can also check traffic conditions and find nearby services.",
        'For navigation assistance, I recommend using real-time traffic data and considering current road conditions. Would you like me to help you find directions to a specific location?',
        "Navigation services include route planning, traffic updates, and points of interest. Let me know your destination and I'll provide turn-by-turn directions.",
      ],
      'es': [
        '¡Puedo ayudarte con la navegación! Proporcione su destino y ubicación actual, y le guiaré a la mejor ruta. También puede verificar las condiciones de tráfico y encontrar servicios cercanos.',
        'Para asistencia de navegación, recomiendo usar datos de tráfico en tiempo real y considerar las condiciones actuales de la carretera.',
      ],
      'fr': [
        'Je peux vous aider avec la navigation ! Veuillez fournir votre destination et votre position actuelle, et je vous guiderai vers le meilleur itinéraire. Vous pouvez également vérifier les conditions de trafic et trouver des services à proximité.',
        "Pour l'assistance de navigation, je recommande d'utiliser les données de trafic en temps réel et de considérer les conditions routières actuelles.",
      ],
    };

    return _getRandomResponse(responses, language);
  }

  /// Get emergency related response
  String _getEmergencyResponse(String language) {
    final responses = {
      'en': [
        "In case of emergency, stay calm and call emergency services immediately. I can help you locate the nearest hospital, police station, or towing service. What's your current situation?",
        'For vehicle emergencies, I recommend having roadside assistance. I can help you find the nearest service station, emergency contacts, or guide you through basic troubleshooting steps.',
        'Emergency preparedness is important. I can provide you with emergency contact numbers, help locate services, and guide you through safety procedures. How can I assist you right now?',
      ],
      'es': [
        'En caso de emergencia, manténgase calmado y llame a servicios de emergencia inmediatamente. Puedo ayudarle a localizar el hospital, estación de policía o servicio de remolque más cercano.',
        'Para emergencias vehiculares, recomiendo tener asistencia en carretera. Puedo ayudarle a encontrar la estación de servicio más cercana o contactos de emergencia.',
      ],
      'fr': [
        "En cas d'urgence, restez calme et appelez immédiatement les services d'urgence. Je peux vous aider à localiser l'hôpital, le poste de police ou le service de remorquage le plus proche.",
        "Pour les urgences automobiles, je recommande d'avoir une assistance routière. Je peux vous aider à trouver la station-service la plus proche ou les contacts d'urgence.",
      ],
    };

    return _getRandomResponse(responses, language);
  }

  /// Get vehicle health response
  String _getHealthResponse(String language) {
    final responses = {
      'en': [
        "Vehicle health monitoring is essential for safe driving. I can help you check your vehicle's systems, monitor vital signs, and provide maintenance recommendations. Would you like me to run a diagnostic check?",
        "Your vehicle's health status includes engine performance, battery condition, tire pressure, and fluid levels. I recommend regular check-ups to maintain optimal performance.",
        "I can provide insights into your vehicle's health metrics. Current systems show normal operation, but I recommend scheduling a professional inspection for a comprehensive assessment.",
      ],
      'es': [
        'El monitoreo de la salud del vehículo es esencial para una conducción segura. Puedo ayudarle a verificar los sistemas de su vehículo, monitorear signos vitales y proporcionar recomendaciones de mantenimiento.',
        'El estado de salud de su vehículo incluye el rendimiento del motor, la condición de la batería, la presión de los neumáticos y los niveles de fluidos.',
      ],
      'fr': [
        "La surveillance de l'état du véhicule est essentielle pour une conduite sûre. Je peux vous aider à vérifier les systèmes de votre véhicule, surveiller les signes vitaux et fournir des recommandations d'entretien.",
        "L'état de santé de votre véhicule comprend les performances du moteur, l'état de la batterie, la pression des pneus et les niveaux de fluides.",
      ],
    };

    return _getRandomResponse(responses, language);
  }

  /// Get greeting response
  String _getGreetingResponse(String language) {
    final responses = {
      'en': [
        "Hello! I'm AIVONITY, your vehicle assistant. How can I help you with your vehicle today?",
        "Hi there! I'm here to help you with all your vehicle-related questions and needs. What would you like to know?",
        "Greetings! I'm your AI vehicle companion. I can assist with maintenance, navigation, fuel efficiency, and more. How can I help?",
      ],
      'es': [
        '¡Hola! Soy AIVONITY, su asistente de vehículo. ¿Cómo puedo ayudarle con su vehículo hoy?',
        '¡Hola! Estoy aquí para ayudarle con todas sus preguntas y necesidades relacionadas con el vehículo.',
      ],
      'fr': [
        "Bonjour ! Je suis AIVONITY, votre assistant véhicule. Comment puis-je vous aider avec votre véhicule aujourd'hui ?",
        'Salut ! Je suis là pour vous aider avec toutes vos questions et besoins liés au véhicule.',
      ],
    };

    return _getRandomResponse(responses, language);
  }

  /// Get default response
  String _getDefaultResponse(String language) {
    final responses = {
      'en': [
        "I'm here to help with your vehicle-related questions! I can assist with maintenance, fuel efficiency, navigation, emergency services, and general vehicle information. What would you like to know?",
        'As your vehicle assistant, I can provide information about maintenance schedules, fuel saving tips, navigation help, and emergency contacts. How can I assist you today?',
        'I specialize in vehicle management and can help with various topics including maintenance, diagnostics, navigation, and safety. What specific question do you have?',
      ],
      'es': [
        '¡Estoy aquí para ayudar con sus preguntas relacionadas con el vehículo! Puedo ayudar con mantenimiento, eficiencia de combustible, navegación, servicios de emergencia e información general del vehículo.',
        'Como su asistente de vehículo, puedo proporcionar información sobre horarios de mantenimiento, consejos para ahorrar combustible, ayuda de navegación y contactos de emergencia.',
      ],
      'fr': [
        "Je suis là pour vous aider avec vos questions liées au véhicule ! Je peux vous aider avec l'entretien, l'efficacité énergétique, la navigation, les services d'urgence et les informations générales sur le véhicule.",
        "En tant que votre assistant véhicule, je peux fournir des informations sur les programmes d'entretien, les conseils d'économie de carburant, l'aide à la navigation et les contacts d'urgence.",
      ],
    };

    return _getRandomResponse(responses, language);
  }

  /// Check if message contains any of the keywords
  bool _containsKeywords(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  /// Get a random response from the list for the specified language
  String _getRandomResponse(
    Map<String, List<String>> responses,
    String language,
  ) {
    final languageResponses =
        responses[language] ?? responses['en'] ?? ['I\'m here to help!'];
    return languageResponses[_random.nextInt(languageResponses.length)];
  }

  /// Get supported languages
  List<String> getSupportedLanguages() {
    return ['en', 'es', 'fr'];
  }
}

