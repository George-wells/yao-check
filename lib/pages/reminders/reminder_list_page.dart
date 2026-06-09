import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/string_utils.dart';
import '../../providers/reminder_provider.dart';
import '../../models/medication_plan.dart';
import '../../widgets/empty_state.dart';

/// 用药计划列表页
/// 展示所有活跃的用药计划，支持编辑和删除
class ReminderListPage extends StatefulWidget {
  const ReminderListPage({super.key});

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReminderProvider>().loadPlans();
  }

  Future<void> _deletePlan(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「$name」的用药提醒吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final reminder = context.read<ReminderProvider>();
      final success = await reminder.deletePlan(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '已删除' : '删除失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final reminder = context.watch<ReminderProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('用药提醒'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: theme.iconStandard),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => reminder.loadPlans(),
        child: reminder.plans.isEmpty
            ? EmptyState(
                icon: Icons.alarm_outlined,
                title: '暂无用药提醒',
                subtitle: '点击右上角 + 添加您的第一个用药提醒',
                actionLabel: '添加用药提醒',
                onAction: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),
              )
            : ListView.builder(
                padding: EdgeInsets.all(isElderly ? 20 : 16),
                itemCount: reminder.plans.length,
                itemBuilder: (context, index) {
                  final plan = reminder.plans[index];
                  return _buildPlanCard(theme, plan, isElderly);
                },
              ),
      ),
    );
  }

  Widget _buildPlanCard(ThemeProvider theme, MedicationPlan plan, bool isElderly) {
    final scheduleStr = plan.schedule
        .map((s) => s.time)
        .join(', ');
    final frequencyLabel = StringUtils.getFrequencyLabel(
      plan.frequencyType,
      plan.frequencyTimesPerDay,
      plan.frequencyInterval,
    );

    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(theme.cardRadius),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        await _deletePlan(plan.id, plan.medicineName);
        return false;
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isElderly ? 16 : 12),
        padding: EdgeInsets.all(isElderly ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          boxShadow: theme.shadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isElderly ? 48 : 40,
                  height: isElderly ? 48 : 40,
                  decoration: BoxDecoration(
                    color: theme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: theme.primary,
                    size: isElderly ? 28 : 22,
                  ),
                ),
                SizedBox(width: theme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.medicineName,
                        style: TextStyle(
                          fontSize: isElderly ? 22 : 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        '${StringUtils.formatDosage(plan.dosageValue, plan.dosageUnit)} · $frequencyLabel',
                        style: TextStyle(
                          fontSize: isElderly ? 18 : 13,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 状态开关
                Switch(
                  value: plan.isActive,
                  onChanged: (_) {},
                  activeColor: theme.primary,
                ),
              ],
            ),
            SizedBox(height: theme.spaceSM),
            // 服药时间
            Row(
              children: [
                Icon(Icons.access_time, size: isElderly ? 22 : 16, color: theme.textSecondary),
                SizedBox(width: theme.spaceSM),
                Text(
                  scheduleStr,
                  style: TextStyle(
                    fontSize: isElderly ? 18 : 13,
                    color: theme.textSecondary,
                  ),
                ),
                const Spacer(),
                // 剩余数量
                if (plan.stockQuantity != null)
                  Text(
                    StringUtils.formatStockReminder(plan.stockQuantity, plan.stockUnit),
                    style: TextStyle(
                      fontSize: isElderly ? 16 : 12,
                      color: (plan.stockQuantity ?? 0) <= 7
                          ? const Color(0xFFFAAD14)
                          : theme.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
