import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../models/medicine.dart';
import '../../models/interaction.dart';

/// 药物相互作用检查页（增强版）
/// 从API加载药品列表，实时检查相互作用
class InteractionCheckPage extends StatefulWidget {
  const InteractionCheckPage({super.key});

  @override
  State<InteractionCheckPage> createState() => _InteractionCheckPageState();
}

class _InteractionCheckPageState extends State<InteractionCheckPage> {
  List<Map<String, dynamic>> _medicines = [];
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final provider = context.read<MedicineProvider>();
    final medicines = await provider.getUserMedicines();
    if (mounted && medicines.isNotEmpty) {
      setState(() {
        _medicines = medicines.map((m) => {
          'id': m.id,
          'name': m.name,
          'selected': false,
        }).toList();
      });
    }
  }

  Future<void> _checkInteractions() async {
    final selectedIds = _medicines
        .where((m) => m['selected'] == true)
        .map((m) => m['id'] as String)
        .toList();

    if (selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择2种药品')),
      );
      return;
    }

    final provider = context.read<MedicineProvider>();
    await provider.checkInteractions(selectedIds);
    setState(() => _showResult = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final medicine = context.watch<MedicineProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('药物相互作用检查'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isElderly ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 药品选择
            Text(
              '选择需要检查的药品',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceSM),
            Text(
              '选择2种或以上药品进行相互作用分析',
              style: TextStyle(
                fontSize: theme.fontSizeCaption,
                color: theme.textSecondary,
              ),
            ),
            SizedBox(height: theme.spaceMD),

            if (_medicines.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(theme.space3XL),
                  child: Text(
                    '暂无药品数据，请先在搜索中添加药品',
                    style: TextStyle(fontSize: theme.fontSizeBody, color: theme.textSecondary),
                  ),
                ),
              )
            else
              ...List.generate(_medicines.length, (index) {
                final med = _medicines[index];
                return CheckboxListTile(
                  title: Text(
                    med['name'],
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      color: theme.textPrimary,
                    ),
                  ),
                  value: med['selected'],
                  onChanged: (v) {
                    setState(() {
                      _medicines[index]['selected'] = v;
                      _showResult = false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: theme.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: !isElderly,
                );
              }),

            SizedBox(height: theme.spaceLG),

            // 检查按钮
            SizedBox(
              width: double.infinity,
              height: theme.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: medicine.isLoading ? null : _checkInteractions,
                icon: medicine.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  medicine.isLoading ? '检查中...' : '开始检查',
                  style: TextStyle(fontSize: theme.fontSizeButton),
                ),
              ),
            ),
            SizedBox(height: theme.spaceLG),

            // 错误提示
            if (medicine.error != null)
              Container(
                padding: EdgeInsets.all(theme.cardPadding),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(theme.cardRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFFFF4D4F), size: 20),
                    SizedBox(width: theme.spaceSM),
                    Expanded(
                      child: Text(
                        medicine.error!,
                        style: TextStyle(
                          fontSize: theme.fontSizeBodySmall,
                          color: const Color(0xFFFF4D4F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 检查结果
            if (_showResult && medicine.interactionResult != null)
              _buildResultsText(theme, medicine.interactionResult!, isElderly),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsText(ThemeProvider theme, String result, bool isElderly) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI 分析结果',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceMD),
            Text(
              result,
              style: TextStyle(
                fontSize: isElderly ? 16 : 14,
                color: theme.textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeProvider theme, InteractionResult result, bool isElderly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: theme.dividerColor),
        SizedBox(height: theme.spaceMD),

        // 汇总
        Row(
          children: [
            Text(
              '检查结果',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '共${result.summary.total}项',
              style: TextStyle(
                fontSize: theme.fontSizeCaption,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spaceMD),

        // 风险汇总
        Row(
          children: [
            _buildSummaryBadge(theme, '高风险', result.summary.high, const Color(0xFFFF4D4F)),
            SizedBox(width: theme.spaceSM),
            _buildSummaryBadge(theme, '中风险', result.summary.medium, const Color(0xFFFAAD14)),
            SizedBox(width: theme.spaceSM),
            _buildSummaryBadge(theme, '低风险', result.summary.low, const Color(0xFF52C41A)),
          ],
        ),
        SizedBox(height: theme.spaceLG),

        // 相互作用列表
        ...result.interactions.map((item) {
          Color severityColor;
          switch (item.severity) {
            case 'high':
              severityColor = const Color(0xFFFF4D4F);
              break;
            case 'medium':
              severityColor = const Color(0xFFFAAD14);
              break;
            default:
              severityColor = const Color(0xFF52C41A);
          }

          return Container(
            margin: EdgeInsets.only(bottom: theme.spaceMD),
            padding: EdgeInsets.all(theme.cardPadding),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(theme.cardRadius),
              border: Border.all(color: severityColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item.severity == 'high' ? Icons.error :
                      item.severity == 'medium' ? Icons.warning_amber_rounded :
                      Icons.check_circle,
                      color: severityColor,
                      size: 24,
                    ),
                    SizedBox(width: theme.spaceSM),
                    Expanded(
                      child: Text(
                        '${item.medicineAName} ↔ ${item.medicineBName}',
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
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.severityLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: theme.spaceSM),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: theme.fontSizeBodySmall,
                    color: theme.textPrimary,
                    height: 1.5,
                  ),
                ),
                if (item.mechanism != null) ...[
                  SizedBox(height: theme.spaceSM),
                  Text(
                    '作用机制：${item.mechanism}',
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
                if (item.clinicalManagement != null) ...[
                  SizedBox(height: theme.spaceXS),
                  Text(
                    '管理建议：${item.clinicalManagement}',
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
                if (item.symptoms != null) ...[
                  SizedBox(height: theme.spaceXS),
                  Text(
                    '可能症状：${item.symptoms}',
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: const Color(0xFFFF4D4F),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryBadge(ThemeProvider theme, String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.spaceMD, vertical: theme.spaceSM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(theme.radiusMD),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: theme.fontSizeH3,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: theme.spaceXS),
          Text(
            label,
            style: TextStyle(
              fontSize: theme.fontSizeCaption,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
