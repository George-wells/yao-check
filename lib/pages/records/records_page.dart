import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/records_provider.dart';
import '../../models/medication_log.dart';

/// 用药记录页（增强版）
/// 统计概览 + 趋势图表（fl_chart） + 日历视图（状态颜色） + 打卡明细
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  @override
  void initState() {
    super.initState();
    context.read<RecordsProvider>().loadAll(days: 7);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final records = context.watch<RecordsProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('用药记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showExportDialog(theme),
            tooltip: '导出报告',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => records.loadAll(days: records.selectedRange),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isElderly ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计概览卡片
              _buildStatsCard(theme, records, isElderly),
              SizedBox(height: isElderly ? 20 : 16),

              // 时间筛选
              _buildTimeFilter(theme, records, isElderly),
              SizedBox(height: isElderly ? 20 : 16),

              // 趋势图表
              _buildTrendChart(theme, records, isElderly),
              SizedBox(height: isElderly ? 20 : 16),

              // 日历视图
              _buildCalendarView(theme, records, isElderly),
              SizedBox(height: isElderly ? 20 : 16),

              // 选中日期明细
              _buildDateDetail(theme, records, isElderly),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 统计概览卡片
  Widget _buildStatsCard(ThemeProvider theme, RecordsProvider records, bool isElderly) {
    final summary = records.getSummary();
    final rate = summary['rate'] as double;
    final completed = summary['completed'] as int;
    final total = summary['total'] as int;
    final streak = summary['streak'] as int;

    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Row(
          children: [
            // 按时率圆环
            SizedBox(
              width: isElderly ? 90 : 72,
              height: isElderly ? 90 : 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: isElderly ? 90 : 72,
                    height: isElderly ? 90 : 72,
                    child: CircularProgressIndicator(
                      value: total > 0 ? rate / 100.0 : 0,
                      strokeWidth: isElderly ? 6 : 4,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rate >= 80 ? const Color(0xFF52C41A) :
                        rate >= 60 ? const Color(0xFFFAAD14) :
                        const Color(0xFFFF4D4F),
                      ),
                    ),
                  ),
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: isElderly ? 22 : 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '按时服药率',
                    style: TextStyle(
                      fontSize: theme.fontSizeH3,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  SizedBox(height: theme.spaceSM),
                  _buildStatRow(theme, '已完成', '$completed/$total', theme.success),
                  SizedBox(height: theme.spaceXS),
                  _buildStatRow(theme, '连续打卡', '$streak 天', theme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(ThemeProvider theme, String label, String value, Color color) {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 14, color: color),
        SizedBox(width: theme.spaceXS),
        Text(
          '$label：',
          style: TextStyle(fontSize: theme.fontSizeCaption, color: theme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: theme.fontSizeBodySmall,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 时间筛选
  Widget _buildTimeFilter(ThemeProvider theme, RecordsProvider records, bool isElderly) {
    final ranges = [7, 30, 90];
    final labels = ['7天', '30天', '90天'];

    return Row(
      children: List.generate(ranges.length, (index) {
        final selected = records.selectedRange == ranges[index];
        return Expanded(
          child: GestureDetector(
            onTap: () => records.switchRange(ranges[index]),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: isElderly ? 14 : 10),
              margin: EdgeInsets.only(right: index < ranges.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: selected ? theme.primary : Colors.white,
                borderRadius: BorderRadius.circular(theme.radiusMD),
                border: Border.all(
                  color: selected ? theme.primary : const Color(0xFFE8E8E8),
                ),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: theme.fontSizeBodySmall,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : theme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 趋势图表
  Widget _buildTrendChart(ThemeProvider theme, RecordsProvider records, bool isElderly) {
    final trend = records.getTrendData(records.selectedRange);
    if (trend.isEmpty) {
      return Card(
        child: Container(
          padding: EdgeInsets.all(theme.cardPadding),
          child: Center(
            child: Text('暂无数据', style: TextStyle(color: theme.textSecondary)),
          ),
        ),
      );
    }

    // 最多显示14天，否则取间隔
    final displayData = trend.length > 14
        ? [trend.first, ...trend.where((e) => trend.indexOf(e) % (trend.length ~/ 10) == 0).toList().sublist(0, 10), trend.last]
        : trend;

    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '按时服药率趋势',
                  style: TextStyle(
                    fontSize: theme.fontSizeH3,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                if (records.isLoading)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: theme.spaceLG),
            SizedBox(
              height: isElderly ? 220 : 180,
              child: CustomPaint(
                size: Size(double.infinity, isElderly ? 220 : 180),
                painter: _TrendChartPainter(
                  data: displayData,
                  primaryColor: theme.primary,
                  successColor: const Color(0xFF52C41A),
                  warningColor: const Color(0xFFFAAD14),
                  dangerColor: const Color(0xFFFF4D4F),
                  isElderly: isElderly,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 日历视图
  Widget _buildCalendarView(ThemeProvider theme, RecordsProvider records, bool isElderly) {
    final now = records.calendarMonth;
    final daysInMonth = app_date_utils.DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];

    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          children: [
            // 月份标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final newMonth = DateTime(now.year, now.month - 1, 1);
                    records.switchMonth(newMonth.year, newMonth.month);
                  },
                ),
                Text(
                  '${now.year}年${now.month}月',
                  style: TextStyle(
                    fontSize: theme.fontSizeH3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final newMonth = DateTime(now.year, now.month + 1, 1);
                    records.switchMonth(newMonth.year, newMonth.month);
                  },
                ),
              ],
            ),
            SizedBox(height: theme.spaceMD),

            // 星期头
            Row(
              children: weekdays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )).toList(),
            ),
            SizedBox(height: theme.spaceSM),

            // 日期网格
            ...List.generate(6, (row) {
              return Padding(
                padding: EdgeInsets.only(bottom: theme.spaceSM),
                child: Row(
                  children: List.generate(7, (col) {
                    final day = row * 7 + col - firstWeekday + 2;
                    final isValid = day > 0 && day <= daysInMonth;
                    final date = isValid ? DateTime(now.year, now.month, day) : null;
                    final isSelected = date != null &&
                        date.year == records.selectedDate.year &&
                        date.month == records.selectedDate.month &&
                        date.day == records.selectedDate.day;
                    final isToday = date != null &&
                        date.year == DateTime.now().year &&
                        date.month == DateTime.now().month &&
                        date.day == DateTime.now().day;

                    // 获取该日状态
                    Color? dayColor;
                    if (isValid) {
                      final status = records.getDayStatus(now.year, now.month, day);
                      if (status == 'all_taken') {
                        dayColor = const Color(0xFF52C41A);
                      } else if (status == 'partial') {
                        dayColor = const Color(0xFFFAAD14);
                      } else if (status == 'all_missed') {
                        dayColor = const Color(0xFFFF4D4F);
                      }
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: isValid ? () => records.selectedDate = DateTime(now.year, now.month, day) : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: isElderly ? 8 : 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primary
                                : isToday
                                    ? theme.primaryLight
                                    : null,
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isValid ? '$day' : '',
                                style: TextStyle(
                                  fontSize: isElderly ? 22 : 16,
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? theme.primary
                                          : theme.textPrimary,
                                ),
                              ),
                              if (dayColor != null)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: dayColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),

            // 图例
            SizedBox(height: theme.spaceSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(theme, '全部按时', const Color(0xFF52C41A)),
                SizedBox(width: theme.spaceLG),
                _buildLegend(theme, '部分漏服', const Color(0xFFFAAD14)),
                SizedBox(width: theme.spaceLG),
                _buildLegend(theme, '全部漏服', const Color(0xFFFF4D4F)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeProvider theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: theme.spaceXS),
        Text(label, style: TextStyle(fontSize: theme.fontSizeCaption, color: theme.textSecondary)),
      ],
    );
  }

  /// 选中日期明细
  Widget _buildDateDetail(ThemeProvider theme, RecordsProvider records, bool isElderly) {
    final date = records.selectedDate;
    final dayLogs = records.getLogsForDate(date);

    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.month}月${date.day}日 打卡明细',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceMD),
            if (dayLogs.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.spaceLG),
                child: Center(
                  child: Text(
                    '暂无记录',
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      color: theme.textDisabled,
                    ),
                  ),
                ),
              )
            else
              ...dayLogs.map((log) {
                return Padding(
                  padding: EdgeInsets.only(bottom: theme.spaceSM),
                  child: _buildDetailItem(theme, log, isElderly),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(ThemeProvider theme, MedicationLog log, bool isElderly) {
    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case 'taken':
        statusColor = const Color(0xFF52C41A);
        statusIcon = Icons.check_circle;
        break;
      case 'missed':
        statusColor = const Color(0xFFFF4D4F);
        statusIcon = Icons.error;
        break;
      case 'skipped':
        statusColor = const Color(0xFFD9D9D9);
        statusIcon = Icons.skip_next;
        break;
      case 'late':
        statusColor = log.isMakeup ? const Color(0xFFFA8C16) : const Color(0xFFFAAD14);
        statusIcon = log.isMakeup ? Icons.refresh : Icons.access_time;
        break;
      default:
        statusColor = const Color(0xFFD9D9D9);
        statusIcon = Icons.schedule;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: theme.spaceSM),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: theme.iconStandard),
          SizedBox(width: theme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.medicineName ?? '',
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      log.scheduledTime,
                      style: TextStyle(
                        fontSize: theme.fontSizeCaption,
                        color: theme.textSecondary,
                      ),
                    ),
                    if (log.delayMinutes != null && log.delayMinutes! > 0) ...[
                      SizedBox(width: theme.spaceSM),
                      Text(
                        '延迟${log.delayMinutes}分钟',
                        style: TextStyle(
                          fontSize: theme.fontSizeCaption,
                          color: const Color(0xFFFAAD14),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spaceSM,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              log.statusLabel,
              style: TextStyle(
                fontSize: theme.fontSizeCaption,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 导出报告对话框
  void _showExportDialog(ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radiusXL),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: theme.spaceLG),
            Text(
              '导出用药报告',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: theme.spaceLG),
            _buildExportOption(theme, Icons.description_outlined, '导出为 PDF', '适合分享和打印'),
            SizedBox(height: theme.spaceSM),
            _buildExportOption(theme, Icons.table_chart_outlined, '导出为 CSV', '适合数据分析'),
            SizedBox(height: theme.spaceSM),
            _buildExportOption(theme, Icons.share_outlined, '分享用药报告', '发送给家人或医生'),
            SizedBox(height: theme.spaceLG),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(ThemeProvider theme, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: theme.primary),
      title: Text(title, style: TextStyle(fontSize: theme.fontSizeBody)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: theme.fontSizeCaption)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.radiusMD)),
    );
  }
}

/// 趋势图自定义绘制
class _TrendChartPainter extends CustomPainter {
  final List<dynamic> data;
  final Color primaryColor;
  final Color successColor;
  final Color warningColor;
  final Color dangerColor;
  final bool isElderly;

  _TrendChartPainter({
    required this.data,
    required this.primaryColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
    required this.isElderly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final chartHeight = size.height - 30;
    final barWidth = (size.width / data.length) * 0.6;
    final gap = (size.width / data.length) * 0.4;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final rate = item.rate as double;
      final barHeight = (rate / 100) * chartHeight;
      final x = i * (barWidth + gap) + gap / 2;
      final y = size.height - 30 - barHeight;

      // 柱子颜色
      final color = rate >= 80
          ? successColor
          : rate >= 60
              ? warningColor
              : dangerColor;

      // 绘制柱子
      final barPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        barPaint,
      );

      // 绘制百分比文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${rate.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontSize: isElderly ? 16 : 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, y - textPainter.height - 2),
      );

      // 绘制日期标签（只显示部分）
      if (i % (data.length > 7 ? (data.length ~/ 7) : 1) == 0 || i == data.length - 1) {
        final dateStr = item.date.toString();
        final label = dateStr.length >= 10 ? dateStr.substring(5) : dateStr;
        final labelPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: isElderly ? 14 : 8,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(
            x + (barWidth - labelPainter.width) / 2,
            size.height - 18,
          ),
        );
      }
    }

    // 绘制基线
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 28),
      Offset(size.width, size.height - 28),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
