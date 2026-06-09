import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/medicine_provider.dart';
import '../../models/medicine.dart';

/// 药品详情页（说明书）- 增强版
/// 使用MedicineProvider获取真实数据，支持说明书折叠展开
class MedicineDetailPage extends StatefulWidget {
  final String? medicineName;
  const MedicineDetailPage({super.key, this.medicineName});

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  final Set<String> _expandedSections = {
    '适应症', '用法用量', '禁忌', '不良反应', '注意事项', '药物相互作用'
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final medicine = context.read<MedicineProvider>();
    if (medicine.selectedMedicine == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('keyword')) {
        medicine.getMedicineByName(args['keyword']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final medicine = context.watch<MedicineProvider>();
    final med = medicine.selectedMedicine;
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(med?.name ?? '药品详情'),
        actions: [
          if (isElderly)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {},
              tooltip: '语音播报',
            ),
        ],
      ),
      body: medicine.isLoading
          ? const Center(child: CircularProgressIndicator())
          : med == null
              ? _buildErrorState(theme)
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isElderly ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 药品基本信息卡片
                      _buildInfoCard(theme, med, isElderly),
                      SizedBox(height: theme.spaceLG),

                      // 快速操作
                      _buildQuickActions(theme, med, isElderly),
                      SizedBox(height: theme.spaceLG),

                      // 说明书内容（可折叠）
                      if (med.indications != null)
                        _buildSection(theme, '适应症', med.indications!, isElderly),
                      if (med.usageDosage != null)
                        _buildSection(theme, '用法用量', med.usageDosage!, isElderly),
                      if (med.contraindications != null)
                        _buildSection(theme, '禁忌', med.contraindications!, isElderly),
                      if (med.sideEffects != null)
                        _buildSection(theme, '不良反应', med.sideEffects!, isElderly),
                      if (med.precautions != null)
                        _buildSection(theme, '注意事项', med.precautions!, isElderly),
                      if (med.drugInteractions != null)
                        _buildSection(theme, '药物相互作用', med.drugInteractions!, isElderly),

                      SizedBox(height: theme.spaceLG),

                      // 通俗解释
                      if (med.plainLanguageExplanation != null)
                        _buildPlainExplanation(theme, med.plainLanguageExplanation!, isElderly),

                      SizedBox(height: theme.space4XL),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.textDisabled),
          const SizedBox(height: 16),
          Text(
            '未找到药品信息',
            style: TextStyle(fontSize: theme.fontSizeH3, color: theme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeProvider theme, Medicine med, bool isElderly) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isElderly ? 60 : 48,
                  height: isElderly ? 60 : 48,
                  decoration: BoxDecoration(
                    color: theme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication, color: theme.primary, size: isElderly ? 36 : 28),
                ),
                SizedBox(width: theme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: TextStyle(
                          fontSize: theme.fontSizeH2,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      if (med.genericName != null)
                        Text(
                          '通用名：${med.genericName}',
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
            SizedBox(height: theme.spaceMD),
            if (med.specification != null)
              _buildInfoRow(theme, '规格', med.specification!),
            if (med.manufacturer != null)
              _buildInfoRow(theme, '厂家', med.manufacturer!),
            if (med.category != null)
              _buildInfoRow(theme, '分类', med.category!),
            if (med.dosageForm != null)
              _buildInfoRow(theme, '剂型', med.dosageForm!),
          ],
        ),
      ),
    );
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

  Widget _buildQuickActions(ThemeProvider theme, Medicine med, bool isElderly) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: theme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeReminderAdd),
              icon: const Icon(Icons.add_alarm, size: 20),
              label: Text(
                '添加提醒',
                style: TextStyle(fontSize: theme.fontSizeButton),
              ),
            ),
          ),
        ),
        SizedBox(width: theme.spaceMD),
        Expanded(
          child: SizedBox(
            height: theme.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeInteractions),
              icon: const Icon(Icons.swap_horiz, size: 20),
              label: Text(
                '相互作用检查',
                style: TextStyle(fontSize: theme.fontSizeButton),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(ThemeProvider theme, String title, String content, bool isElderly) {
    final isExpanded = _expandedSections.contains(title);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedSections.remove(title);
              } else {
                _expandedSections.add(title);
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spaceMD),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: theme.fontSizeH3,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                if (isElderly)
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.help_outline, size: 18, color: theme.primary),
                    ),
                  ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: EdgeInsets.only(bottom: theme.spaceMD),
            child: Text(
              content,
              style: TextStyle(
                fontSize: theme.fontSizeBody,
                color: theme.textPrimary,
                height: 1.6,
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        Divider(color: theme.dividerColor, height: 1),
      ],
    );
  }

  Widget _buildPlainExplanation(ThemeProvider theme, String content, bool isElderly) {
    return Container(
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: theme.primaryLight,
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.primary, size: theme.iconStandard),
              SizedBox(width: theme.spaceSM),
              Text(
                '通俗解释',
                style: TextStyle(
                  fontSize: theme.fontSizeH3,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spaceSM),
          Text(
            content,
            style: TextStyle(
              fontSize: theme.fontSizeBody,
              color: theme.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
