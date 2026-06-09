import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/string_utils.dart';
import '../../providers/reminder_provider.dart';

/// 添加用药提醒页
/// 三步设置：选择药品 → 设置服药时间 → 其他设置
class ReminderAddPage extends StatefulWidget {
  const ReminderAddPage({super.key});

  @override
  State<ReminderAddPage> createState() => _ReminderAddPageState();
}

class _ReminderAddPageState extends State<ReminderAddPage> {
  final _searchController = TextEditingController();
  final _dosageController = TextEditingController(text: '1');
  final _stockController = TextEditingController();

  int _currentStep = 0;
  String _selectedMedicine = '';
  String _dosageUnit = '片';
  String _frequencyType = 'daily';
  int _frequencyTimes = 1;
  List<String> _selectedTimes = ['08:00'];
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  final List<String> _commonMedicines = [
    '硝苯地平控释片',
    '二甲双胍片',
    '阿司匹林肠溶片',
    '阿托伐他汀钙片',
    '氯沙坦钾片',
  ];

  final List<String> _dosageUnits = ['片', '粒', 'ml', 'mg', 'g', '袋', '支'];

  @override
  void dispose() {
    _searchController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedMedicine.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择药品')),
      );
      return;
    }

    final reminder = context.read<ReminderProvider>();

    // 检查重复用药
    final duplicateWarning = reminder.checkDuplicateMedicine(_selectedMedicine);
    if (duplicateWarning != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFAAD14)),
              SizedBox(width: 8),
              Text('重复用药提醒'),
            ],
          ),
          content: Text(duplicateWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('仍要添加'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final data = {
      'medicineName': _selectedMedicine,
      'dosageValue': double.tryParse(_dosageController.text) ?? 1,
      'dosageUnit': _dosageUnit,
      'dosageDescription': '每次${_dosageController.text}$_dosageUnit',
      'frequencyType': _frequencyType,
      'frequencyTimesPerDay': _frequencyTimes,
      'schedule': _selectedTimes.map((time) => {
        'time': time,
        'daysOfWeek': _selectedDays,
      }).toList(),
      'startDate': DateTime.now().toIso8601String().split('T')[0],
    };

    final success = await reminder.createPlan(data, force: true);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('用药提醒已创建'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('添加用药提醒'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isElderly ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 步骤指示器
            _buildStepIndicator(theme),

            SizedBox(height: isElderly ? 24 : 20),

            // 步骤内容
            if (_currentStep == 0) _buildStep1(theme),
            if (_currentStep == 1) _buildStep2(theme),
            if (_currentStep == 2) _buildStep3(theme),

            SizedBox(height: isElderly ? 24 : 20),

            // 导航按钮
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: SizedBox(
                      height: theme.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: Text('上一步', style: TextStyle(fontSize: theme.fontSizeButton)),
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: theme.spaceMD),
                Expanded(
                  child: SizedBox(
                    height: theme.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _currentStep < 2
                          ? () => setState(() => _currentStep++)
                          : _save,
                      child: Text(
                        _currentStep < 2 ? '下一步' : '保存提醒计划',
                        style: TextStyle(fontSize: theme.fontSizeButton),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeProvider theme) {
    final steps = ['选择药品', '设置时间', '其他设置'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isDone = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              // 步骤圆点
              Container(
                width: theme.isElderlyMode ? 36 : 28,
                height: theme.isElderlyMode ? 36 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive || isDone ? theme.primary : const Color(0xFFE8E8E8),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF999999),
                            fontWeight: FontWeight.bold,
                            fontSize: theme.isElderlyMode ? 18 : 14,
                          ),
                        ),
                ),
              ),
              SizedBox(width: theme.spaceSM),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: theme.isElderlyMode ? 18 : 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? theme.primary : theme.textSecondary,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.symmetric(horizontal: theme.spaceSM),
                    color: isDone ? theme.primary : const Color(0xFFE8E8E8),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep1(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索框
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索药品名称...',
            prefixIcon: Icon(Icons.search, color: theme.primary),
            suffixIcon: IconButton(
              icon: Icon(Icons.qr_code_scanner, color: theme.primary),
              onPressed: () {},
            ),
          ),
        ),
        SizedBox(height: theme.spaceLG),

        // 常用药品
        Text(
          '常用药品',
          style: TextStyle(
            fontSize: theme.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: theme.spaceSM),
        Wrap(
          spacing: theme.spaceSM,
          runSpacing: theme.spaceSM,
          children: _commonMedicines.map((name) {
            final selected = _selectedMedicine == name;
            return GestureDetector(
              onTap: () => setState(() => _selectedMedicine = name),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spaceLG,
                  vertical: theme.spaceSM,
                ),
                decoration: BoxDecoration(
                  color: selected ? theme.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(theme.radiusLG),
                  border: Border.all(
                    color: selected ? theme.primary : const Color(0xFFE8E8E8),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: theme.fontSizeBodySmall,
                    color: selected ? theme.primary : theme.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: theme.spaceLG),

        // 已选药品
        if (_selectedMedicine.isNotEmpty) ...[
          Text(
            '已选药品',
            style: TextStyle(
              fontSize: theme.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          SizedBox(height: theme.spaceSM),
          Card(
            child: Padding(
              padding: EdgeInsets.all(theme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMedicine,
                    style: TextStyle(
                      fontSize: theme.fontSizeH3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: theme.spaceMD),
                  Row(
                    children: [
                      Text('剂型：', style: TextStyle(fontSize: theme.fontSizeBodySmall)),
                      DropdownButton<String>(
                        value: _dosageUnit,
                        items: _dosageUnits.map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u, style: TextStyle(fontSize: theme.fontSizeBody)),
                        )).toList(),
                        onChanged: (v) => setState(() => _dosageUnit = v ?? '片'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _dosageController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      Text(' $_dosageUnit/次', style: TextStyle(fontSize: theme.fontSizeBody)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 服药频率
        Text(
          '服药频率',
          style: TextStyle(
            fontSize: theme.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: theme.spaceSM),
        Wrap(
          spacing: theme.spaceSM,
          runSpacing: theme.spaceSM,
          children: [
            _FrequencyChip(
              label: '每日1次',
              selected: _frequencyType == 'daily' && _frequencyTimes == 1,
              onTap: () => setState(() {
                _frequencyType = 'daily';
                _frequencyTimes = 1;
              }),
              theme: theme,
            ),
            _FrequencyChip(
              label: '每日2次',
              selected: _frequencyType == 'daily' && _frequencyTimes == 2,
              onTap: () => setState(() {
                _frequencyType = 'daily';
                _frequencyTimes = 2;
                if (_selectedTimes.length < 2) {
                  _selectedTimes = ['08:00', '20:00'];
                }
              }),
              theme: theme,
            ),
            _FrequencyChip(
              label: '每日3次',
              selected: _frequencyType == 'daily' && _frequencyTimes == 3,
              onTap: () => setState(() {
                _frequencyType = 'daily';
                _frequencyTimes = 3;
                if (_selectedTimes.length < 3) {
                  _selectedTimes = ['08:00', '12:30', '18:00'];
                }
              }),
              theme: theme,
            ),
            _FrequencyChip(
              label: '每8小时',
              selected: _frequencyType == 'every_n_hours',
              onTap: () => setState(() {
                _frequencyType = 'every_n_hours';
                _selectedTimes = ['08:00', '16:00', '00:00'];
              }),
              theme: theme,
            ),
          ],
        ),
        SizedBox(height: theme.spaceLG),

        // 服药时间
        Text(
          '服药时间',
          style: TextStyle(
            fontSize: theme.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: theme.spaceSM),
        ...List.generate(_selectedTimes.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: theme.spaceSM),
            child: Row(
              children: [
                Icon(Icons.access_time, color: theme.primary, size: theme.iconStandard),
                SizedBox(width: theme.spaceSM),
                Text(
                  _selectedTimes[index],
                  style: TextStyle(
                    fontSize: theme.fontSizeH3,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        DateTime.parse('2024-01-01 ${_selectedTimes[index]}:00'),
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedTimes[index] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: const Text('修改'),
                ),
                if (_selectedTimes.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _selectedTimes.removeAt(index)),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _selectedTimes.add('12:00')),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('添加时间'),
        ),
        SizedBox(height: theme.spaceLG),

        // 重复
        Text(
          '重复',
          style: TextStyle(
            fontSize: theme.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: theme.spaceSM),
        Wrap(
          spacing: theme.spaceSM,
          runSpacing: theme.spaceSM,
          children: List.generate(7, (index) {
            final day = index + 1;
            final selected = _selectedDays.contains(day);
            final labels = ['一', '二', '三', '四', '五', '六', '日'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
              child: Container(
                width: theme.isElderlyMode ? 52 : 44,
                height: theme.isElderlyMode ? 52 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? theme.primary : const Color(0xFFF5F5F5),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: theme.isElderlyMode ? 20 : 16,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : theme.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStep3(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 开始日期
        _buildSettingItem(
          theme,
          icon: Icons.calendar_today,
          label: '开始日期',
          value: DateTime.now().toIso8601String().split('T')[0],
        ),
        SizedBox(height: theme.spaceLG),

        // 结束日期
        _buildSettingItem(
          theme,
          icon: Icons.event,
          label: '结束日期',
          value: '无（长期服用）',
        ),
        SizedBox(height: theme.spaceLG),

        // 剩余数量
        Text(
          '剩余数量',
          style: TextStyle(
            fontSize: theme.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: theme.spaceSM),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '数量',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            SizedBox(width: theme.spaceSM),
            Text(
              _dosageUnit,
              style: TextStyle(
                fontSize: theme.fontSizeBody,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: theme.spaceLG),

        // 提醒方式
        Text(
          '提醒方式',
          style: TextStyle(
            fontSize: theme.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: theme.spaceSM),
        Row(
          children: [
            FilterChip(
              label: const Text('推送通知'),
              selected: true,
              onSelected: (_) {},
            ),
            SizedBox(width: theme.spaceSM),
            FilterChip(
              label: const Text('声音'),
              selected: true,
              onSelected: (_) {},
            ),
            SizedBox(width: theme.spaceSM),
            FilterChip(
              label: const Text('震动'),
              selected: false,
              onSelected: (_) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    ThemeProvider theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.primary, size: theme.iconStandard),
        SizedBox(width: theme.spaceSM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: theme.fontSizeCaption,
                color: theme.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: theme.fontSizeBody,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Icon(Icons.chevron_right, color: theme.textDisabled),
      ],
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeProvider theme;

  const _FrequencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spaceLG,
          vertical: theme.spaceSM,
        ),
        decoration: BoxDecoration(
          color: selected ? theme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(theme.radiusLG),
          border: Border.all(
            color: selected ? theme.primary : const Color(0xFFE8E8E8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: theme.fontSizeBodySmall,
            color: selected ? theme.primary : theme.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
