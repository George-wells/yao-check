import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/records_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/guardian_provider.dart';
import 'services/local_storage_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

/// 智能用药App 主入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  await LocalStorageService.instance.init();

  // 初始化API服务
  ApiService.instance;

  // 初始化本地通知服务
  final notifService = NotificationService.instance;
  await notifService.init();
  await notifService.createNotificationChannels();

  runApp(const SmartMedicationApp());
}

class SmartMedicationApp extends StatelessWidget {
  const SmartMedicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 主题状态管理
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadPreferences()),
        // 认证状态管理
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        // 用药提醒状态管理
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        // 药物信息查询状态管理
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        // 用药记录状态管理
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
        // 处方管理状态管理
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        // 家人监护状态管理
        ChangeNotifierProvider(create: (_) => GuardianProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: '智能用药',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppRouter.navigatorKey,
            theme: themeProvider.toThemeData(),
            initialRoute: '/',
            onGenerateRoute: (settings) {
              final routes = AppRouter.buildRoutes();
              final builder = routes[settings.name];
              if (builder != null) {
                return MaterialPageRoute(
                  builder: (context) => builder(context),
                  settings: settings,
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
