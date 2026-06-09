import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme_tokens.dart';
import 'elderly_theme_tokens.dart';

/// 主题模式枚举
enum ThemeModeType { normal, elderly }

/// 适老化字体缩放级别
enum FontScaleLevel {
  normal('标准', 1.0),
  large('大', 1.25),
  extraLarge('超大', 1.5);

  final String label;
  final double scale;
  const FontScaleLevel(this.label, this.scale);
}

/// 全局主题状态管理 Provider（增强版）
/// 支持默认现代化风格和适老化模式两套主题的无缝切换
/// 适老化模式包含：大字体、高对比度、大触控目标、语音播报、简化布局
class ThemeProvider extends ChangeNotifier {
  ThemeModeType _mode = ThemeModeType.normal;
  FontScaleLevel _fontScale = FontScaleLevel.extraLarge;
  bool _highContrast = true;
  bool _enableVoice = false;
  bool _initialized = false;

  ThemeModeType get mode => _mode;
  bool get isElderlyMode => _mode == ThemeModeType.elderly;
  bool get isInitialized => _initialized;
  FontScaleLevel get fontScale => _fontScale;
  bool get highContrast => _highContrast;
  bool get enableVoice => _enableVoice;

  /// 实际字体缩放倍数
  double get effectiveFontScale => isElderlyMode ? _fontScale.scale : 1.0;

  // ==================== 颜色 ====================
  Color get primary => isElderlyMode ? ElderlyThemeTokens.primary : AppThemeTokens.primary;
  Color get primaryLight => isElderlyMode ? ElderlyThemeTokens.primaryLight : AppThemeTokens.primaryLight;
  Color get primaryDark => isElderlyMode ? ElderlyThemeTokens.primaryDark : AppThemeTokens.primaryDark;
  Color get success => AppThemeTokens.success;
  Color get warning => AppThemeTokens.warning;
  Color get danger => AppThemeTokens.danger;
  Color get info => AppThemeTokens.info;

  Color get textPrimary => isElderlyMode ? ElderlyThemeTokens.textPrimary : AppThemeTokens.textPrimary;
  Color get textSecondary => isElderlyMode ? ElderlyThemeTokens.textSecondary : AppThemeTokens.textSecondary;
  Color get textDisabled => AppThemeTokens.textDisabled;

  Color get background => isElderlyMode ? ElderlyThemeTokens.background : AppThemeTokens.background;
  Color get cardColor => AppThemeTokens.card;
  Color get dividerColor => AppThemeTokens.divider;

  // ==================== 圆角 ====================
  double get radiusSM => isElderlyMode ? ElderlyThemeTokens.radiusSM : AppThemeTokens.radiusSM;
  double get radiusMD => isElderlyMode ? ElderlyThemeTokens.radiusMD : AppThemeTokens.radiusMD;
  double get radiusLG => isElderlyMode ? ElderlyThemeTokens.radiusLG : AppThemeTokens.radiusLG;
  double get radiusXL => isElderlyMode ? ElderlyThemeTokens.radiusXL : AppThemeTokens.radiusXL;

  // ==================== 间距 ====================
  double get spaceXS => AppThemeTokens.spaceXS;
  double get spaceSM => AppThemeTokens.spaceSM;
  double get spaceMD => AppThemeTokens.spaceMD;
  double get spaceLG => isElderlyMode ? ElderlyThemeTokens.spaceCardPadding : AppThemeTokens.spaceLG;
  double get spaceXL => isElderlyMode ? ElderlyThemeTokens.spacePageMargin : AppThemeTokens.spaceXL;
  double get spaceButtonGap => isElderlyMode ? 16.0 : 12.0;
  double get space2XL => AppThemeTokens.space2XL;
  double get space3XL => AppThemeTokens.space3XL;
  double get space4XL => AppThemeTokens.space4XL;

  // ==================== 字体（应用缩放倍数） ====================
  double get fontSizeH1 => (isElderlyMode ? ElderlyThemeTokens.fontSizeH1 : AppThemeTokens.fontSizeH1) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeH2 => (isElderlyMode ? ElderlyThemeTokens.fontSizeH2 : AppThemeTokens.fontSizeH2) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeH3 => (isElderlyMode ? ElderlyThemeTokens.fontSizeH3 : AppThemeTokens.fontSizeH3) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeBody => (isElderlyMode ? ElderlyThemeTokens.fontSizeBody : AppThemeTokens.fontSizeBody) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeBodySmall => (isElderlyMode ? ElderlyThemeTokens.fontSizeBodySmall : AppThemeTokens.fontSizeBodySmall) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeCaption => (isElderlyMode ? ElderlyThemeTokens.fontSizeCaption : AppThemeTokens.fontSizeCaption) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeNumLarge => (isElderlyMode ? ElderlyThemeTokens.fontSizeNumLarge : AppThemeTokens.fontSizeNumLarge) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeNumMedium => (isElderlyMode ? ElderlyThemeTokens.fontSizeNumMedium : AppThemeTokens.fontSizeNumMedium) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeButton => (isElderlyMode ? ElderlyThemeTokens.fontSizeButton : AppThemeTokens.fontSizeButton) * (isElderlyMode ? _fontScale.scale : 1.0);
  double get fontSizeTab => (isElderlyMode ? ElderlyThemeTokens.fontSizeTab : AppThemeTokens.fontSizeTab) * (isElderlyMode ? _fontScale.scale : 1.0);

  // ==================== 阴影 ====================
  List<BoxShadow> get shadowLight => isElderlyMode ? ElderlyThemeTokens.shadowLight : AppThemeTokens.shadowLight;
  List<BoxShadow> get shadowMedium => isElderlyMode ? ElderlyThemeTokens.shadowMedium : AppThemeTokens.shadowMedium;
  List<BoxShadow> get shadowDeep => isElderlyMode ? ElderlyThemeTokens.shadowDeep : AppThemeTokens.shadowDeep;
  List<BoxShadow> get shadowPrimary => isElderlyMode ? ElderlyThemeTokens.shadowPrimary : AppThemeTokens.shadowPrimary;

  // ==================== 按钮 ====================
  double get buttonHeight => isElderlyMode ? ElderlyThemeTokens.buttonHeight : AppThemeTokens.buttonHeight;
  double get buttonRadius => isElderlyMode ? ElderlyThemeTokens.buttonRadius : AppThemeTokens.buttonRadius;
  double get fabSize => isElderlyMode ? ElderlyThemeTokens.fabSize : AppThemeTokens.fabSize;

  // ==================== 输入框 ====================
  double get inputHeight => isElderlyMode ? ElderlyThemeTokens.inputHeight : AppThemeTokens.inputHeight;
  double get inputRadius => isElderlyMode ? ElderlyThemeTokens.inputRadius : AppThemeTokens.inputRadius;

  // ==================== 底部导航 ====================
  double get bottomNavHeight => isElderlyMode ? ElderlyThemeTokens.bottomNavHeight : AppThemeTokens.bottomNavHeight;
  double get bottomNavIconSize => isElderlyMode ? ElderlyThemeTokens.bottomNavIconSize : AppThemeTokens.bottomNavIconSize;

  // ==================== 图标 ====================
  double get iconStandard => isElderlyMode ? ElderlyThemeTokens.iconStandard : AppThemeTokens.iconStandard;
  double get iconSmall => isElderlyMode ? ElderlyThemeTokens.iconSmall : AppThemeTokens.iconSmall;
  double get iconLarge => isElderlyMode ? ElderlyThemeTokens.iconLarge : AppThemeTokens.iconLarge;

  // ==================== 卡片 ====================
  double get cardRadius => isElderlyMode ? ElderlyThemeTokens.cardRadius : AppThemeTokens.cardRadius;
  double get cardPadding => isElderlyMode ? ElderlyThemeTokens.cardPadding : AppThemeTokens.cardPadding;
  double get cardMargin => isElderlyMode ? ElderlyThemeTokens.cardMargin : AppThemeTokens.cardMargin;

  // ==================== 触控目标 ====================
  double get minTouchTarget => isElderlyMode ? ElderlyThemeTokens.minTouchTarget : 44.0;

  /// 从本地存储加载偏好设置
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode') ?? 'normal';
    _mode = savedMode == 'elderly' ? ThemeModeType.elderly : ThemeModeType.normal;

    // 加载适老化子设置
    final savedFontScale = prefs.getString('font_scale') ?? 'extraLarge';
    _fontScale = FontScaleLevel.values.firstWhere(
      (f) => f.name == savedFontScale,
      orElse: () => FontScaleLevel.extraLarge,
    );
    _highContrast = prefs.getBool('high_contrast') ?? true;
    _enableVoice = prefs.getBool('enable_voice') ?? false;

    _initialized = true;
    notifyListeners();
  }

  /// 切换适老化模式
  Future<void> toggleMode() async {
    _mode = isElderlyMode ? ThemeModeType.normal : ThemeModeType.elderly;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _mode == ThemeModeType.elderly ? 'elderly' : 'normal');
  }

  /// 设置指定模式
  Future<void> setMode(ThemeModeType mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode == ThemeModeType.elderly ? 'elderly' : 'normal');
  }

  /// 设置字体缩放级别
  Future<void> setFontScale(FontScaleLevel level) async {
    _fontScale = level;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_scale', level.name);
  }

  /// 设置高对比度
  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', value);
  }

  /// 设置语音播报
  Future<void> setEnableVoice(bool value) async {
    _enableVoice = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_voice', value);
  }

  /// 构建 Flutter ThemeData
  ThemeData toThemeData() {
    final isElderly = isElderlyMode;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        surface: cardColor,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: primary,
        onSurface: textPrimary,
      ),

      // 文字主题
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeH1,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.33,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeH2,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeH3,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.44,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBodySmall,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.57,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeCaption,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.67,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeButton,
          fontWeight: isElderly ? FontWeight.bold : FontWeight.w500,
          color: Colors.white,
          height: 1.5,
        ),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: TextStyle(
            fontSize: fontSizeButton,
            fontWeight: isElderly ? FontWeight.bold : FontWeight.w500,
          ),
          elevation: isElderly ? 4 : 2,
          shadowColor: shadowPrimary.isNotEmpty ? shadowPrimary[0].color : null,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: Size(double.infinity, isElderly ? 52 : 40),
          side: BorderSide(
            color: primary,
            width: isElderly ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: TextStyle(
            fontSize: fontSizeButton,
            fontWeight: isElderly ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: isElderly ? 16 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(
            color: dividerColor,
            width: isElderly ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(
            color: dividerColor,
            width: isElderly ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(
            color: primary,
            width: isElderly ? 2 : 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppThemeTokens.danger),
        ),
        hintStyle: TextStyle(
          fontSize: fontSizeBody,
          color: textDisabled,
        ),
      ),

      // 卡片主题
      cardTheme: CardTheme(
        color: cardColor,
        elevation: isElderly ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: cardMargin,
          vertical: 8,
        ),
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primary,
        unselectedItemColor: AppThemeTokens.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeTab,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeTab,
        ),
      ),

      // AppBar主题
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeH3,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(
          color: textPrimary,
          size: iconStandard,
        ),
      ),

      // 分割线
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 0,
      ),

      // 浮动按钮
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),

      // 对话框
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: TextStyle(
          fontSize: isElderly ? 26 : 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: isElderly ? 20 : 14,
          color: textSecondary,
        ),
      ),

      // 进度指示器
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryLight,
      ),

      // 复选框
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),

      // 开关
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withOpacity(0.5);
          return null;
        }),
      ),
    );
  }
}
