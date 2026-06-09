import 'package:intl/intl.dart';

/// 日期工具类
class DateUtils {
  DateUtils._();

  /// 格式化时间 HH:mm
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// 格式化日期 yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 格式化日期 yyyy年M月d日
  static String formatDateChinese(DateTime date) {
    return DateFormat('yyyy年M月d日').format(date);
  }

  /// 格式化日期 EEEE
  static String formatWeekday(DateTime date) {
    return DateFormat('EEEE', 'zh_CN').format(date);
  }

  /// 获取时间段问候语
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '凌晨好';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 获取本周的日期范围
  static List<DateTime> getCurrentWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return List.generate(7, (i) {
      return now.subtract(Duration(days: weekday - 1 - i));
    });
  }

  /// 获取本月的所有日期
  static List<DateTime> getMonthDays(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(year, month, i + 1));
  }

  /// 获取某月的天数
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 计算两个日期之间的天数差
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  /// 获取相对时间描述
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}周前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}个月前';
    return '${(diff.inDays / 365).floor()}年前';
  }

  /// 获取剩余天数描述
  static String getRemainingDays(DateTime targetDate) {
    final days = daysBetween(DateTime.now(), targetDate);
    if (days < 0) return '已过期${-days}天';
    if (days == 0) return '今天到期';
    if (days == 1) return '明天到期';
    return '剩余$days天';
  }

  /// 获取星期中文名
  static String getChineseWeekday(int weekday) {
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday];
  }

  /// 时间字符串转DateTime
  static DateTime? parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (_) {}
    return null;
  }

  /// 检查时间是否已过
  static bool isTimePassed(String timeStr) {
    final time = parseTimeString(timeStr);
    if (time == null) return false;
    return time.isBefore(DateTime.now());
  }

  /// 检查是否在可撤销窗口内（5分钟）
  static bool isWithinUndoWindow(DateTime checkinTime) {
    return DateTime.now().difference(checkinTime).inMinutes < 5;
  }
}
