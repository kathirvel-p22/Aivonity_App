/// AIVONITY RCA Report Model
/// Represents a Root Cause Analysis report with detailed findings
class RCAReport {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final RCAStatus status;
  final RCASeverity severity;
  final String category;
  final String vehicleId;
  final List<String> symptoms;
  final List<String> rootCauses;
  final List<String> recommendations;
  final List<String> correctiveActions;
  final Map<String, dynamic>? metadata;

  const RCAReport({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.resolvedAt,
    required this.status,
    required this.severity,
    required this.category,
    required this.vehicleId,
    required this.symptoms,
    required this.rootCauses,
    required this.recommendations,
    required this.correctiveActions,
    this.metadata,
  });

  factory RCAReport.fromJson(Map<String, dynamic> json) {
    return RCAReport(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      status: RCAStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RCAStatus.open,
      ),
      severity: RCASeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => RCASeverity.medium,
      ),
      category: json['category'] as String,
      vehicleId: json['vehicleId'] as String,
      symptoms: (json['symptoms'] as List).cast<String>(),
      rootCauses: (json['rootCauses'] as List).cast<String>(),
      recommendations: (json['recommendations'] as List).cast<String>(),
      correctiveActions: (json['correctiveActions'] as List).cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'status': status.name,
      'severity': severity.name,
      'category': category,
      'vehicleId': vehicleId,
      'symptoms': symptoms,
      'rootCauses': rootCauses,
      'recommendations': recommendations,
      'correctiveActions': correctiveActions,
      'metadata': metadata,
    };
  }

  RCAReport copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? resolvedAt,
    RCAStatus? status,
    RCASeverity? severity,
    String? category,
    String? vehicleId,
    List<String>? symptoms,
    List<String>? rootCauses,
    List<String>? recommendations,
    List<String>? correctiveActions,
    Map<String, dynamic>? metadata,
  }) {
    return RCAReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      vehicleId: vehicleId ?? this.vehicleId,
      symptoms: symptoms ?? this.symptoms,
      rootCauses: rootCauses ?? this.rootCauses,
      recommendations: recommendations ?? this.recommendations,
      correctiveActions: correctiveActions ?? this.correctiveActions,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// RCA Status Enum
enum RCAStatus { open, inProgress, resolved, closed }

/// RCA Severity Enum
enum RCASeverity { low, medium, high, critical }

extension RCAStatusExtension on RCAStatus {
  String get displayName {
    switch (this) {
      case RCAStatus.open:
        return 'Open';
      case RCAStatus.inProgress:
        return 'In Progress';
      case RCAStatus.resolved:
        return 'Resolved';
      case RCAStatus.closed:
        return 'Closed';
    }
  }
}

extension RCASeverityExtension on RCASeverity {
  String get displayName {
    switch (this) {
      case RCASeverity.low:
        return 'Low';
      case RCASeverity.medium:
        return 'Medium';
      case RCASeverity.high:
        return 'High';
      case RCASeverity.critical:
        return 'Critical';
    }
  }
}

