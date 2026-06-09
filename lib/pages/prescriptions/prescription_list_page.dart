import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/prescription_provider.dart';
import '../../models/prescription.dart';
import '../../widgets/empty_state.dart';

/// 处方列表页（增强版）
/// 支持：处方列表、OCR入口、到期提醒、续方提醒
class PrescriptionListPage extends StatefulWidget {
  const PrescriptionListPage({super.key});

  @override
  State<PrescriptionListPage> createState() => _PrescriptionListPageState();
}

class _PrescriptionListPageState extends State<PrescriptionListPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrescriptionProvider>().loadPrescriptions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<PrescriptionProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('处方管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: theme.iconStandard),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routePrescriptionOcr),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => provider.loadPrescriptions(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isElderly ? 24 : 16),
          child: Column(
            children: [
              // OCR识别入口
              _buildOcrEntry(theme, isElderly),
              SizedBox(height: theme.spaceLG),

              // 续方提醒（如有即将过期处方）
              if (provider.expiringPrescriptions.isNotEmpty)
                _buildRefillReminder(theme, provider, isElderly),
              if (provider.expiringPrescriptions.isNotEmpty)
                SizedBox(height: theme.spaceLG),

              // 处方列表
              if (provider.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              else if (provider.prescriptions.isEmpty)
                EmptyState(
                  icon: Icons.description_outlined,
                  title: '暂无处方',
                  subtitle: '点击上方"拍照识别处方"添加您的第一张处方',
                  actionLabel: '拍照识别',
                  onAction: () => Navigator.pushNamed(context, AppConstants.routePrescriptionOcr),
                )
              else
                ...provider.prescriptions.map((prescription) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: theme.spaceMD),
                    child: _buildPrescriptionCard(theme, prescription, isElderly),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOcrEntry(ThemeProvider theme, bool isElderly) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppConstants.routePrescriptionOcr),
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        decoration: BoxDecoration(
          color: theme.primaryLight,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          border: Border.all(
            color: theme.primary.withOpacity(0.3),
            width: isElderly ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isElderly ? 56 : 48,
              height: isElderly ? 56 : 48,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: isElderly ? 32 : 24),
            ),
            SizedBox(width: theme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '拍照识别处方',
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                  Text(
                    '拍照自动识别药品信息，快速录入',
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.primary, size: theme.iconStandard),
          ],
        ),
      ),
    );
  }

  Widget _buildRefillReminder(ThemeProvider theme, PrescriptionProvider provider, bool isElderly) {
    final expiring = provider.expiringPrescriptions;
    return Container(
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: const Color(0xFFFAAD14).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFAAD14), size: 24),
              SizedBox(width: theme.spaceSM),
              Text(
                '续方提醒',
                style: TextStyle(
                  fontSize: theme.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFAAD14),
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spaceSM),
          ...expiring.map((p) => Padding(
            padding: EdgeInsets.only(bottom: theme.spaceSM),
            child: Text(
              '${p.hospitalName ?? ''}处方将于${p.expiryDate ?? ''}到期',
              style: TextStyle(
                fontSize: theme.fontSizeBodySmall,
                color: theme.textPrimary,
              ),
            ),
          )),
          SizedBox(height: theme.spaceMD),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: isElderly ? 44 : 36,
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('查看附近药店', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              SizedBox(width: theme.spaceSM),
              Expanded(
                child: SizedBox(
                  height: isElderly ? 44 : 36,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('在线问诊', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(ThemeProvider theme, Prescription prescription, bool isElderly) {
    final isValid = prescription.isValid;
    final medicinesStr = prescription.medicines.isNotEmpty
        ? '${prescription.medicines.length}种药品'
        : '暂无药品';

    return GestureDetector(
      onTap: () {
        context.read<PrescriptionProvider>().getPrescriptionDetail(prescription.id);
        Navigator.pushNamed(context, AppConstants.routePrescriptionDetail);
      },
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          boxShadow: theme.shadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, size: theme.iconStandard, color: theme.primary),
                SizedBox(width: theme.spaceSM),
                Expanded(
                  child: Text(
                    prescription.issueDate ?? '未知日期',
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isValid
                        ? const Color(0xFF52C41A).withOpacity(0.1)
                        : const Color(0xFFFF4D4F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prescription.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isValid ? const Color(0xFF52C41A) : const Color(0xFFFF4D4F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spaceSM),
            Text(
              '${prescription.hospitalName ?? ''} · ${prescription.doctorName ?? ''}',
              style: TextStyle(
                fontSize: theme.fontSizeCaption,
                color: theme.textSecondary,
              ),
            ),
            SizedBox(height: theme.spaceXS),
            Text(
              '$medicinesStr · 有效期至${prescription.expiryDate ?? '未知'}',
              style: TextStyle(
                fontSize: theme.fontSizeCaption,
                color: theme.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
