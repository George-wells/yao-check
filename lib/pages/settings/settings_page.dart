import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

/// 设置页（增强版）
/// 包含：适老化模式切换（字体缩放、高对比度、语音播报）、个人信息、通知设置
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isElderly ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 适老化模式开关（顶部突出）
            _buildElderlyModeCard(theme),
            SizedBox(height: theme.spaceLG),

            // 适老化详细设置（仅在适老化模式下显示）
            if (isElderly) ...[
              _buildSectionTitle(theme, '适老化设置'),
              _buildSettingCard(theme, [
                _buildFontScaleSetting(theme),
                _buildSwitchItem(theme, Icons.contrast_outlined, '高对比度模式', theme.highContrast, (v) => theme.setHighContrast(v)),
                _buildSwitchItem(theme, Icons.volume_up_outlined, '语音播报', theme.enableVoice, (v) => theme.setEnableVoice(v)),
                _buildSwitchItem(theme, Icons.vibration, '震动反馈', true, (_) {}),
              ]),
              SizedBox(height: theme.spaceLG),
            ],

            // 个人信息
            if (!isElderly) ...[
              _buildSectionTitle(theme, '个人信息'),
              _buildSettingCard(theme, [
                _buildSettingItem(theme, Icons.person_outline, '头像 + ${auth.user?.name ?? '用户'}', '138****1234'),
                _buildSettingItem(theme, Icons.cake_outlined, '出生日期', '1960-01-01'),
                _buildSettingItem(theme, Icons.emergency_outlined, '紧急联系人', '王建国（儿子）'),
              ]),
              SizedBox(height: theme.spaceLG),
            ],

            // 通知设置
            if (!isElderly) ...[
              _buildSectionTitle(theme, '通知设置'),
              _buildSettingCard(theme, [
                _buildSwitchItem(theme, Icons.notifications_outlined, '服药提醒推送', true, (_) {}),
                _buildSettingItem(theme, Icons.volume_up_outlined, '提醒声音', '标准'),
                _buildSwitchItem(theme, Icons.vibration, '震动提醒', true, (_) {}),
                _buildSettingItem(theme, Icons.do_not_disturb_outlined, '免打扰时段', '22:00-7:00'),
              ]),
              SizedBox(height: theme.spaceLG),
            ],

            // 其他
            if (!isElderly) ...[
              _buildSectionTitle(theme, '其他'),
              _buildSettingCard(theme, [
                _buildSettingItem(theme, Icons.help_outline, '使用帮助', ''),
                _buildSettingItem(theme, Icons.privacy_tip_outlined, '隐私政策', ''),
                _buildSettingItem(theme, Icons.info_outline, '关于我们', ''),
                _buildSettingItem(theme, Icons.phone_android, '版本', 'v1.0.0'),
              ]),
              SizedBox(height: theme.spaceLG),
            ],

            // 退出登录
            SizedBox(
              width: double.infinity,
              height: theme.buttonHeight,
              child: OutlinedButton(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppConstants.routeLogin,
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: Text(
                  '退出登录',
                  style: TextStyle(fontSize: theme.fontSizeButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElderlyModeCard(ThemeProvider theme) {
    final isElderly = theme.isElderlyMode;

    return Container(
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        boxShadow: theme.shadowMedium,
        border: Border.all(
          color: theme.primary.withOpacity(0.3),
          width: isElderly ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.visibility, color: theme.primary, size: 28),
              ),
              SizedBox(width: theme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '适老化模式',
                      style: TextStyle(
                        fontSize: theme.fontSizeH3,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      isElderly ? '当前：已开启' : '大字体 · 高对比度 · 简化布局',
                      style: TextStyle(
                        fontSize: theme.fontSizeCaption,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isElderly,
                onChanged: (value) => theme.toggleMode(),
                activeColor: theme.primary,
              ),
            ],
          ),
          if (isElderly) ...[
            SizedBox(height: theme.spaceMD),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => theme.setMode(ThemeModeType.normal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: theme.textPrimary,
                ),
                child: const Text('关闭适老化模式'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 字体缩放设置
  Widget _buildFontScaleSetting(ThemeProvider theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.cardPadding,
        vertical: theme.spaceMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: theme.textSecondary, size: theme.iconStandard),
              SizedBox(width: theme.spaceMD),
              Text(
                '字体大小',
                style: TextStyle(
                  fontSize: theme.fontSizeBody,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spaceSM),
          Row(
            children: FontScaleLevel.values.map((level) {
              final selected = theme.fontScale == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () => theme.setFontScale(level),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    margin: EdgeInsets.only(right: level != FontScaleLevel.values.last ? 8 : 0),
                    decoration: BoxDecoration(
                      color: selected ? theme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? theme.primary : const Color(0xFFE8E8E8),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          level.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: selected ? Colors.white : theme.textPrimary,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(level.scale * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white70 : theme.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          // 预览文字
          SizedBox(height: theme.spaceSM),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '预览：智能用药App',
              style: TextStyle(
                fontSize: 14 * theme.effectiveFontScale,
                color: theme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeProvider theme, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spaceSM),
      child: Text(
        title,
        style: TextStyle(
          fontSize: theme.fontSizeBodySmall,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingCard(ThemeProvider theme, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        boxShadow: theme.shadowLight,
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingItem(ThemeProvider theme, IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.cardPadding,
        vertical: theme.spaceMD,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.textSecondary, size: theme.iconStandard),
          SizedBox(width: theme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    color: theme.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: theme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.textDisabled, size: 20),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(ThemeProvider theme, IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.cardPadding,
        vertical: theme.spaceMD,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.textSecondary, size: theme.iconStandard),
          SizedBox(width: theme.spaceMD),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: theme.fontSizeBody,
                color: theme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }
}
