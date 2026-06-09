import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_provider.dart';

/// 进度卡片组件
/// 展示今日用药进度，含圆形进度指示器
class ProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final double progress; // 0-100

  const ProgressCard({
    super.key,
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Row(
          children: [
            // 圆形进度
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: total > 0 ? progress / 100.0 : 0,
                      strokeWidth: 4,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 80 ? theme.success : theme.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$completed/$total',
                        style: TextStyle(
                          fontSize: theme.fontSizeNumMedium,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        '项',
                        style: TextStyle(
                          fontSize: theme.fontSizeCaption,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.spaceLG),
            // 文字说明
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日用药进度',
                    style: TextStyle(
                      fontSize: theme.fontSizeH3,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  SizedBox(height: theme.spaceSM),
                  Text(
                    '已完成 $completed 项',
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      color: theme.success,
                    ),
                  ),
                  if (total - completed > 0)
                    Text(
                      '剩余 ${total - completed} 项待服',
                      style: TextStyle(
                        fontSize: theme.fontSizeBodySmall,
                        color: theme.textSecondary,
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
