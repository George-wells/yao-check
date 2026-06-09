import 'package:flutter/material.dart';

/// 适老化模式主题 Token
/// 设计规范来源：王悦 UI/UX设计师
/// 风格：温暖舒适的橙色系，WCAG AA标准
class ElderlyThemeTokens {
  // ==================== 颜色 ====================
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFFF2E8);
  static const Color primaryDark = Color(0xFFD94A1A);
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color danger = Color(0xFFFF4D4F);
  static const Color info = Color(0xFF13C2C2);

  // 文字（高对比度 ≥7:1）
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4D4D4D);
  static const Color textDisabled = Color(0xFFBFBFBF);

  // 背景（暖白）
  static const Color background = Color(0xFFFFFBF7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFF0F0F0);

  // ==================== 圆角（增大） ====================
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // ==================== 间距（增大） ====================
  static const double spaceCardPadding = 20.0;
  static const double spacePageMargin = 24.0;
  static const double spaceItemGap = 18.0;
  static const double spaceButtonGap = 20.0;

  // ==================== 字体（放大1.5倍） ====================
  static const double fontSizeH1 = 36.0;
  static const double fontSizeH2 = 30.0;
  static const double fontSizeH3 = 26.0;
  static const double fontSizeBody = 24.0;
  static const double fontSizeBodySmall = 20.0;
  static const double fontSizeCaption = 16.0;
  static const double fontSizeNumLarge = 48.0;
  static const double fontSizeNumMedium = 30.0;
  static const double fontSizeButton = 22.0;
  static const double fontSizeTab = 18.0;

  // ==================== 阴影（加深20%） ====================
  static List<BoxShadow> get shadowLight => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowDeep => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowPrimary => [
    BoxShadow(
      color: primary.withOpacity(0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ==================== 按钮 ====================
  static const double buttonHeight = 56.0;
  static const double buttonRadius = 12.0;
  static const double fabSize = 64.0;

  // ==================== 输入框 ====================
  static const double inputHeight = 52.0;
  static const double inputRadius = 12.0;

  // ==================== 底部导航 ====================
  static const double bottomNavHeight = 72.0;
  static const double bottomNavIconSize = 32.0;
  static const double bottomNavFontSize = 16.0;

  // ==================== 图标（放大1.3倍） ====================
  static const double iconStandard = 32.0;
  static const double iconSmall = 28.0;
  static const double iconLarge = 44.0;

  // ==================== 卡片 ====================
  static const double cardRadius = 16.0;
  static const double cardPadding = 20.0;
  static const double cardMargin = 16.0;

  // ==================== 触控目标 ====================
  static const double minTouchTarget = 48.0;
}
