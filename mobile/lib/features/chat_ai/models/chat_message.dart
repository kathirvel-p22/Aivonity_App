/// AIVONITY Chat Message Model
/// Represents a single chat message with metadata
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isDelivered;
  final bool isRead;
  final String? vehicleContext;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isDelivered = true,
    this.isRead = false,
    this.vehicleContext,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isDelivered: json['isDelivered'] as bool? ?? true,
      isRead: json['isRead'] as bool? ?? false,
      vehicleContext: json['vehicleContext'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isDelivered': isDelivered,
      'isRead': isRead,
      'vehicleContext': vehicleContext,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isDelivered,
    bool? isRead,
    String? vehicleContext,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      vehicleContext: vehicleContext ?? this.vehicleContext,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Chat Message Type Enum
enum ChatMessageType { text, voice, image, vehicleData, alert, recommendation }

/// Chat Context Model for vehicle-specific conversations
class ChatContext {
  final String? vehicleId;
  final String? currentLocation;
  final Map<String, dynamic>? vehicleStatus;
  final List<String>? activeAlerts;
  final String? lastMaintenanceDate;

  const ChatContext({
    this.vehicleId,
    this.currentLocation,
    this.vehicleStatus,
    this.activeAlerts,
    this.lastMaintenanceDate,
  });

  factory ChatContext.fromJson(Map<String, dynamic> json) {
    return ChatContext(
      vehicleId: json['vehicleId'] as String?,
      currentLocation: json['currentLocation'] as String?,
      vehicleStatus: json['vehicleStatus'] as Map<String, dynamic>?,
      activeAlerts: (json['activeAlerts'] as List?)?.cast<String>(),
      lastMaintenanceDate: json['lastMaintenanceDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'currentLocation': currentLocation,
      'vehicleStatus': vehicleStatus,
      'activeAlerts': activeAlerts,
      'lastMaintenanceDate': lastMaintenanceDate,
    };
  }
}

