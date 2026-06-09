/// 用药状态枚举
enum MedicationStatus {
  pending('待服', 'pending'),
  taken('已服', 'taken'),
  missed('漏服', 'missed'),
  skipped('跳过', 'skipped'),
  late('延迟', 'late'),
  makeup('补服', 'late');

  final String label;
  final String apiValue;
  const MedicationStatus(this.label, this.apiValue);

  static MedicationStatus fromApi(String value) {
    return MedicationStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => MedicationStatus.pending,
    );
  }
}

/// 频率类型
enum FrequencyType {
  daily('每日一次', 'daily'),
  everyNHours('每N小时', 'every_n_hours'),
  specificDays('特定日期', 'specific_days'),
  asNeeded('按需', 'as_needed');

  final String label;
  final String apiValue;
  const FrequencyType(this.label, this.apiValue);

  static FrequencyType fromApi(String value) {
    return FrequencyType.values.firstWhere(
      (f) => f.apiValue == value,
      orElse: () => FrequencyType.daily,
    );
  }
}

/// 监护关系类型
enum RelationshipType {
  spouse('配偶', 'spouse'),
  child('子女', 'child'),
  parent('父母', 'parent'),
  sibling('兄弟姐妹', 'sibling'),
  relative('亲戚', 'relative'),
  caregiver('照护者', 'caregiver'),
  other('其他', 'other');

  final String label;
  final String apiValue;
  const RelationshipType(this.label, this.apiValue);

  static RelationshipType fromApi(String value) {
    return RelationshipType.values.firstWhere(
      (r) => r.apiValue == value,
      orElse: () => RelationshipType.other,
    );
  }
}

/// 处方状态
enum PrescriptionStatus {
  active('有效', 'active'),
  expired('已过期', 'expired'),
  archived('已归档', 'archived');

  final String label;
  final String apiValue;
  const PrescriptionStatus(this.label, this.apiValue);

  static PrescriptionStatus fromApi(String value) {
    return PrescriptionStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => PrescriptionStatus.active,
    );
  }
}

/// 通知类型
enum NotificationType {
  medicationReminder('用药提醒', 'medication_reminder'),
  missedDose('漏服提醒', 'missed_dose'),
  makeupReminder('补服提醒', 'makeup_reminder'),
  guardianMissedDose('家人漏服通知', 'guardian_missed_dose'),
  prescriptionExpiry('处方到期', 'prescription_expiry'),
  refillReminder('续方提醒', 'refill_reminder'),
  interactionWarning('相互作用警告', 'interaction_warning'),
  sideEffectTip('副作用提示', 'side_effect_tip'),
  careMessage('关怀提醒', 'care_message'),
  systemNotification('系统通知', 'system_notification');

  final String label;
  final String apiValue;
  const NotificationType(this.label, this.apiValue);

  static NotificationType fromApi(String value) {
    return NotificationType.values.firstWhere(
      (n) => n.apiValue == value,
      orElse: () => NotificationType.systemNotification,
    );
  }
}

/// 药物相互作用风险等级
enum InteractionSeverity {
  high('高风险', 'high', 5),
  medium('中风险', 'medium', 3),
  low('低风险', 'low', 1);

  final String label;
  final String apiValue;
  final int level;
  const InteractionSeverity(this.label, this.apiValue, this.level);

  static InteractionSeverity fromApi(String value) {
    return InteractionSeverity.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => InteractionSeverity.low,
    );
  }
}
