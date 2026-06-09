import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/medication_plan.dart';
import '../models/medication_log.dart';

/// 用药提醒Provider - 本地存储版
class ReminderProvider extends ChangeNotifier {
  List<MedicationPlan> _plans = [];
  List<MedicationLog> _logs = [];
  bool _isLoading = false;

  List<MedicationPlan> get plans => _plans;
  List<MedicationLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Box get _box => Hive.box('medication_data');

  ReminderProvider() {
    loadPlans();
    _loadLogs();
  }

  void loadPlans() {
    final data = _box.get('plans', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _plans = list.map((e) => MedicationPlan.fromJson(e)).toList();
    notifyListeners();
  }

  void _loadLogs() {
    final data = _box.get('logs', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _logs = list.map((e) => MedicationLog.fromJson(e)).toList();
  }

  void _savePlans() {
    final data = jsonEncode(_plans.map((e) => e.toJson()).toList());
    _box.put('plans', data);
  }

  void _saveLogs() {
    final data = jsonEncode(_logs.map((e) => e.toJson()).toList());
    _box.put('logs', data);
  }

  Future<void> addPlan(MedicationPlan plan) async {
    _plans.add(plan);
    _savePlans();
    notifyListeners();
  }

  Future<bool> createPlan(Map<String, dynamic> data, {bool force = false}) async {
    final plan = MedicationPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'local',
      medicineName: data['medicineName'] ?? '',
      dosageValue: (data['dosageValue'] ?? 1).toDouble(),
      dosageUnit: data['dosageUnit'] ?? '片',
      dosageDescription: data['dosageDescription'] ?? '',
      frequencyType: data['frequencyType'] ?? 'daily',
      frequencyTimesPerDay: data['frequencyTimesPerDay'],
      schedule: (data['schedule'] as List<dynamic>?)
              ?.map((e) => ScheduleItem.fromJson(e))
              .toList() ??
          [ScheduleItem(time: '08:00', daysOfWeek: [1,2,3,4,5,6,7])],
      startDate: data['startDate'] ?? DateTime.now().toIso8601String().substring(0, 10),
      endDate: data['endDate'],
      isActive: true,
    );
    _plans.add(plan);
    _savePlans();
    notifyListeners();
    return true;
  }

  Future<void> updatePlan(MedicationPlan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index >= 0) {
      _plans[index] = plan;
      _savePlans();
      notifyListeners();
    }
  }

  Future<bool> deletePlan(String id) async {
    _plans.removeWhere((p) => p.id == id);
    _savePlans();
    notifyListeners();
    return true;
  }

  String? checkDuplicateMedicine(String medicineName) {
    final existing = _plans.where((p) =>
      p.medicineName == medicineName && p.isActive
    ).toList();
    if (existing.isNotEmpty) {
      return '已在用药计划中（${existing.first.medicineName}）';
    }
    return null;
  }

  /// 打卡
  Future<bool> checkin(Map<String, dynamic> data) async {
    final log = MedicationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      planId: data['planId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      dosageDescription: data['dosage'] ?? '',
      scheduledTime: data['time'] ?? DateTime.now().toIso8601String().substring(11, 16),
      scheduledDate: DateTime.now().toIso8601String().substring(0, 10),
      status: 'taken',
    );
    _logs.add(log);
    _saveLogs();
    notifyListeners();
    return true;
  }

  Future<List<MedicationLog>> getCheckins({String? startDate, String? endDate}) async {
    if (startDate != null) {
      return _logs.where((l) => l.scheduledDate == startDate).toList();
    }
    return _logs;
  }

  Future<bool> undoCheckin(String logId) async {
    final index = _logs.indexWhere((l) => l.id == logId);
    if (index >= 0) {
      _logs[index] = MedicationLog(
        id: _logs[index].id,
        planId: _logs[index].planId,
        medicineName: _logs[index].medicineName,
        dosageDescription: _logs[index].dosageDescription,
        scheduledTime: _logs[index].scheduledTime,
        scheduledDate: _logs[index].scheduledDate,
        status: 'missed',
      );
      _saveLogs();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> snoozeReminder({String? planId, String? medicineName, String? dosage, String? scheduledTime}) async {
    // 本地提醒的延迟功能由本地通知处理
    debugPrint('Snooze reminder $planId');
  }

  List<MedicationPlan> getPendingPlans() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _plans.where((p) =>
      p.isActive &&
      p.startDate.compareTo(todayStr) <= 0 &&
      (p.endDate == null || p.endDate!.compareTo(todayStr) >= 0)
    ).toList();
  }

  List<MedicationPlan> getPlansForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _plans.where((p) {
      if (!p.isActive) return false;
      if (p.startDate.compareTo(dateStr) > 0) return false;
      if (p.endDate != null && p.endDate!.compareTo(dateStr) < 0) return false;
      return true;
    }).toList();
  }
}
