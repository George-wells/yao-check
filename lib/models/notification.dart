/// 通知数据模型
class AppNotification {
  final String id;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      notificationType: json['notificationType'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  /// 获取通知类型标签
  String get typeLabel {
    switch (notificationType) {
      case 'medication_reminder':
        return '用药提醒';
      case 'missed_dose':
        return '漏服提醒';
      case 'makeup_reminder':
        return '补服提醒';
      case 'guardian_missed_dose':
        return '家人漏服通知';
      case 'prescription_expiry':
        return '处方到期';
      case 'refill_reminder':
        return '续方提醒';
      case 'interaction_warning':
        return '相互作用警告';
      case 'side_effect_tip':
        return '副作用提示';
      case 'care_message':
        return '关怀提醒';
      default:
        return '系统通知';
    }
  }
}
