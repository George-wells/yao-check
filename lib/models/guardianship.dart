/// 监护关系数据模型
class Guardianship {
  final String id;
  final String guardianId;
  final String patientId;
  final String? patientName;
  final String relationship;
  final bool canViewMedications;
  final bool canViewCheckins;
  final bool canReceiveNotifications;
  final String status;
  final DateTime? confirmedAt;
  final DateTime? createdAt;

  Guardianship({
    required this.id,
    required this.guardianId,
    required this.patientId,
    this.patientName,
    required this.relationship,
    this.canViewMedications = true,
    this.canViewCheckins = true,
    this.canReceiveNotifications = true,
    this.status = 'pending',
    this.confirmedAt,
    this.createdAt,
  });

  factory Guardianship.fromJson(Map<String, dynamic> json) {
    return Guardianship(
      id: json['id'] ?? '',
      guardianId: json['guardianId'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'],
      relationship: json['relationship'] ?? 'other',
      canViewMedications: json['canViewMedications'] ?? true,
      canViewCheckins: json['canViewCheckins'] ?? true,
      canReceiveNotifications: json['canReceiveNotifications'] ?? true,
      status: json['status'] ?? 'pending',
      confirmedAt: json['confirmedAt'] != null ? DateTime.tryParse(json['confirmedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  /// 获取关系标签
  String get relationshipLabel {
    switch (relationship) {
      case 'spouse':
        return '配偶';
      case 'child':
        return '子女';
      case 'parent':
        return '父母';
      case 'sibling':
        return '兄弟姐妹';
      case 'relative':
        return '亲戚';
      case 'caregiver':
        return '照护者';
      default:
        return '其他';
    }
  }
}

/// 被监护人用药摘要
class GuardianPatientSummary {
  final String patientId;
  final String patientName;
  final String relationship;
  final int total;
  final int completed;
  final int missed;
  final double complianceRate;

  GuardianPatientSummary({
    required this.patientId,
    required this.patientName,
    required this.relationship,
    this.total = 0,
    this.completed = 0,
    this.missed = 0,
    this.complianceRate = 0,
  });

  factory GuardianPatientSummary.fromJson(Map<String, dynamic> json) {
    final todaySummary = json['todaySummary'] as Map<String, dynamic>? ?? {};
    return GuardianPatientSummary(
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      relationship: json['relationship'] ?? '',
      total: todaySummary['total'] ?? 0,
      completed: todaySummary['completed'] ?? 0,
      missed: todaySummary['missed'] ?? 0,
      complianceRate: (json['complianceRate'] ?? 0).toDouble(),
    );
  }
}

/// 用药报告
class GuardianReport {
  final String patientName;
  final String relationship;
  final int totalDoses;
  final int completedDoses;
  final int missedDoses;
  final double complianceRate;
  final List<DailyTrend> trend;

  GuardianReport({
    required this.patientName,
    required this.relationship,
    this.totalDoses = 0,
    this.completedDoses = 0,
    this.missedDoses = 0,
    this.complianceRate = 0,
    this.trend = const [],
  });

  factory GuardianReport.fromJson(Map<String, dynamic> json) {
    return GuardianReport(
      patientName: json['patient']?['name'] ?? '',
      relationship: json['relationship'] ?? '',
      totalDoses: json['summary']?['totalDoses'] ?? 0,
      completedDoses: json['summary']?['completedDoses'] ?? 0,
      missedDoses: json['summary']?['missedDoses'] ?? 0,
      complianceRate: (json['summary']?['complianceRate'] ?? 0).toDouble(),
      trend: (json['trend'] as List<dynamic>?)
              ?.map((e) => DailyTrend.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 每日趋势
class DailyTrend {
  final String date;
  final int total;
  final int completed;
  final double rate;

  DailyTrend({
    required this.date,
    this.total = 0,
    this.completed = 0,
    this.rate = 0,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['scheduledDate'] ?? '',
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }
}
