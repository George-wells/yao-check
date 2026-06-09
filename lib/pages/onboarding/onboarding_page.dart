import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/local_storage_service.dart';

/// 引导页
/// 首次启动时展示3页引导内容
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.alarm_on_outlined,
      title: '智能用药管理',
      subtitle: '设置个性化用药提醒\n不再漏服、错服任何一次药',
      color: const Color(0xFF1890FF),
    ),
    _OnboardingItem(
      icon: Icons.family_restroom_outlined,
      title: '家人远程监护',
      subtitle: '实时了解家人用药情况\n漏服自动通知，安心放心',
      color: const Color(0xFFFF6B35),
    ),
    _OnboardingItem(
      icon: Icons.medication_outlined,
      title: '药品信息查询',
      subtitle: '扫码查药、相互作用检查\n安全用药，科学管理',
      color: const Color(0xFF52C41A),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final storage = LocalStorageService.instance;
    await storage.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 跳过按钮
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onGetStarted,
                child: Text(
                  '跳过',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ),

            // 引导内容
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 图标
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            item.icon,
                            size: 64,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF262626),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF595959),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 指示器 + 按钮
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // 圆点指示器
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.primary
                              : theme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 按钮
                  SizedBox(
                    width: double.infinity,
                    height: theme.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _items.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _onGetStarted();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.buttonRadius),
                        ),
                      ),
                      child: Text(
                        _currentPage < _items.length - 1 ? '下一步' : '立即体验',
                        style: TextStyle(
                          fontSize: theme.fontSizeButton,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _OnboardingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
