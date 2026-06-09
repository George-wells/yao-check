import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/local_storage_service.dart';

/// 启动页
/// 检查登录状态和引导页状态，自动跳转
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final storage = LocalStorageService.instance;
    final onboardingDone = storage.getBool('onboarding_done') ?? false;

    if (!onboardingDone) {
      Navigator.pushReplacementNamed(context, AppConstants.routeOnboarding);
    } else if (!auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
    } else {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: theme.shadowMedium,
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 56,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '智能用药',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '科学用药 · 健康生活',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
