import 'package:flutter/material.dart';
import '../core/theme/theme_provider.dart';

/// 提醒卡片组件
/// 展示单个用药提醒项，支持已服/待服/漏服三种状态
/// 待服状态支持：立即打卡、稍后提醒
class ReminderCard extends StatelessWidget {
  final String time;
  final String medicineName;
  final String dosage;
  final String status; // pending, taken, missed
  final bool isElderly;
  final VoidCallback? onCheckin;
  final VoidCallback? onSnooze;

  const ReminderCard({
    super.key,
    required this.time,
    required this.medicineName,
    required this.dosage,
    required this.status,
    this.isElderly = false,
    this.onCheckin,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'taken':
        statusColor = const Color(0xFF52C41A);
        statusIcon = Icons.check_circle;
        statusLabel = '已服';
        break;
      case 'missed':
        statusColor = const Color(0xFFFF4D4F);
        statusIcon = Icons.warning;
        statusLabel = '漏服';
        break;
      default:
        statusColor = const Color(0xFFFA8C16);
        statusIcon = Icons.schedule;
        statusLabel = '待服';
    }

    if (isElderly && status == 'pending') {
      return _buildElderlyCard(statusColor, statusIcon);
    }

    return _buildDefaultCard(statusColor, statusIcon, statusLabel);
  }

  Widget _buildElderlyCard(Color statusColor, IconData statusIcon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF262626),
                  ),
                ),
                const Spacer(),
                Text(
                  dosage,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF595959),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              medicineName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onCheckin,
                icon: const Icon(Icons.check_circle, size: 24),
                label: const Text(
                  '立即打卡',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1890FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (onSnooze != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onSnooze,
                    icon: const Icon(Icons.alarm, size: 20),
                    label: const Text(
                      '稍后提醒（15分钟）',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCard(Color statusColor, IconData statusIcon, String statusLabel) {
    final List<Widget> trailingWidgets = [];
    if (status == 'pending' && !isElderly) {
      trailingWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSnooze != null)
              IconButton(
                onPressed: onSnooze,
                icon: const Icon(Icons.alarm, size: 20),
                tooltip: '稍后提醒',
                color: const Color(0xFF595959),
              ),
            const SizedBox(width: 4),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: onCheckin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('立即打卡', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      );
    } else {
      trailingWidgets.add(
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isElderly ? 12 : 8,
            vertical: isElderly ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: isElderly ? 18 : 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: isElderly ? 16 : 8),
      padding: EdgeInsets.all(isElderly ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isElderly ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: isElderly ? 32 : 24),
          SizedBox(width: isElderly ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: isElderly ? 22 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262626),
                      ),
                    ),
                    SizedBox(width: isElderly ? 12 : 8),
                    Text(
                      medicineName,
                      style: TextStyle(
                        fontSize: isElderly ? 20 : 14,
                        color: const Color(0xFF262626),
                      ),
                    ),
                  ],
                ),
                Text(
                  dosage,
                  style: TextStyle(
                    fontSize: isElderly ? 18 : 12,
                    color: const Color(0xFF595959),
                  ),
                ),
              ],
            ),
          ),
          ...trailingWidgets,
        ],
      ),
    );
  }
}
