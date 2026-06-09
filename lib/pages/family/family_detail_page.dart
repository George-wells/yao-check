import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/guardian_provider.dart';
import '../../models/guardianship.dart';

/// 被监护人详情页（增强版）
/// 展示用药概况、趋势、漏服记录，支持发送提醒和查看报告
class FamilyDetailPage extends StatefulWidget {
  const FamilyDetailPage({super.key});

  @override
  State<FamilyDetailPage> createState() => _FamilyDetailPageState();
}

class _FamilyDetailPageState extends State<FamilyDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      context.read<GuardianProvider>().loadReport(args['patientId']);
    }
  }

  Future<void> _sendReminder() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final provider = context.read<GuardianProvider>();
    final success = await provider.sendReminder(args['patientId']);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '已发送提醒通知' : '发送失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<GuardianProvider>();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isElderly = theme.isElderlyMode;
    final report = provider.selectedReport;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('${args?['patientName'] ?? '家人'}（${args?['relationship'] ?? ''}）'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, size: theme.iconStandard),
            onPressed: () {},
            tooltip: '通知设置',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isElderly ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 统计概览
                  _buildStatsOverview(theme, report, isElderly),
                  SizedBox(height: theme.spaceLG),

                  // 今日用药概况
                  _buildTodayCheckins(theme, report, isElderly),
                  SizedBox(height: theme.spaceLG),

                  // 本周趋势
                  _buildWeeklyTrend(theme, report, isElderly),
                  SizedBox(height: theme.spaceLG),

                  // 漏服记录
                  if (report != null && report.missedDoses > 0)
                    _buildMissedRecords(theme, report, isElderly),
                  if (report != null && report.missedDoses > 0)
                    SizedBox(height: theme.spaceLG),

                  // 快捷操作
                  _buildQuickActions(theme, isElderly),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsOverview(ThemeProvider theme, GuardianReport? report, bool isElderly) {
    final rate = report?.complianceRate ?? 0;
    final total = report?.totalDoses ?? 0;
    final completed = report?.completedDoses ?? 0;

    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Row(
          children: [
            SizedBox(
              width: isElderly ? 80 : 64,
              height: isElderly ? 80 : 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: total > 0 ? rate / 100 : 0,
                    strokeWidth: isElderly ? 6 : 4,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 80 ? const Color(0xFF52C41A) :
                      rate >= 60 ? const Color(0xFFFAAD14) :
                      const Color(0xFFFF4D4F),
                    ),
                  ),
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: isElderly ? 22 : 16,
                      fontWeight: FontWeight.bold,
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
                    '用药依从率',
                    style: TextStyle(
                      fontSize: theme.fontSizeH3,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  SizedBox(height: theme.spaceSM),
                  Text(
                    '已完成 $completed/$total 次',
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      color: theme.success,
                    ),
                  ),
                  if (report != null && report.missedDoses > 0)
                    Text(
                      '漏服 ${report.missedDoses} 次',
                      style: TextStyle(
                        fontSize: theme.fontSizeBodySmall,
                        color: const Color(0xFFFF4D4F),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCheckins(ThemeProvider theme, GuardianReport? report, bool isElderly) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日用药概况',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceMD),
            _buildCheckinItem(theme, '08:00', '硝苯地平 1片', true),
            Divider(color: theme.dividerColor),
            _buildCheckinItem(theme, '12:30', '二甲双胍 1片', true),
            Divider(color: theme.dividerColor),
            _buildCheckinItem(theme, '18:00', '阿司匹林 1片', false),
            Divider(color: theme.dividerColor),
            _buildCheckinItem(theme, '21:00', '他汀 1片', false),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinItem(ThemeProvider theme, String time, String medicine, bool done) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spaceSM),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.schedule,
            color: done ? const Color(0xFF52C41A) : const Color(0xFFD9D9D9),
            size: theme.iconStandard,
          ),
          SizedBox(width: theme.spaceMD),
          Expanded(
            child: Row(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: theme.spaceMD),
                Text(
                  medicine,
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend(ThemeProvider theme, GuardianReport? report, bool isElderly) {
    final trend = report?.trend ?? [];
    final days = ['一', '二', '三', '四', '五', '六', '日'];

    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周趋势',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceMD),
            SizedBox(
              height: 60,
              child: Row(
                children: List.generate(7, (index) {
                  final dayTrend = index < trend.length ? trend[index] : null;
                  final completed = dayTrend?.completed ?? 0;
                  final total = dayTrend?.total ?? 0;
                  bool? isCompleted;
                  if (total > 0) {
                    isCompleted = completed >= total;
                  }

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted == true
                                ? const Color(0xFF52C41A)
                                : isCompleted == false
                                    ? const Color(0xFFFF4D4F)
                                    : const Color(0xFFF0F0F0),
                          ),
                          child: Center(
                            child: isCompleted != null
                                ? Icon(
                                    isCompleted ? Icons.check : Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '-',
                                    style: TextStyle(
                                      color: theme.textDisabled,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: theme.spaceXS),
                        Text(
                          days[index],
                          style: TextStyle(
                            fontSize: theme.fontSizeCaption,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedRecords(ThemeProvider theme, GuardianReport report, bool isElderly) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4D4F), size: 20),
                SizedBox(width: theme.spaceSM),
                Text(
                  '本周漏服记录',
                  style: TextStyle(
                    fontSize: theme.fontSizeH3,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spaceMD),
            if (report.trend.isEmpty)
              Text(
                '本周无漏服记录',
                style: TextStyle(
                  fontSize: theme.fontSizeBody,
                  color: theme.success,
                ),
              )
            else
              ...report.trend
                  .where((t) => t.completed < t.total)
                  .map((t) => Padding(
                    padding: EdgeInsets.only(bottom: theme.spaceSM),
                    child: _buildMissedItem(theme, t.date, '漏服 ${t.total - t.completed} 次'),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedItem(ThemeProvider theme, String date, String content) {
    return Container(
      padding: EdgeInsets.all(theme.spaceMD),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(theme.radiusMD),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF4D4F), size: 20),
          SizedBox(width: theme.spaceSM),
          Text(
            '$date $content',
            style: TextStyle(
              fontSize: theme.fontSizeBodySmall,
              color: const Color(0xFFFF4D4F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeProvider theme, bool isElderly) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: theme.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: _sendReminder,
            icon: const Icon(Icons.notifications_active),
            label: Text(
              '提醒服药（发送通知给被监护人）',
              style: TextStyle(fontSize: theme.fontSizeButton),
            ),
          ),
        ),
        SizedBox(height: theme.spaceMD),
        SizedBox(
          width: double.infinity,
          height: theme.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.assessment),
            label: Text(
              '查看完整用药报告',
              style: TextStyle(fontSize: theme.fontSizeButton),
            ),
          ),
        ),
      ],
    );
  }
}
