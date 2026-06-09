import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';

/// 适老化大按钮组件
/// 适老化模式下使用的全宽大按钮，带图标和文字
class ElderlyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ElderlyButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          boxShadow: theme.shadowLight,
          border: Border.all(
            color: theme.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: theme.fontSizeButton,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
