/// 应用常量配置
class AppConstants {
  AppConstants._();

  // ==================== 应用信息 ====================
  static const String appName = '药吃了么';
  static const String appVersion = '1.0.0';

  // ==================== 存储Key ====================
  static const String themeModeKey = 'theme_mode';
  static const String onboardingDoneKey = 'onboarding_done';

  // ==================== 提醒相关 ====================
  static const int missedDoseThresholdMinutes = 30;
  static const int consecutiveMissedThreshold = 3;
  static const int undoCheckinWindowMinutes = 5;
  static const int refillReminderDays = 7;

  // ==================== 适老化 ====================
  static const double elderlyFontScale = 1.5;
  static const double elderlyMinFontSize = 16.0;
  static const double elderlyMinTouchTarget = 48.0;
  static const double elderlyContrastRatio = 7.0;

  // ==================== 动画 ====================
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration checkinSuccessDuration = Duration(milliseconds: 500);
  static const Duration themeSwitchDuration = Duration(milliseconds: 800);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1000);

  // ==================== 分页 ====================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // ==================== 路由路径 ====================
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeHome = '/home';
  static const String routeReminders = '/reminders';
  static const String routeReminderAdd = '/reminders/add';
  static const String routeReminderEdit = '/reminders/edit';
  static const String routeCheckin = '/checkin';
  static const String routeRecords = '/records';
  static const String routeMedicines = '/medicines';
  static const String routeMedicineDetail = '/medicines/detail';
  static const String routeInteractions = '/medicines/interactions';
  static const String routePrescriptions = '/prescriptions';
  static const String routePrescriptionOcr = '/prescriptions/ocr';
  static const String routePrescriptionDetail = '/prescriptions/detail';
  static const String routeSettings = '/settings';
}
