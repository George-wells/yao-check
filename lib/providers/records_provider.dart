import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/medication_log.dart';

/// 用药记录Provider - 本地存储版
class RecordsProvider extends ChangeNotifier {
  List<MedicationLog> _logs = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime.now();
  int _selectedRange = 7; // 7天/30天

  List<MedicationLog> get logs => _logs;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  DateTime get calendarMonth => _calendarMonth;
  int get selectedRange => _selectedRange;

  set selectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Box get _box => Hive.box('medication_data');

  RecordsProvider() {
    loadLogs();
  }

  void loadLogs() {
    final data = _box.get('logs', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _logs = list.map((e) => MedicationLog.fromJson(e)).toList();
    notifyListeners();
  }

  void _saveLogs() {
    final data = jsonEncode(_logs.map((e) => e.toJson()).toList());
    _box.put('logs', data);
  }

  Future<void> loadAll({int days = 7}) async {
    _isLoading = true;
    notifyListeners();
    loadLogs();
    _isLoading = false;
    notifyListeners();
  }

  void switchRange(int range) {
    _selectedRange = range;
    notifyListeners();
  }

  void switchMonth(int year, int month) {
    _calendarMonth = DateTime(year, month);
    notifyListeners();
  }

  Map<String, dynamic> getSummary() {
    final now = DateTime.now();
    final todayLogs = getLogsForDate(now);
    final total = todayLogs.length;
    final taken = todayLogs.where((l) => l.status == 'taken').length;
    return {
      'total': total,
      'taken': taken,
      'rate': total > 0 ? taken / total : 0,
      'streak': getStreakDays(),
    };
  }

  List<Map<String, dynamic>> getTrendData(int days) {
    final result = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final logs = getLogsForDate(date);
      final total = logs.length;
      final taken = logs.where((l) => l.status == 'taken').length;
      result.add({
        'date': date,
        'rate': total > 0 ? taken / total : 0,
        'total': total,
        'taken': taken,
      });
    }
    return result;
  }

  String getDayStatus(int year, int month, int day) {
    final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final dayLogs = _logs.where((l) => l.scheduledDate == dateStr).toList();
    if (dayLogs.isEmpty) return 'none';
    final allTaken = dayLogs.every((l) => l.status == 'taken');
    return allTaken ? 'completed' : 'partial';
  }

  List<MedicationLog> getLogsForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _logs.where((l) => l.scheduledDate == dateStr).toList();
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

  Future<void> addLog(MedicationLog log) async {
    _logs.add(log);
    _saveLogs();
    notifyListeners();
  }
}
