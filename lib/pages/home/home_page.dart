import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/reminder_provider.dart';
import '../../widgets/elderly_button.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/reminder_card.dart';

/// 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final reminder = context.watch<ReminderProvider>();
    final isElderly = theme.isElderlyMode;
    final now = DateTime.now();

    final pages = [
      _buildHome(theme, reminder, isElderly, now),
      _buildRecords(theme, isElderly),
      _buildProfile(theme, isElderly),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: theme.primary,
        unselectedItemColor: theme.textDisabled,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: '记录'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '设置'),
        ],
      ),
    );
  }

  Widget _buildHome(ThemeProvider theme, ReminderProvider reminder, bool isElderly, DateTime now) {
    final pendingPlans = reminder.getPendingPlans();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          '${app_date_utils.DateUtils.getGreeting()}，用户',
          style: TextStyle(fontSize: theme.fontSizeH2),
        ),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isElderly ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期
            Text(
              '${app_date_utils.DateUtils.formatDateChinese(now)} ${app_date_utils.DateUtils.getChineseWeekday(now.weekday)}',
              style: TextStyle(fontSize: theme.fontSizeBody, color: theme.textSecondary),
            ),
            SizedBox(height: theme.spaceLG),

            // 今日概览
            _buildTodayOverview(theme, reminder, isElderly),

            SizedBox(height: theme.spaceLG),

            // 快捷操作
            Text(
              '快捷操作',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceMD),
            _buildQuickActions(theme, isElderly),

            SizedBox(height: theme.spaceLG),

            // 待服药提醒
            if (pendingPlans.isNotEmpty) ...[
              Text(
                '待服药项',
                style: TextStyle(
                  fontSize: theme.fontSizeH3,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              SizedBox(height: theme.spaceMD),
              ...pendingPlans.take(5).map((plan) => ReminderCard(
                time: plan.schedule.isNotEmpty ? plan.schedule.first.time : '08:00',
                medicineName: plan.medicineName,
                dosage: plan.dosageDescription.isNotEmpty ? plan.dosageDescription : '${plan.dosageValue}${plan.dosageUnit}',
                status: 'pending',

              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOverview(ThemeProvider theme, ReminderProvider reminder, bool isElderly) {
    final total = reminder.plans.length;
    final active = reminder.getPendingPlans().length;

    return Row(
      children: [
        Expanded(
          child: ProgressCard(
            title: '用药计划',
            value: '$total',
            unit: '个',
            icon: Icons.medication_outlined,
            color: theme.primary,
            isElderly: isElderly,
          ),
        ),
        SizedBox(width: theme.spaceMD),
        Expanded(
          child: ProgressCard(
            title: '待服药',
            value: '$active',
            unit: '项',
            icon: Icons.schedule,
            color: const Color(0xFFFA8C16),
            isElderly: isElderly,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeProvider theme, bool isElderly) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElderlyButton(
                icon: Icons.add_alarm_outlined,
                label: '添加提醒',
                onTap: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),

              ),
            ),
            SizedBox(width: theme.spaceMD),
            Expanded(
              child: ElderlyButton(
                icon: Icons.check_circle_outline,
                label: '服药打卡',
                onTap: () => Navigator.pushNamed(context, AppConstants.routeCheckin),

              ),
            ),
          ],
        ),
        SizedBox(height: theme.spaceButtonGap),
        Row(
          children: [
            Expanded(
              child: ElderlyButton(
                icon: Icons.search_outlined,
                label: '查药',
                onTap: () => Navigator.pushNamed(context, AppConstants.routeMedicines),

              ),
            ),
            SizedBox(width: theme.spaceMD),
            Expanded(
              child: ElderlyButton(
                icon: Icons.assignment_outlined,
                label: '处方管理',
                onTap: () => Navigator.pushNamed(context, AppConstants.routePrescriptions),

              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecords(ThemeProvider theme, bool isElderly) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('用药记录'),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: theme.textDisabled),
            const SizedBox(height: 16),
            Text(
              '记录功能',
              style: TextStyle(fontSize: theme.fontSizeBody, color: theme.textSecondary),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeRecords),
              child: const Text('查看详细记录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(ThemeProvider theme, bool isElderly) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(isElderly ? 24 : 16),
        children: [
          _buildMenuCard(theme, Icons.notifications_outlined, '用药提醒', () {
            Navigator.pushNamed(context, AppConstants.routeReminders);
          }, isElderly),
          SizedBox(height: theme.spaceMD),
          _buildMenuCard(theme, Icons.medication_outlined, '药品查询', () {
            Navigator.pushNamed(context, AppConstants.routeMedicines);
          }, isElderly),
          SizedBox(height: theme.spaceMD),
          _buildMenuCard(theme, Icons.assignment_outlined, '处方管理', () {
            Navigator.pushNamed(context, AppConstants.routePrescriptions);
          }, isElderly),
          SizedBox(height: theme.spaceMD),
          _buildMenuCard(theme, Icons.smart_toy_outlined, 'AI 设置', () {
            Navigator.pushNamed(context, AppConstants.routeSettings);
          }, isElderly),
          SizedBox(height: theme.spaceMD),
          _buildMenuCard(theme, Icons.palette_outlined, '适老化模式', () {
            theme.toggleElderlyMode();
          }, isElderly),
        ],
      ),
    );
  }

  Widget _buildMenuCard(ThemeProvider theme, IconData icon, String title, VoidCallback onTap, bool isElderly) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.primary),
        title: Text(title, style: TextStyle(fontSize: isElderly ? 18 : 16)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
