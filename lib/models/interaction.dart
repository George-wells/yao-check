/// 药物相互作用结果
class InteractionResult {
  final List<InteractionItem> interactions;
  final InteractionSummary summary;

  InteractionResult({
    this.interactions = const [],
    required this.summary,
  });

  factory InteractionResult.fromJson(Map<String, dynamic> json) {
    return InteractionResult(
      interactions: (json['interactions'] as List<dynamic>?)
              ?.map((e) => InteractionItem.fromJson(e))
              .toList() ??
          [],
      summary: InteractionSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

/// 单条相互作用
class InteractionItem {
  final String id;
  final String severity;
  final int severityLevel;
  final String description;
  final String? mechanism;
  final String? clinicalManagement;
  final String? symptoms;
  final String medicineAName;
  final String medicineBName;

  InteractionItem({
    required this.id,
    required this.severity,
    required this.severityLevel,
    required this.description,
    this.mechanism,
    this.clinicalManagement,
    this.symptoms,
    required this.medicineAName,
    required this.medicineBName,
  });

  factory InteractionItem.fromJson(Map<String, dynamic> json) {
    return InteractionItem(
      id: json['id'] ?? '',
      severity: json['severity'] ?? 'low',
      severityLevel: json['severityLevel'] ?? 1,
      description: json['description'] ?? '',
      mechanism: json['mechanism'],
      clinicalManagement: json['clinicalManagement'],
      symptoms: json['symptoms'],
      medicineAName: json['medicineAName'] ?? '',
      medicineBName: json['medicineBName'] ?? '',
    );
  }

  /// 获取风险等级颜色
  String get severityLabel {
    switch (severity) {
      case 'high':
        return '高风险';
      case 'medium':
        return '中风险';
      case 'low':
        return '低风险';
      default:
        return '未知';
    }
  }
}

/// 相互作用汇总
class InteractionSummary {
  final int total;
  final int high;
  final int medium;
  final int low;

  InteractionSummary({
    this.total = 0,
    this.high = 0,
    this.medium = 0,
    this.low = 0,
  });

  factory InteractionSummary.fromJson(Map<String, dynamic> json) {
    return InteractionSummary(
      total: json['total'] ?? 0,
      high: json['high'] ?? 0,
      medium: json['medium'] ?? 0,
      low: json['low'] ?? 0,
    );
  }
}
