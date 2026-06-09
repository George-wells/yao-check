import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';
import '../core/router/app_router.dart';

/// 本地通知服务
/// 管理服药提醒的本地推送通知
class NotificationService {
  static NotificationService? _instance;
  late FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  /// 初始化通知插件
  Future<void> init() async {
    if (_initialized) return;

    _plugin = FlutterLocalNotificationsPlugin();

    // Android 初始化配置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化配置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// 通知点击回调
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.startsWith('checkin:')) {
      // payload 格式: checkin:{planId}:{scheduledDate}:{scheduledTime}
      final parts = payload.split(':');
      if (parts.length >= 4) {
        final planId = parts[1];
        final scheduledDate = parts[2];
        final scheduledTime = parts[3];
        final isMakeup = parts.length > 4 && parts[4] == 'makeup';

        // 通过全局 navigatorKey 导航到打卡页
        final navigator = AppRouter.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushNamed(
            '/checkin',
            arguments: {
              'planId': planId,
              'scheduledDate': scheduledDate,
              'scheduledTime': scheduledTime,
              'isMakeup': isMakeup,
            },
          );
        }
      }
    }
  }

  /// 获取通知插件实例
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    return true;
  }

  /// 创建通知渠道
  Future<void> createNotificationChannels() async {
    final androidPlugin = AndroidFlutterLocalNotificationsPlugin();
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'medication_reminder',
        '用药提醒',
        description: '按时服药提醒通知',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'missed_dose',
        '漏服提醒',
        description: '漏服检测和提醒通知',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'care_message',
        '关怀提醒',
        description: '用药关怀和健康提示',
        importance: Importance.defaultImportance,
      ),
    );
  }

  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'medication_reminder',
  }) async {
    // 根据channelId选择对应的渠道配置
    final isHighPriority = channelId == 'medication_reminder' || channelId == 'missed_dose';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: isHighPriority ? Importance.high : Importance.defaultImportance,
      priority: isHighPriority ? Priority.high : Priority.defaultPriority,
      showWhen: true,
      enableVibration: isHighPriority,
      playSound: true,
      fullScreenIntent: isHighPriority,
      category: isHighPriority ? AndroidNotificationCategory.alarm : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: isHighPriority
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// 获取渠道名称
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'medication_reminder':
        return '用药提醒';
      case 'missed_dose':
        return '漏服提醒';
      case 'care_message':
        return '关怀提醒';
      default:
        return '用药提醒';
    }
  }

  /// 获取渠道描述
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'medication_reminder':
        return '按时服药提醒通知';
      case 'missed_dose':
        return '漏服检测和提醒通知';
      case 'care_message':
        return '用药关怀和健康提示';
      default:
        return '用药提醒通知';
    }
  }

  /// 显示漏服通知
  Future<void> showMissedDoseNotification({
    required int id,
    required String medicineName,
    required String dosage,
    required String scheduledTime,
    String? planId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'missed_dose',
      '漏服提醒',
      channelDescription: '漏服检测和提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const details = NotificationDetails(android: androidDetails);
    final payload = 'checkin:$planId:${DateTime.now().toIso8601String().split('T')[0]}:$scheduledTime';

    await _plugin.show(
      id,
      '⚠️ 您漏服了 $medicineName',
      '预定时间：$scheduledTime · $dosage，请尽快补服',
      details,
      payload: payload,
    );
  }

  /// 显示关怀提醒（连续漏服）
  Future<void> showCareNotification({
    required int id,
    required int consecutiveDays,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'care_message',
      '关怀提醒',
      channelDescription: '用药关怀和健康提示',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id,
      '💊 用药关怀提醒',
      '您已连续 $consecutiveDays 天漏服，建议咨询医生调整用药方案',
      details,
    );
  }

  /// 显示重复用药预警通知
  Future<void> showDuplicateMedicineWarning({
    required int id,
    required String medicineName,
    required String duplicateComponent,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminder',
      '用药提醒',
      channelDescription: '按时服药提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id,
      '⚠️ 重复用药预警',
      '$medicineName 含有与已有药品相同的成分 $duplicateComponent',
      details,
    );
  }

  /// 取消通知
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 检查通知权限
  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.areNotificationsEnabled();
      return granted ?? false;
    }
    return true;
  }
}
