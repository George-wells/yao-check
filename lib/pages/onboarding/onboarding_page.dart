import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// 引导页
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.medication_outlined,
      title: '用药提醒',
      description: '设置个性化用药提醒，按时服药不遗漏',
      color: const Color(0xFF1890FF),
    ),
    _OnboardingItem(
      icon: Icons.search_outlined,
      title: '药物查询',
      description: '查询药物信息，了解用法用量和注意事项',
      color: const Color(0xFF52C41A),
    ),
    _OnboardingItem(
      icon: Icons.assignment_outlined,
      title: '处方管理',
      description: '拍照识别处方，一键添加用药提醒',
      color: const Color(0xFFFAAD14),
    ),
    _OnboardingItem(
      icon: Icons.security_outlined,
      title: '本地隐私',
      description: '所有数据仅存储在本地，不上传云端',
      color: const Color(0xFF722ED1),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingDoneKey, true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(item.icon, size: 60, color: item.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF595959),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 指示器
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
                        ? _items[_currentPage].color
                        : const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _currentPage == _items.length - 1
                      ? _completeOnboarding
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _items[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _currentPage == _items.length - 1 ? '开始使用' : '下一步',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
