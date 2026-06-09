import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../pages/splash/splash_page.dart';
import '../../pages/onboarding/onboarding_page.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/reminders/reminder_add_page.dart';
import '../../pages/reminders/reminder_list_page.dart';
import '../../pages/checkin/checkin_page.dart';
import '../../pages/records/records_page.dart';
import '../../pages/medicines/medicine_search_page.dart';
import '../../pages/medicines/medicine_detail_page.dart';
import '../../pages/medicines/interaction_check_page.dart';
import '../../pages/prescriptions/prescription_list_page.dart';
import '../../pages/prescriptions/prescription_ocr_page.dart';
import '../../pages/prescriptions/prescription_detail_page.dart';
import '../../pages/family/family_list_page.dart';
import '../../pages/family/family_detail_page.dart';
import '../../pages/settings/settings_page.dart';

/// 应用路由配置
/// 使用GoRouter实现命名路由导航
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 构建路由表
  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      AppConstants.routeSplash: (context) => const SplashPage(),
      AppConstants.routeOnboarding: (context) => const OnboardingPage(),
      AppConstants.routeLogin: (context) => const LoginPage(),
      AppConstants.routeHome: (context) => const HomePage(),
      AppConstants.routeReminders: (context) => const ReminderListPage(),
      AppConstants.routeReminderAdd: (context) => const ReminderAddPage(),
      AppConstants.routeCheckin: (context) => const CheckinPage(),
      AppConstants.routeRecords: (context) => const RecordsPage(),
      AppConstants.routeMedicines: (context) => const MedicineSearchPage(),
      AppConstants.routeMedicineDetail: (context) => const MedicineDetailPage(),
      AppConstants.routeInteractions: (context) => const InteractionCheckPage(),
      AppConstants.routePrescriptions: (context) => const PrescriptionListPage(),
      AppConstants.routePrescriptionOcr: (context) => const PrescriptionOcrPage(),
      AppConstants.routePrescriptionDetail: (context) => const PrescriptionDetailPage(),
      AppConstants.routeFamily: (context) => const FamilyListPage(),
      AppConstants.routeFamilyDetail: (context) => const FamilyDetailPage(),
      AppConstants.routeSettings: (context) => const SettingsPage(),
    };
  }

  /// 获取初始路由
  static String getInitialRoute(AuthProvider auth, bool onboardingDone) {
    if (!onboardingDone) return AppConstants.routeOnboarding;
    if (!auth.isLoggedIn) return AppConstants.routeLogin;
    return AppConstants.routeHome;
  }

  /// 页面切换动画
  static Route createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      transitionDuration: AppConstants.pageTransitionDuration,
    );
  }

  /// 导航到页面
  static Future<T?> push<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// 替换当前页面
  static Future<T?> pushReplacement<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  /// 返回上一页
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  /// 跳转到首页（清除路由栈）
  static void goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, AppConstants.routeHome, (route) => false);
  }

  /// 跳转到登录页（清除路由栈）
  static void goToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, AppConstants.routeLogin, (route) => false);
  }
}
