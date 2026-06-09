import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/medication_log.dart';

/// 用药记录Provider - 本地存储版
class RecordsProvider extends ChangeNotifier {
  List<MedicationLog> _logs = [];
  bool _isLoading = false;

  List<MedicationLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Box get _box => Hive.box('medication_data');

  RecordsProvider() {
    loadLogs();
  }

  void loadLogs() {
    _isLoading = true;
    notifyListeners();

    final data = _box.get('logs', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _logs = list.map((e) => MedicationLog.fromJson(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  void _saveLogs() {
    final data = jsonEncode(_logs.map((e) => e.toJson()).toList());
    _box.put('logs', data);
  }

  Future<void> addLog(MedicationLog log) async {
    _logs.add(log);
    _saveLogs();
    notifyListeners();
  }

  Future<void> updateLog(MedicationLog log) async {
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
      _saveLogs();
      notifyListeners();
    }
  }

  List<MedicationLog> getLogsForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _logs.where((l) => l.date == dateStr).toList();
  }

  double getComplianceRate(DateTime date) {
    final logs = getLogsForDate(date);
    if (logs.isEmpty) return 0;
    final taken = logs.where((l) => l.status == 'taken').length;
    return taken / logs.length;
  }

  int getStreakDays() {
    int streak = 0;
    var date = DateTime.now();
    while (true) {
      final logs = getLogsForDate(date);
      if (logs.isEmpty || logs.every((l) => l.status != 'taken')) break;
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
