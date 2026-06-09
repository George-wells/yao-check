import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';

/// 空态组件
/// 当列表无数据时展示引导提示
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.space3XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 40,
                color: theme.primary,
              ),
            ),
            SizedBox(height: theme.spaceLG),
            Text(
              title,
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceSM),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: theme.fontSizeBodySmall,
                color: theme.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: theme.spaceXL),
              SizedBox(
                height: theme.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(Icons.add, size: theme.iconStandard),
                  label: Text(
                    actionLabel!,
                    style: TextStyle(fontSize: theme.fontSizeButton),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
