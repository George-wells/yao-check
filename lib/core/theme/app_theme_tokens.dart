import 'package:flutter/material.dart';

/// 默认模式主题 Token
/// 设计规范来源：王悦 UI/UX设计师
/// 风格：冷静专业的蓝色系
class AppThemeTokens {
  // ==================== 颜色 ====================
  static const Color primary = Color(0xFF1890FF);
  static const Color primaryLight = Color(0xFFE6F7FF);
  static const Color primaryDark = Color(0xFF096DD9);
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color danger = Color(0xFFFF4D4F);
  static const Color info = Color(0xFF13C2C2);

  // 文字
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF595959);
  static const Color textDisabled = Color(0xFFBFBFBF);

  // 背景
  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFF0F0F0);

  // ==================== 圆角 ====================
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;

  // ==================== 间距 (8px网格) ====================
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double space2XL = 24.0;
  static const double space3XL = 32.0;
  static const double space4XL = 40.0;

  // ==================== 字体 ====================
  static const double fontSizeH1 = 24.0;
  static const double fontSizeH2 = 20.0;
  static const double fontSizeH3 = 18.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeBodySmall = 14.0;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeNumLarge = 32.0;
  static const double fontSizeNumMedium = 20.0;
  static const double fontSizeButton = 16.0;
  static const double fontSizeTab = 14.0;

  // ==================== 阴影 ====================
  static List<BoxShadow> get shadowLight => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowDeep => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowPrimary => [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ==================== 按钮 ====================
  static const double buttonHeight = 44.0;
  static const double buttonRadius = 8.0;
  static const double fabSize = 56.0;

  // ==================== 输入框 ====================
  static const double inputHeight = 44.0;
  static const double inputRadius = 8.0;

  // ==================== 底部导航 ====================
  static const double bottomNavHeight = 56.0;
  static const double bottomNavIconSize = 24.0;
  static const double bottomNavFontSize = 12.0;

  // ==================== 图标 ====================
  static const double iconStandard = 24.0;
  static const double iconSmall = 20.0;
  static const double iconLarge = 32.0;

  // ==================== 卡片 ====================
  static const double cardRadius = 12.0;
  static const double cardPadding = 16.0;
  static const double cardMargin = 12.0;
}
