/// 字符串工具类
class StringUtils {
  StringUtils._();

  /// 隐藏手机号中间四位
  static String maskPhone(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  /// 截断字符串
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$suffix';
  }

  /// 判断字符串是否为空
  static bool isBlank(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// 获取药品剂型单位
  static String getDosageUnitLabel(String unit) {
    switch (unit) {
      case '片':
        return '片/次';
      case '粒':
        return '粒/次';
      case 'ml':
        return 'ml/次';
      case 'mg':
        return 'mg/次';
      case 'g':
        return 'g/次';
      case '袋':
        return '袋/次';
      case '支':
        return '支/次';
      case '瓶':
        return '瓶/次';
      default:
        return '$unit/次';
    }
  }

  /// 格式化剂量描述
  static String formatDosage(double value, String unit) {
    final valueStr = value == value.floorToDouble() ? value.toInt().toString() : value.toString();
    return '$valueStr$unit';
  }

  /// 获取频率描述
  static String getFrequencyLabel(String type, int? timesPerDay, int? interval) {
    switch (type) {
      case 'daily':
        return '每日${timesPerDay ?? 1}次';
      case 'every_n_hours':
        return '每${interval ?? 8}小时一次';
      case 'specific_days':
        return '特定日期';
      case 'as_needed':
        return '按需服用';
      default:
        return '每日1次';
    }
  }

  /// 格式化剩余数量提示
  static String formatStockReminder(double? quantity, String? unit) {
    if (quantity == null || unit == null) return '';
    return '剩余 ${formatDosage(quantity, unit)}';
  }
}
