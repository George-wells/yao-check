import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'providers/reminder_provider.dart';
import 'providers/records_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/prescription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('medication_data');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
      ],
      child: const SmartMedicationApp(),
    ),
  );
}

class SmartMedicationApp extends StatelessWidget {
  const SmartMedicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: '智能用药',
      debugShowCheckedModeBanner: false,
      theme: theme.buildLightTheme(),
      darkTheme: theme.buildDarkTheme(),
      themeMode: theme.themeMode,
      initialRoute: AppConstants.routeSplash,
      onGenerateRoute: AppRouter.generateRoute,
      navigatorKey: AppRouter.navigatorKey,
    );
  }
}
