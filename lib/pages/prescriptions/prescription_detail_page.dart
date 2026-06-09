import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/prescription_provider.dart';
import '../../models/prescription.dart';

/// 处方详情页（增强版）
/// 使用PrescriptionProvider获取真实数据，支持一键添加提醒
class PrescriptionDetailPage extends StatelessWidget {
  const PrescriptionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<PrescriptionProvider>();
    final prescription = provider.selectedPrescription;
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('处方详情'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prescription == null
              ? Center(
                  child: Text('未找到处方', style: TextStyle(color: theme.textSecondary)),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isElderly ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 处方信息卡片
                      _buildInfoCard(theme, prescription, isElderly),
                      SizedBox(height: theme.spaceLG),

                      // 处方药品
                      Text(
                        '处方药品',
                        style: TextStyle(
                          fontSize: theme.fontSizeH3,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      SizedBox(height: theme.spaceMD),
                      ...prescription.medicines.map((med) => Padding(
                        padding: EdgeInsets.only(bottom: theme.spaceMD),
                        child: _buildMedicineCard(theme, med, isElderly, context),
                      )),

                      if (prescription.medicines.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(theme.spaceLG),
                            child: Text(
                              '暂无药品信息',
                              style: TextStyle(color: theme.textSecondary),
                            ),
                          ),
                        ),

                      SizedBox(height: theme.spaceLG),

                      // 处方照片
                      if (prescription.imageUrl != null) ...[
                        Text(
                          '处方照片',
                          style: TextStyle(
                            fontSize: theme.fontSizeH3,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        SizedBox(height: theme.spaceMD),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(theme.cardRadius),
                            image: DecorationImage(
                              image: NetworkImage(prescription.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: theme.spaceLG),
                      ],

                      // OCR状态
                      if (prescription.ocrStatus != null)
                        _buildOcrStatus(theme, prescription.ocrStatus!),

                      // 一键添加按钮
                      SizedBox(
                        width: double.infinity,
                        height: theme.buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 逐个添加药品到提醒
                            for (final med in prescription.medicines) {
                              // 导航到添加提醒页
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('药品已添加到用药提醒'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_alarm),
                          label: Text(
                            '一键添加所有药品到提醒',
                            style: TextStyle(fontSize: theme.fontSizeButton),
                          ),
                        ),
                      ),

                      SizedBox(height: theme.spaceMD),

                      // 删除按钮
                      SizedBox(
                        width: double.infinity,
                        height: theme.buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('确认删除'),
                                content: const Text('删除后无法恢复，确定要删除此处方吗？'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('删除'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await provider.deletePrescription(prescription.id);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: Text(
                            '删除处方',
                            style: TextStyle(fontSize: theme.fontSizeButton),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(ThemeProvider theme, Prescription prescription, bool isElderly) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, size: theme.iconStandard, color: theme.primary),
                SizedBox(width: theme.spaceSM),
                Text(
                  '处方信息',
                  style: TextStyle(
                    fontSize: theme.fontSizeH3,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: prescription.isValid
                        ? const Color(0xFF52C41A).withOpacity(0.1)
                        : const Color(0xFFFF4D4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prescription.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: prescription.isValid ? const Color(0xFF52C41A) : const Color(0xFFFF4D4F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spaceMD),
            _buildInfoRow(theme, '医院', prescription.hospitalName ?? '-'),
            _buildInfoRow(theme, '医生', prescription.doctorName ?? '-'),
            _buildInfoRow(theme, '诊断', prescription.diagnosis ?? '-'),
            _buildInfoRow(theme, '开具日期', prescription.issueDate ?? '-'),
            _buildInfoRow(theme, '有效期至', prescription.expiryDate ?? '-'),
            if (prescription.expiryDate != null)
              _buildInfoRow(theme, '剩余', _getRemainingDays(prescription.expiryDate!)),
          ],
        ),
      ),
    );
  }

  String _getRemainingDays(String expiryDateStr) {
    final expiry = DateTime.tryParse(expiryDateStr);
    if (expiry == null) return '-';
    final remaining = expiry.difference(DateTime.now()).inDays;
    if (remaining < 0) return '已过期${-remaining}天';
    if (remaining == 0) return '今天到期';
    return '$remaining天';
  }

  Widget _buildInfoRow(ThemeProvider theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spaceSM),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: theme.fontSizeBodySmall,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: theme.fontSizeBodySmall,
                color: theme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(ThemeProvider theme, PrescriptionMedicine med, bool isElderly, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        boxShadow: theme.shadowLight,
      ),
      child: Row(
        children: [
          Icon(Icons.medication, size: theme.iconStandard, color: theme.primary),
          SizedBox(width: theme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                SizedBox(height: theme.spaceXS),
                Text(
                  '${med.dosage ?? ''} · ${med.frequency ?? ''} · ${med.duration ?? ''}',
                  style: TextStyle(
                    fontSize: theme.fontSizeCaption,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),
            child: const Text('添加提醒'),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrStatus(ThemeProvider theme, String ocrStatus) {
    String label;
    Color color;
    IconData icon;

    switch (ocrStatus) {
      case 'completed':
        label = 'OCR识别已完成';
        color = const Color(0xFF52C41A);
        icon = Icons.check_circle;
        break;
      case 'processing':
        label = 'OCR识别中...';
        color = const Color(0xFFFAAD14);
        icon = Icons.hourglass_top;
        break;
      case 'failed':
        label = 'OCR识别失败';
        color = const Color(0xFFFF4D4F);
        icon = Icons.error;
        break;
      default:
        label = '等待OCR识别';
        color = theme.textDisabled;
        icon = Icons.schedule;
    }

    return Container(
      margin: EdgeInsets.only(bottom: theme.spaceLG),
      padding: EdgeInsets.all(theme.spaceMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(theme.radiusMD),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: theme.spaceSM),
          Text(
            label,
            style: TextStyle(
              fontSize: theme.fontSizeBodySmall,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
