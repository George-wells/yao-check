/// API 接口路径常量
class ApiEndpoints {
  ApiEndpoints._();

  // ==================== 认证 ====================
  static const String sendCode = '/auth/send-code';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ==================== 用户 ====================
  static const String userProfile = '/users/profile';
  static const String elderlyPreferences = '/users/elderly-preferences';
  static const String userStats = '/users/stats';

  // ==================== 药品 ====================
  static const String medicines = '/medicines';
  static String medicineDetail(String id) => '/medicines/$id';
  static String medicineByBarcode(String code) => '/medicines/barcode/$code';
  static const String medicineInteractions = '/medicines/interactions';

  // ==================== 用药计划 ====================
  static const String plans = '/plans';
  static const String plansToday = '/plans/today';
  static String planDetail(String id) => '/plans/$id';

  // ==================== 打卡 ====================
  static const String checkins = '/checkins';
  static String checkinUndo(String id) => '/checkins/$id/undo';
  static const String checkinCalendar = '/checkins/calendar';

  // ==================== 处方 ====================
  static const String prescriptions = '/prescriptions';
  static String prescriptionDetail(String id) => '/prescriptions/$id';
  static String prescriptionOcr(String id) => '/prescriptions/$id/ocr';

  // ==================== 家人监护 ====================
  static const String guardians = '/guardians';
  static const String guardianPatients = '/guardians/patients';
  static const String guardianMyGuardians = '/guardians/my-guardians';
  static const String guardianInvitations = '/guardians/invitations';
  static String guardianConfirm(String patientId) => '/guardians/$patientId/confirm';
  static String guardianDetail(String patientId) => '/guardians/$patientId';
  static String guardianReport(String patientId) => '/guardians/$patientId/report';

  // ==================== 通知 ====================
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationReadAll = '/notifications/read-all';
  static const String registerDevice = '/notifications/device';

  // ==================== 健康检查 ====================
  static const String health = '/health';
}
