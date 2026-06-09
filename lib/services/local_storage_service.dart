import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/medication_plan.dart';
import '../models/medication_log.dart';

/// 本地存储服务
/// 使用SharedPreferences实现轻量级本地数据持久化
/// 支持：用户信息缓存、提醒列表缓存、打卡记录缓存
class LocalStorageService {
  static LocalStorageService? _instance;
  late SharedPreferences _prefs;

  LocalStorageService._();

  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 用户信息 ====================

  /// 缓存用户信息
  Future<void> cacheUser(User user) async {
    await _prefs.setString('cached_user', jsonEncode(user.toJson()));
  }

  /// 获取缓存的用户信息
  User? getCachedUser() {
    final json = _prefs.getString('cached_user');
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  /// 清除缓存的用户信息
  Future<void> clearUser() async {
    await _prefs.remove('cached_user');
  }

  // ==================== 用药计划缓存 ====================

  /// 缓存用药计划列表
  Future<void> cachePlans(List<MedicationPlan> plans) async {
    final jsonList = plans.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('cached_plans', jsonList);
  }

  /// 获取缓存的用药计划列表
  List<MedicationPlan> getCachedPlans() {
    final jsonList = _prefs.getStringList('cached_plans');
    if (jsonList == null) return [];
    try {
      return jsonList.map((json) => MedicationPlan.fromJson(jsonDecode(json))).toList();
    } catch (_) {
      return [];
    }
  }

  // ==================== 今日安排缓存 ====================

  /// 缓存今日用药安排
  Future<void> cacheTodaySchedule(TodaySchedule schedule) async {
    // 简化缓存：只缓存统计数据
    await _prefs.setInt('today_total', schedule.total);
    await _prefs.setInt('today_completed', schedule.completed);
    await _prefs.setInt('today_missed', schedule.missed);
    await _prefs.setInt('today_progress', schedule.progress);
  }

  /// 获取缓存的今日安排
  TodaySchedule? getCachedTodaySchedule() {
    final total = _prefs.getInt('today_total');
    if (total == null) return null;
    return TodaySchedule(
      total: total,
      completed: _prefs.getInt('today_completed') ?? 0,
      missed: _prefs.getInt('today_missed') ?? 0,
      progress: _prefs.getInt('today_progress') ?? 0,
    );
  }

  // ==================== 通用存储 ====================

  /// 保存字符串
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// 获取字符串
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// 保存布尔值
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// 获取布尔值
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// 保存整数
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  /// 获取整数
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// 保存字符串列表
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  /// 获取字符串列表
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
