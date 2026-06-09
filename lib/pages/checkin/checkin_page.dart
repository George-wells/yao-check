import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/reminder_provider.dart';

/// 服药打卡页
/// 展示药品信息，提供已服药/补服/跳过/稍后提醒操作
class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isDone = false;
  int _undoCountdown = 300; // 5分钟 = 300秒
  bool _undoTimerActive = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppConstants.checkinSuccessDuration,
    );
    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _doCheckin(String status, {bool isMakeup = false}) async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final data = {
      'planId': args['planId'],
      'scheduledDate': args['scheduledDate'],
      'scheduledTime': args['scheduledTime'],
      'status': status,
      'isMakeup': isMakeup,
    };

    final reminder = context.read<ReminderProvider>();
    final success = await reminder.checkin(data);

    if (success && mounted) {
      setState(() {
        _isDone = true;
        _undoCountdown = 300;
        _undoTimerActive = true;
      });
      _animController.forward();
      _startUndoTimer();
    }
  }

  /// 启动撤销倒计时（5分钟）
  void _startUndoTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_undoTimerActive) return false;
      setState(() => _undoCountdown--);
      if (_undoCountdown <= 0) {
        _undoTimerActive = false;
        if (mounted) Navigator.pop(context);
        return false;
      }
      return true;
    });
  }

  /// 撤销打卡
  Future<void> _undoCheckin() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final reminder = context.read<ReminderProvider>();
    // 通过获取最近一条打卡记录的ID来撤销
    final logs = await reminder.getCheckins(
      startDate: args['scheduledDate'],
      endDate: args['scheduledDate'],
    );
    if (logs.isNotEmpty && mounted) {
      final log = logs.firstWhere(
        (l) => l.planId == args['planId'] && l.scheduledTime == args['scheduledTime'],
        orElse: () => logs.first,
      );
      final success = await reminder.undoCheckin(log.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已撤销打卡'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('撤销失败，已超过5分钟窗口'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 稍后提醒
  Future<void> _snooze() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isMakeup = args?['isMakeup'] == true;
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(isMakeup ? '补服打卡' : '服药打卡'),
      ),
      body: Center(
        child: _isDone
            ? _buildSuccessAnimation(theme)
            : _buildCheckinContent(theme, args, isMakeup, isElderly),
      ),
    );
  }

  Widget _buildSuccessAnimation(ThemeProvider theme) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.success.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 64,
              color: Color(0xFF52C41A),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '打卡成功！',
            style: TextStyle(
              fontSize: theme.fontSizeH1,
              fontWeight: FontWeight.bold,
              color: theme.success,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已记录服药信息',
            style: TextStyle(
              fontSize: theme.fontSizeBody,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // 撤销按钮（5分钟内可撤销）
          if (_undoTimerActive)
            SizedBox(
              width: double.infinity,
              height: theme.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: _undoCheckin,
                icon: const Icon(Icons.undo),
                label: Text(
                  '撤销打卡（${_undoCountdown ~/ 60}:${(_undoCountdown % 60).toString().padLeft(2, '0')}）',
                  style: TextStyle(fontSize: theme.fontSizeButton),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.warning,
                  side: BorderSide(color: theme.warning),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '${_undoCountdown ~/ 60}:${(_undoCountdown % 60).toString().padLeft(2, '0')} 后可自动返回',
            style: TextStyle(
              fontSize: theme.fontSizeCaption,
              color: theme.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinContent(
    ThemeProvider theme,
    Map<String, dynamic>? args,
    bool isMakeup,
    bool isElderly,
  ) {
    return Padding(
      padding: EdgeInsets.all(isElderly ? 32 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 药品图标
          Container(
            width: isElderly ? 100 : 80,
            height: isElderly ? 100 : 80,
            decoration: BoxDecoration(
              color: theme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.medication,
              size: isElderly ? 56 : 44,
              color: theme.primary,
            ),
          ),
          SizedBox(height: isElderly ? 32 : 24),

          // 药品名称
          Text(
            args?['medicineName'] ?? '',
            style: TextStyle(
              fontSize: theme.fontSizeH1,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          SizedBox(height: theme.spaceSM),

          // 剂量
          Text(
            args?['dosage'] ?? '',
            style: TextStyle(
              fontSize: theme.fontSizeH3,
              color: theme.textSecondary,
            ),
          ),
          SizedBox(height: theme.spaceLG),

          // 预定时间
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: theme.iconStandard, color: theme.textSecondary),
              SizedBox(width: theme.spaceSM),
              Text(
                '预定时间：${args?['scheduledTime'] ?? ''}',
                style: TextStyle(
                  fontSize: theme.fontSizeBody,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),

          if (isMakeup) ...[
            SizedBox(height: theme.spaceSM),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spaceLG,
                vertical: theme.spaceSM,
              ),
              decoration: BoxDecoration(
                color: theme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(theme.radiusMD),
              ),
              child: Text(
                '⚠️ 已延迟，请确认是否补服',
                style: TextStyle(
                  fontSize: theme.fontSizeBodySmall,
                  color: theme.warning,
                ),
              ),
            ),
          ],

          SizedBox(height: isElderly ? 48 : 40),

          // 已服药/补服按钮
          SizedBox(
            width: double.infinity,
            height: theme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => _doCheckin(isMakeup ? 'late' : 'taken', isMakeup: isMakeup),
              icon: Icon(
                isMakeup ? Icons.refresh : Icons.check_circle,
                size: theme.iconStandard,
              ),
              label: Text(
                isMakeup ? '确认补服' : '已服药',
                style: TextStyle(
                  fontSize: theme.fontSizeButton,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMakeup ? theme.warning : theme.success,
              ),
            ),
          ),
          SizedBox(height: theme.spaceMD),

          // 稍后提醒按钮
          if (!isMakeup)
            SizedBox(
              width: double.infinity,
              height: theme.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: _snooze,
                icon: const Icon(Icons.alarm),
                label: Text(
                  '稍后提醒（15分钟）',
                  style: TextStyle(fontSize: theme.fontSizeButton),
                ),
              ),
            ),
          if (!isMakeup)
            SizedBox(height: theme.spaceMD),

          // 跳过按钮
          SizedBox(
            width: double.infinity,
            height: theme.buttonHeight,
            child: TextButton.icon(
              onPressed: () => _doCheckin('skipped'),
              icon: const Icon(Icons.skip_next),
              label: Text(
                '跳过此次',
                style: TextStyle(
                  fontSize: theme.fontSizeButton,
                  color: theme.textSecondary,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
