import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../../pages/splash/splash_page.dart';
import '../../pages/onboarding/onboarding_page.dart';
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
import '../../pages/settings/settings_page.dart';

/// 应用路由配置
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeSplash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case AppConstants.routeOnboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case AppConstants.routeHome:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppConstants.routeReminders:
        return MaterialPageRoute(builder: (_) => const ReminderListPage());
      case AppConstants.routeReminderAdd:
        return MaterialPageRoute(builder: (_) => const ReminderAddPage());
      case AppConstants.routeCheckin:
        return MaterialPageRoute(builder: (_) => const CheckinPage());
      case AppConstants.routeRecords:
        return MaterialPageRoute(builder: (_) => const RecordsPage());
      case AppConstants.routeMedicines:
        return MaterialPageRoute(builder: (_) => const MedicineSearchPage());
      case AppConstants.routeMedicineDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MedicineDetailPage(medicineName: args?['name'] as String? ?? ''),
        );
      case AppConstants.routeInteractions:
        return MaterialPageRoute(builder: (_) => const InteractionCheckPage());
      case AppConstants.routePrescriptions:
        return MaterialPageRoute(builder: (_) => const PrescriptionListPage());
      case AppConstants.routePrescriptionOcr:
        return MaterialPageRoute(builder: (_) => const PrescriptionOcrPage());
      case AppConstants.routePrescriptionDetail:
        return MaterialPageRoute(builder: (_) => const PrescriptionDetailPage());
      case AppConstants.routeSettings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, AppConstants.routeHome, (route) => false);
  }
}
