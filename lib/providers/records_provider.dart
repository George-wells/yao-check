import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/medication_log.dart';

/// 用药记录状态管理 Provider
/// 管理打卡记录查询、统计概览、趋势数据、日历数据
class RecordsProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<MedicationLog> _logs = [];
  Map<String, dynamic>? _stats;
  Map<String, String> _calendarData = {}; // date -> status summary
  bool _isLoading = false;
  String? _error;

  int _selectedRange = 7;
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime.now();

  List<MedicationLog> get logs => _logs;
  Map<String, dynamic>? get stats => _stats;
  Map<String, String> get calendarData => _calendarData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedRange => _selectedRange;
  DateTime get selectedDate => _selectedDate;
  DateTime get calendarMonth => _calendarMonth;

  set selectedRange(int v) {
    _selectedRange = v;
    notifyListeners();
  }

  set selectedDate(DateTime v) {
    _selectedDate = v;
    notifyListeners();
  }

  set calendarMonth(DateTime v) {
    _calendarMonth = v;
    notifyListeners();
  }

  /// 加载统计概览
  Future<void> loadStats({int days = 7}) async {
    try {
      final response = await _api.get('/users/stats', queryParameters: {
        'days': days,
      });
      if (response.data['success'] == true) {
        _stats = response.data['data'];
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 加载打卡记录
  Future<void> loadLogs({int days = 7}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    try {
      final response = await _api.get('/checkins', queryParameters: {
        'startDate': _formatDate(startDate),
        'endDate': _formatDate(endDate),
        'pageSize': 200,
      });
      if (response.data['success'] == true) {
        _logs = (response.data['data'] as List<dynamic>)
            .map((e) => MedicationLog.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = '加载记录失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 加载日历数据
  Future<void> loadCalendarData(int year, int month) async {
    try {
      final response = await _api.get('/checkins/calendar', queryParameters: {
        'year': year,
        'month': month,
      });
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          _calendarData = data.map((k, v) => MapEntry(k, v.toString()));
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 获取某日期的状态
  String? getDayStatus(int year, int month, int day) {
    final key = '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    return _calendarData[key];
  }

  /// 获取某日期的打卡明细
  List<MedicationLog> getLogsForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return _logs.where((log) => log.scheduledDate == dateStr).toList();
  }

  /// 获取趋势数据（按天汇总）
  List<DailyStat> getTrendData(int days) {
    final Map<String, List<MedicationLog>> grouped = {};
    for (final log in _logs) {
      grouped.putIfAbsent(log.scheduledDate, () => []).add(log);
    }

    final result = <DailyStat>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _formatDate(date);
      final dayLogs = grouped[key] ?? [];
      final total = dayLogs.length;
      final completed = dayLogs.where((l) =>
          l.status == 'taken' || l.status == 'late').length;
      result.add(DailyStat(
        date: key,
        total: total,
        completed: completed,
        rate: total > 0 ? (completed / total * 100) : 0,
      ));
    }
    return result;
  }

  /// 获取统计摘要
  Map<String, dynamic> getSummary() {
    final trend = getTrendData(_selectedRange);
    final total = trend.fold<int>(0, (sum, d) => sum + d.total);
    final completed = trend.fold<int>(0, (sum, d) => sum + d.completed);
    final missed = trend.fold<int>(0, (sum, d) => sum + (d.total - d.completed));
    final rate = total > 0 ? (completed / total * 100) : 0.0;

    // 连续打卡天数
    int streak = 0;
    for (final day in trend.reversed) {
      if (day.total > 0 && day.rate >= 100) {
        streak++;
      } else if (day.total > 0) {
        break;
      }
    }

    return {
      'total': total,
      'completed': completed,
      'missed': missed,
      'rate': rate,
      'streak': streak,
    };
  }

  /// 加载所有数据
  Future<void> loadAll({int days = 7}) async {
    _selectedRange = days;
    await Future.wait([
      loadStats(days: days),
      loadLogs(days: days),
      loadCalendarData(_calendarMonth.year, _calendarMonth.month),
    ]);
  }

  /// 切换时间范围
  Future<void> switchRange(int days) async {
    _selectedRange = days;
    await loadAll(days: days);
  }

  /// 切换月份
  Future<void> switchMonth(int year, int month) async {
    _calendarMonth = DateTime(year, month);
    await loadCalendarData(year, month);
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// 每日统计数据
class DailyStat {
  final String date;
  final int total;
  final int completed;
  final double rate;

  DailyStat({
    required this.date,
    required this.total,
    required this.completed,
    required this.rate,
  });
}
