/// 打卡记录数据模型
class MedicationLog {
  final String id;
  final String planId;
  final String? medicineName;
  final String? dosageDescription;
  final String scheduledTime;
  final String scheduledDate;
  final DateTime? actualTime;
  final String status;
  final int? delayMinutes;
  final String? note;
  final bool isMakeup;

  MedicationLog({
    required this.id,
    required this.planId,
    this.medicineName,
    this.dosageDescription,
    required this.scheduledTime,
    required this.scheduledDate,
    this.actualTime,
    required this.status,
    this.delayMinutes,
    this.note,
    this.isMakeup = false,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] ?? '',
      planId: json['planId'] ?? '',
      medicineName: json['medicineName'],
      dosageDescription: json['dosageDescription'],
      scheduledTime: json['scheduledTime'] ?? '',
      scheduledDate: json['scheduledDate'] ?? '',
      actualTime: json['actualTime'] != null ? DateTime.tryParse(json['actualTime']) : null,
      status: json['status'] ?? 'pending',
      delayMinutes: json['delayMinutes'],
      note: json['note'],
      isMakeup: json['isMakeup'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'medicineName': medicineName,
      'dosageDescription': dosageDescription,
      'scheduledTime': scheduledTime,
      'scheduledDate': scheduledDate,
      'actualTime': actualTime?.toIso8601String(),
      'status': status,
      'delayMinutes': delayMinutes,
      'note': note,
      'isMakeup': isMakeup,
    };
  }

  /// 获取状态标签
  String get statusLabel {
    switch (status) {
      case 'taken':
        return '已服';
      case 'missed':
        return '漏服';
      case 'skipped':
        return '跳过';
      case 'late':
        return isMakeup ? '补服' : '延迟';
      default:
        return '待服';
    }
  }
}

/// 今日用药安排
class TodaySchedule {
  final int total;
  final int completed;
  final int missed;
  final int pending;
  final int progress; // 0-100 百分比
  final List<MedicationLog> pendingItems;
  final List<MedicationLog> completedItems;
  final List<MedicationLog> missedItems;

  TodaySchedule({
    this.total = 0,
    this.completed = 0,
    this.missed = 0,
    this.pending = 0,
    this.progress = 0,
    this.pendingItems = const [],
    this.completedItems = const [],
    this.missedItems = const [],
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) {
    return TodaySchedule(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      missed: json['missed'] ?? 0,
      pending: json['pending'] ?? 0,
      progress: json['progress'] ?? 0,
    );
  }
}
