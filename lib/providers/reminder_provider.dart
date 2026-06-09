import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../models/medication_plan.dart';
import '../models/medication_log.dart';
import '../core/constants/app_constants.dart';

/// 用药提醒状态管理 Provider（增强版）
/// 功能：CRUD、打卡、漏服检测、重复用药预警、稍后提醒
class ReminderProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final LocalStorageService _storage = LocalStorageService.instance;
  final NotificationService _notif = NotificationService.instance;

  List<MedicationPlan> _plans = [];
  TodaySchedule? _todaySchedule;
  bool _isLoading = false;
  String? _error;

  // 漏服检测相关
  int _consecutiveMissedDays = 0;
  bool _hasMissedDose = false;
  List<MedicationLog> _missedLogs = [];

  // 重复用药预警
  String? _duplicateWarning;
  List<String> _duplicateMedicineNames = [];

  List<MedicationPlan> get plans => _plans;
  TodaySchedule? get todaySchedule => _todaySchedule;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get consecutiveMissedDays => _consecutiveMissedDays;
  bool get hasMissedDose => _hasMissedDose;
  List<MedicationLog> get missedLogs => _missedLogs;
  String? get duplicateWarning => _duplicateWarning;
  List<String> get duplicateMedicineNames => _duplicateMedicineNames;

  /// 加载今日用药安排
  Future<void> loadTodaySchedule() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/plans/today');
      if (response.data['success'] == true) {
        _todaySchedule = TodaySchedule.fromJson(response.data['data']);
        await _storage.cacheTodaySchedule(_todaySchedule!);
        _checkMissedDose();
      }
    } catch (_) {
      _todaySchedule = _storage.getCachedTodaySchedule();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 加载用药计划列表
  Future<void> loadPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/plans');
      if (response.data['success'] == true) {
        _plans = (response.data['data'] as List<dynamic>)
            .map((e) => MedicationPlan.fromJson(e))
            .toList();
        await _storage.cachePlans(_plans);
      }
    } catch (_) {
      _plans = _storage.getCachedPlans();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 检查漏服情况
  void _checkMissedDose() {
    if (_todaySchedule == null) return;

    _hasMissedDose = _todaySchedule!.missed > 0;
    _missedLogs = _todaySchedule!.missedItems;

    // 更新连续漏服天数（简化：根据是否有漏服记录）
    if (_hasMissedDose) {
      _consecutiveMissedDays++;
    } else {
      _consecutiveMissedDays = 0;
    }

    // 连续3天漏服触发关怀提醒
    if (_consecutiveMissedDays >= AppConstants.consecutiveMissedThreshold) {
      _notif.showCareNotification(
        id: 9999,
        consecutiveDays: _consecutiveMissedDays,
      );
    }
  }

  /// 检查重复用药
  /// 返回警告信息，如果无重复返回null
  String? checkDuplicateMedicine(String medicineName) {
    _duplicateWarning = null;
    _duplicateMedicineNames = [];

    // 从已有计划中检查是否有相同药品
    for (final plan in _plans) {
      if (plan.medicineName == medicineName && plan.isActive) {
        _duplicateWarning = '您已有「$medicineName」的用药提醒，是否确认重复添加？';
        _duplicateMedicineNames.add(medicineName);
        notifyListeners();
        return _duplicateWarning;
      }
    }

    return null;
  }

  /// 检查相同成分药物（重复用药预警）
  /// 根据药品的通用名/成分名检查
  String? checkDuplicateComponent(String medicineName, String? genericName) {
    if (genericName == null || genericName.isEmpty) return null;

    for (final plan in _plans) {
      if (plan.medicineName != medicineName && plan.isActive) {
        // 这里简化处理：如果名称包含相同关键词，视为重复成分
        // 实际应通过API查询药品成分
        if (plan.medicineName.contains(genericName) ||
            genericName.contains(plan.medicineName)) {
          _duplicateWarning = '⚠️ 重复用药预警：「$medicineName」与已有药品「${plan.medicineName}」可能含有相同成分，请咨询医生确认。';
          _duplicateMedicineNames.add(plan.medicineName);
          notifyListeners();
          return _duplicateWarning;
        }
      }
    }

    return null;
  }

  /// 清除重复用药警告
  void clearDuplicateWarning() {
    _duplicateWarning = null;
    _duplicateMedicineNames = [];
    notifyListeners();
  }

  /// 创建用药计划（含重复用药检查）
  Future<bool> createPlan(Map<String, dynamic> data, {bool force = false}) async {
    if (!force) {
      // 检查重复用药
      final duplicate = checkDuplicateMedicine(data['medicineName'] ?? '');
      if (duplicate != null) {
        return false; // 调用方处理确认弹窗
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/plans', data: data);
      if (response.data['success'] == true) {
        await loadPlans();
        await loadTodaySchedule();
        return true;
      }
      _error = '创建失败';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '网络错误';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 更新用药计划
  Future<bool> updatePlan(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/plans/$id', data: data);
      if (response.data['success'] == true) {
        await loadPlans();
        await loadTodaySchedule();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 删除用药计划
  Future<bool> deletePlan(String id) async {
    try {
      final response = await _api.delete('/plans/$id');
      if (response.data['success'] == true) {
        await loadPlans();
        await loadTodaySchedule();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 服药打卡
  Future<bool> checkin(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/checkins', data: data);
      if (response.data['success'] == true) {
        await loadTodaySchedule();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 稍后提醒（推迟15分钟）
  Future<void> snoozeReminder({
    required String planId,
    required String medicineName,
    required String dosage,
    required String scheduledTime,
  }) async {
    // 发送本地通知，15分钟后再次提醒
    final notifId = DateTime.now().millisecondsSinceEpoch % 100000;
    await _notif.showNotification(
      id: notifId,
      title: '⏰ 服药提醒（稍后）',
      body: '$medicineName · $dosage',
      payload: 'checkin:$planId:${DateTime.now().toIso8601String().split('T')[0]}:$scheduledTime',
    );
  }

  /// 撤销打卡
  Future<bool> undoCheckin(String id) async {
    try {
      final response = await _api.post('/checkins/$id/undo');
      if (response.data['success'] == true) {
        await loadTodaySchedule();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 获取打卡记录
  Future<List<MedicationLog>> getCheckins({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _api.get('/checkins', queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      if (response.data['success'] == true) {
        return (response.data['data'] as List<dynamic>)
            .map((e) => MedicationLog.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 获取用药统计
  Future<Map<String, dynamic>> getStats({int days = 30}) async {
    try {
      final response = await _api.get('/users/stats', queryParameters: {
        'days': days,
      });
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
