/// 用药提醒计划数据模型
class MedicationPlan {
  final String id;
  final String userId;
  final String? medicineId;
  final String medicineName;
  final String? medicineSpecification;
  final String? dosageForm;
  final double dosageValue;
  final String dosageUnit;
  final String dosageDescription;
  final String frequencyType;
  final int? frequencyInterval;
  final int? frequencyTimesPerDay;
  final List<ScheduleItem> schedule;
  final String startDate;
  final String? endDate;
  final double? stockQuantity;
  final String? stockUnit;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicationPlan({
    required this.id,
    required this.userId,
    this.medicineId,
    required this.medicineName,
    this.medicineSpecification,
    this.dosageForm,
    required this.dosageValue,
    required this.dosageUnit,
    this.dosageDescription = '',
    required this.frequencyType,
    this.frequencyInterval,
    this.frequencyTimesPerDay,
    required this.schedule,
    required this.startDate,
    this.endDate,
    this.stockQuantity,
    this.stockUnit,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicationPlan.fromJson(Map<String, dynamic> json) {
    return MedicationPlan(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      medicineId: json['medicineId'],
      medicineName: json['medicineName'] ?? '',
      medicineSpecification: json['medicineSpecification'],
      dosageForm: json['dosageForm'],
      dosageValue: (json['dosageValue'] ?? 1).toDouble(),
      dosageUnit: json['dosageUnit'] ?? '片',
      dosageDescription: json['dosageDescription'] ?? '',
      frequencyType: json['frequencyType'] ?? 'daily',
      frequencyInterval: json['frequencyInterval'],
      frequencyTimesPerDay: json['frequencyTimesPerDay'],
      schedule: (json['schedule'] as List<dynamic>?)
              ?.map((e) => ScheduleItem.fromJson(e))
              .toList() ??
          [],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      stockQuantity: json['stockQuantity']?.toDouble(),
      stockUnit: json['stockUnit'],
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'medicineSpecification': medicineSpecification,
      'dosageForm': dosageForm,
      'dosageValue': dosageValue,
      'dosageUnit': dosageUnit,
      'dosageDescription': dosageDescription,
      'frequencyType': frequencyType,
      'frequencyInterval': frequencyInterval,
      'frequencyTimesPerDay': frequencyTimesPerDay,
      'schedule': schedule.map((e) => e.toJson()).toList(),
      'startDate': startDate,
      'endDate': endDate,
      'stockQuantity': stockQuantity,
      'stockUnit': stockUnit,
      'isActive': isActive,
      'notes': notes,
    };
  }
}

/// 日程项（服药时间+星期）
class ScheduleItem {
  final String time;
  final List<int> daysOfWeek;

  ScheduleItem({
    required this.time,
    required this.daysOfWeek,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      time: json['time'] ?? '08:00',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'daysOfWeek': daysOfWeek,
    };
  }
}
