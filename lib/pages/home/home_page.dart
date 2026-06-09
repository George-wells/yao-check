import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/reminder_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/elderly_button.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/reminder_card.dart';
import '../../widgets/empty_state.dart';

/// 首页 - 用药计划概览（用药看板）
/// 展示今日用药进度、待服药列表、漏服提醒、快捷操作
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<ReminderProvider>().loadTodaySchedule();
  }

  /// 处理稍后提醒
  Future<void> _handleSnooze(Map<String, dynamic> args) async {
    final reminder = context.read<ReminderProvider>();
    await reminder.snoozeReminder(
      planId: args['planId'],
      medicineName: args['medicineName'] ?? '',
      dosage: args['dosage'] ?? '',
      scheduledTime: args['scheduledTime'] ?? '',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已设置15分钟后再次提醒'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 处理打卡
  void _navigateToCheckin(Map<String, dynamic> args) {
    Navigator.pushNamed(context, AppConstants.routeCheckin, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final reminder = context.watch<ReminderProvider>();
    final auth = context.watch<AuthProvider>();
    final isElderly = theme.isElderlyMode;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${app_date_utils.DateUtils.getGreeting()}，${auth.user?.name ?? '用户'}',
              style: TextStyle(
                fontSize: isElderly ? 28 : 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            Text(
              '${app_date_utils.DateUtils.formatDateChinese(now)} ${app_date_utils.DateUtils.getChineseWeekday(now.weekday)}',
              style: TextStyle(
                fontSize: isElderly ? 20 : 14,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_outlined, size: theme.iconStandard),
                if (reminder.hasMissedDose)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF4D4F),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.person_outline, size: theme.iconStandard),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isElderly ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 今日用药进度卡片
              _buildProgressCard(theme, reminder),

              SizedBox(height: isElderly ? 20 : 16),

              // 漏服提醒（如有）
              if (reminder.hasMissedDose && reminder.missedLogs.isNotEmpty)
                _buildMissedDoseAlert(theme, reminder),

              if (reminder.hasMissedDose && reminder.missedLogs.isNotEmpty)
                SizedBox(height: isElderly ? 16 : 12),

              // 连续漏服关怀提醒
              if (reminder.consecutiveMissedDays >= AppConstants.consecutiveMissedThreshold)
                _buildCareAlert(theme, reminder),

              if (reminder.consecutiveMissedDays >= AppConstants.consecutiveMissedThreshold)
                SizedBox(height: isElderly ? 16 : 12),

              // 待服药提醒列表标题
              Text(
                '今日用药计划',
                style: TextStyle(
                  fontSize: theme.fontSizeH3,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              SizedBox(height: isElderly ? 16 : 12),

              // 待服药列表
              if (reminder.todaySchedule == null || reminder.todaySchedule!.total == 0)
                EmptyState(
                  icon: Icons.medication_outlined,
                  title: '暂无用药提醒',
                  subtitle: '点击下方按钮添加您的第一个用药提醒',
                  actionLabel: '添加用药提醒',
                  onAction: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),
                )
              else
                ..._buildReminderList(theme, reminder),

              SizedBox(height: isElderly ? 24 : 16),

              // 快捷操作
              if (isElderly)
                _buildElderlyQuickActions(theme)
              else
                _buildQuickActions(theme),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 今日进度卡片
  Widget _buildProgressCard(ThemeProvider theme, ReminderProvider reminder) {
    final schedule = reminder.todaySchedule;
    final progress = schedule?.progress ?? 0;
    final total = schedule?.total ?? 0;
    final completed = schedule?.completed ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          children: [
            Row(
              children: [
                // 圆形进度
                SizedBox(
                  width: theme.isElderlyMode ? 80 : 64,
                  height: theme.isElderlyMode ? 80 : 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: theme.isElderlyMode ? 80 : 64,
                        height: theme.isElderlyMode ? 80 : 64,
                        child: CircularProgressIndicator(
                          value: total > 0 ? progress / 100.0 : 0,
                          strokeWidth: theme.isElderlyMode ? 6 : 4,
                          backgroundColor: const Color(0xFFF0F0F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 80 ? theme.success : theme.primary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$completed/$total',
                            style: TextStyle(
                              fontSize: theme.fontSizeNumMedium,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                          Text(
                            '项',
                            style: TextStyle(
                              fontSize: theme.fontSizeCaption,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: theme.spaceLG),
                // 文字说明
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日用药进度',
                        style: TextStyle(
                          fontSize: theme.fontSizeH3,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      SizedBox(height: theme.spaceSM),
                      Text(
                        '已完成 $completed 项',
                        style: TextStyle(
                          fontSize: theme.fontSizeBody,
                          color: theme.success,
                        ),
                      ),
                      if (total - completed > 0)
                        Text(
                          '剩余 ${total - completed} 项待服',
                          style: TextStyle(
                            fontSize: theme.fontSizeBodySmall,
                            color: theme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (theme.isElderlyMode) ...[
              SizedBox(height: theme.spaceLG),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? progress / 100.0 : 0,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              ),
              SizedBox(height: theme.spaceMD),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.volume_up, size: 20),
                  label: const Text('语音播报今日计划'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 漏服提醒横幅
  Widget _buildMissedDoseAlert(ThemeProvider theme, ReminderProvider reminder) {
    return Container(
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(
          color: const Color(0xFFFF4D4F).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: theme.danger, size: theme.iconStandard),
              SizedBox(width: theme.spaceSM),
              Text(
                '漏服提醒',
                style: TextStyle(
                  fontSize: theme.fontSizeH3,
                  fontWeight: FontWeight.bold,
                  color: theme.danger,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spaceSM),
          ...reminder.missedLogs.map((log) => Padding(
            padding: EdgeInsets.only(bottom: theme.spaceSM),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: theme.danger),
                SizedBox(width: theme.spaceSM),
                Expanded(
                  child: Text(
                    '${log.scheduledTime} ${log.medicineName ?? ''} ${log.dosageDescription ?? ''}',
                    style: TextStyle(
                      fontSize: theme.fontSizeBodySmall,
                      color: theme.danger,
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: () => _navigateToCheckin({
                      'planId': log.planId,
                      'medicineName': log.medicineName,
                      'dosage': log.dosageDescription,
                      'scheduledTime': log.scheduledTime,
                      'scheduledDate': log.scheduledDate,
                      'isMakeup': true,
                    }),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: theme.danger,
                    ),
                    child: const Text('补服', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )),
          // 补服/跳过按钮
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: theme.isElderlyMode ? 48 : 36,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (reminder.missedLogs.isNotEmpty) {
                        _navigateToCheckin({
                          'planId': reminder.missedLogs.first.planId,
                          'medicineName': reminder.missedLogs.first.medicineName,
                          'dosage': reminder.missedLogs.first.dosageDescription,
                          'scheduledTime': reminder.missedLogs.first.scheduledTime,
                          'scheduledDate': reminder.missedLogs.first.scheduledDate,
                          'isMakeup': true,
                        });
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('补服'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.warning,
                    ),
                  ),
                ),
              ),
              SizedBox(width: theme.spaceSM),
              Expanded(
                child: SizedBox(
                  height: theme.isElderlyMode ? 48 : 36,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('跳过'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 连续漏服关怀提醒
  Widget _buildCareAlert(ThemeProvider theme, ReminderProvider reminder) {
    return Container(
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(
          color: const Color(0xFFFAAD14).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: theme.warning, size: theme.iconStandard),
          SizedBox(width: theme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '用药关怀提醒',
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    fontWeight: FontWeight.bold,
                    color: theme.warning,
                  ),
                ),
                Text(
                  '您已连续 ${reminder.consecutiveMissedDays} 天漏服，建议咨询医生调整用药方案',
                  style: TextStyle(
                    fontSize: theme.fontSizeCaption,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建提醒列表
  List<Widget> _buildReminderList(ThemeProvider theme, ReminderProvider reminder) {
    final schedule = reminder.todaySchedule!;
    final items = <Widget>[];

    // 待服项
    for (final item in schedule.pendingItems) {
      items.add(
        ReminderCard(
          time: item.scheduledTime,
          medicineName: item.medicineName ?? '',
          dosage: item.dosageDescription ?? '',
          status: 'pending',
          isElderly: theme.isElderlyMode,
          onCheckin: () => _navigateToCheckin({
            'planId': item.planId,
            'medicineName': item.medicineName,
            'dosage': item.dosageDescription,
            'scheduledTime': item.scheduledTime,
            'scheduledDate': item.scheduledDate,
          }),
          onSnooze: () => _handleSnooze({
            'planId': item.planId,
            'medicineName': item.medicineName,
            'dosage': item.dosageDescription,
            'scheduledTime': item.scheduledTime,
          }),
        ),
      );
    }

    // 已服项
    for (final item in schedule.completedItems) {
      items.add(
        ReminderCard(
          time: item.scheduledTime,
          medicineName: item.medicineName ?? '',
          dosage: item.dosageDescription ?? '',
          status: 'taken',
          isElderly: theme.isElderlyMode,
        ),
      );
    }

    // 漏服项
    for (final item in schedule.missedItems) {
      items.add(
        ReminderCard(
          time: item.scheduledTime,
          medicineName: item.medicineName ?? '',
          dosage: item.dosageDescription ?? '',
          status: 'missed',
          isElderly: theme.isElderlyMode,
          onCheckin: () => _navigateToCheckin({
            'planId': item.planId,
            'medicineName': item.medicineName,
            'dosage': item.dosageDescription,
            'scheduledTime': item.scheduledTime,
            'scheduledDate': item.scheduledDate,
            'isMakeup': true,
          }),
        ),
      );
    }

    return items;
  }

  /// 快捷操作栏（默认模式）
  Widget _buildQuickActions(ThemeProvider theme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_circle_outline,
            label: '添加',
            color: theme.primary,
            onTap: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),
          ),
        ),
        SizedBox(width: theme.spaceMD),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.qr_code_scanner_outlined,
            label: '扫码',
            color: theme.info,
            onTap: () {},
          ),
        ),
        SizedBox(width: theme.spaceMD),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.check_circle_outline,
            label: '打卡',
            color: theme.success,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  /// 快捷操作（适老化模式）
  Widget _buildElderlyQuickActions(ThemeProvider theme) {
    return Column(
      children: [
        ElderlyButton(
          icon: Icons.add_circle_outline,
          label: '添加用药提醒',
          onTap: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),
        ),
        SizedBox(height: theme.spaceButtonGap),
        ElderlyButton(
          icon: Icons.qr_code_scanner_outlined,
          label: '扫码查药',
          onTap: () {},
        ),
        SizedBox(height: theme.spaceButtonGap),
        ElderlyButton(
          icon: Icons.check_circle_outline,
          label: '服药打卡',
          onTap: () {},
        ),
      ],
    );
  }
}

/// 快捷操作按钮
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
