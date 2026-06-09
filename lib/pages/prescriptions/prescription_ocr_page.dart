import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/volcengine_service.dart';
import '../../models/medication_plan.dart';

/// OCR拍照识别药品页
/// 支持：拍照/相册选择 -> 火山引擎AI识别 -> 自动填充 -> 一键添加提醒
class PrescriptionOcrPage extends StatefulWidget {
  const PrescriptionOcrPage({super.key});

  @override
  State<PrescriptionOcrPage> createState() => _PrescriptionOcrPageState();
}

class _PrescriptionOcrPageState extends State<PrescriptionOcrPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isScanning = false;
  bool _isComplete = false;
  String _scanError = '';

  // 识别结果
  String _medicineName = '';
  String _genericName = '';
  String _specification = '';
  String _usageDosage = '';
  String _indications = '';
  String _sideEffects = '';
  String _precautions = '';
  String _frequency = 'daily';
  int _timesPerDay = 1;
  String _dosagePerTime = '每次1片';
  String _duration = '';
  String _mealTiming = '';
  List<String> _suggestedTimes = ['08:00'];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _imageFile = file;
          _isScanning = true;
          _scanError = '';
        });

        await _recognizeMedicine(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拍照失败，请重试')),
        );
      }
    }
  }

  Future<void> _recognizeMedicine(XFile file) async {
    try {
      // 读取图片并转 base64
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 调用火山引擎识别
      final result = await VolcengineService.recognizeMedicineImage(base64Image);

      if (mounted) {
        setState(() {
          _medicineName = result['name'] ?? '';
          _genericName = result['genericName'] ?? '';
          _specification = result['specification'] ?? '';
          _usageDosage = result['usageDosage'] ?? '';
          _indications = result['indications'] ?? '';
          _sideEffects = result['sideEffects'] ?? '';
          _precautions = result['precautions'] ?? '';
          _frequency = result['frequency'] ?? 'daily';
          _timesPerDay = (result['timesPerDay'] as num?)?.toInt() ?? 1;
          _dosagePerTime = result['dosagePerTime'] ?? '每次1片';
          _duration = result['duration'] ?? '';
          _mealTiming = result['mealTiming'] ?? '';
          if (result['suggestedTimes'] is List) {
            _suggestedTimes = (result['suggestedTimes'] as List).cast<String>();
          }
          _isScanning = false;
          _isComplete = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanError = '识别失败：$e';
        });
      }
    }
  }

  Future<void> _saveAndCreateReminder() async {
    if (_medicineName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('药品名称不能为空'), backgroundColor: Colors.orange),
      );
      return;
    }

    final reminderProvider = context.read<ReminderProvider>();

    // 自动创建用药提醒
    final schedule = _suggestedTimes.map((t) => ScheduleItem(
      time: t,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    )).toList();

    await reminderProvider.createPlan({
      'medicineName': _medicineName,
      'dosageValue': 1,
      'dosageUnit': '次',
      'dosageDescription': '$_dosagePerTime${_mealTiming.isNotEmpty ? "（$_mealTiming）" : ""}',
      'frequencyType': _frequency,
      'frequencyTimesPerDay': _timesPerDay,
      'schedule': schedule.map((s) => s.toJson()).toList(),
      'startDate': DateTime.now().toIso8601String().substring(0, 10),
      'notes': _duration.isNotEmpty ? '服用周期：$_duration' : null,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已识别「$_medicineName」并创建用药提醒'),
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
      backgroundColor: _isComplete ? theme.background : Colors.black,
      appBar: AppBar(
        backgroundColor: _isComplete ? null : Colors.transparent,
        foregroundColor: _isComplete ? null : Colors.white,
        title: const Text('拍照识别药品'),
      ),
      body: _isComplete
          ? _buildResultView(theme, isElderly)
          : _buildCameraView(theme, isElderly),
    );
  }

  Widget _buildCameraView(ThemeProvider theme, bool isElderly) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 280,
          height: 380,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: isElderly ? 80 : 64, color: Colors.white54),
                      SizedBox(height: theme.spaceMD),
                      Text('将药品包装放在取景框内', style: TextStyle(color: Colors.white70, fontSize: isElderly ? 22 : 16)),
                    ],
                  ),
                ),
        ),
        const Spacer(),
        if (_isScanning)
          Column(
            children: [
              const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              const SizedBox(height: 12),
              Text('正在识别药品...', style: TextStyle(color: Colors.white70, fontSize: isElderly ? 20 : 16)),
            ],
          )
        else if (_scanError.isNotEmpty)
          Column(
            children: [
              Icon(Icons.error_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 8),
              Text(_scanError, style: const TextStyle(color: Colors.orange, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _imageFile != null ? _recognizeMedicine(_imageFile!) : null,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('重试', style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  width: isElderly ? 72 : 60,
                  height: isElderly ? 72 : 60,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                  child: Icon(Icons.photo_library_outlined, color: Colors.white, size: isElderly ? 32 : 28),
                ),
              ),
              SizedBox(width: isElderly ? 40 : 32),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: isElderly ? 80 : 72,
                  height: isElderly ? 80 : 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: theme.primary, width: 4)),
                  child: Icon(Icons.camera_alt, size: isElderly ? 40 : 32, color: theme.primary),
                ),
              ),
            ],
          ),
        const Spacer(),
      ],
    );
  }

  Widget _buildResultView(ThemeProvider theme, bool isElderly) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isElderly ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 识别成功提示
          Container(
            padding: EdgeInsets.all(theme.cardPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF52C41A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(theme.cardRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF52C41A), size: 24),
                SizedBox(width: theme.spaceSM),
                Expanded(
                  child: Text(
                    '识别完成',
                    style: TextStyle(fontSize: theme.fontSizeBody, fontWeight: FontWeight.w600, color: const Color(0xFF52C41A)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: theme.spaceLG),

          // 药品照片
          if (_imageFile != null)
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(theme.cardRadius),
                image: DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover),
              ),
            ),
          if (_imageFile != null) SizedBox(height: theme.spaceLG),

          // 药品信息
          Text('药品信息', style: TextStyle(fontSize: theme.fontSizeH3, fontWeight: FontWeight.bold, color: theme.textPrimary)),
          SizedBox(height: theme.spaceMD),

          if (_medicineName.isNotEmpty)
            _buildInfoRow(theme, '药品名称', _medicineName, isElderly),
          if (_genericName.isNotEmpty)
            _buildInfoRow(theme, '通用名', _genericName, isElderly),
          if (_specification.isNotEmpty)
            _buildInfoRow(theme, '规格', _specification, isElderly),
          if (_usageDosage.isNotEmpty)
            _buildInfoRow(theme, '用法用量', _usageDosage, isElderly),
          if (_indications.isNotEmpty)
            _buildInfoRow(theme, '适应症', _indications, isElderly),
          if (_sideEffects.isNotEmpty)
            _buildInfoRow(theme, '不良反应', _sideEffects, isElderly),
          if (_precautions.isNotEmpty)
            _buildInfoRow(theme, '注意事项', _precautions, isElderly),
          if (_mealTiming.isNotEmpty)
            _buildInfoRow(theme, '服用时间', _mealTiming, isElderly),
          if (_duration.isNotEmpty)
            _buildInfoRow(theme, '服用周期', _duration, isElderly),

          SizedBox(height: theme.spaceLG),

          // 自动提醒设置
          Container(
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
                    Icon(Icons.alarm, color: theme.primary, size: 20),
                    SizedBox(width: theme.spaceSM),
                    Text('自动提醒设置', style: TextStyle(fontSize: theme.fontSizeBody, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                  ],
                ),
                SizedBox(height: theme.spaceMD),
                Text('每日 $_timesPerDay 次', style: TextStyle(fontSize: theme.fontSizeBodySmall, color: theme.textSecondary)),
                Text('建议时间：${_suggestedTimes.join("、")}', style: TextStyle(fontSize: theme.fontSizeBodySmall, color: theme.textSecondary)),
                if (_mealTiming.isNotEmpty)
                  Text('$_mealTiming 服用', style: TextStyle(fontSize: theme.fontSizeBodySmall, color: theme.textSecondary)),
              ],
            ),
          ),

          SizedBox(height: theme.spaceLG),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: theme.buttonHeight,
                  child: OutlinedButton(
                    onPressed: () => setState(() { _isComplete = false; _imageFile = null; _scanError = ''; }),
                    child: Text('重新拍照', style: TextStyle(fontSize: theme.fontSizeButton)),
                  ),
                ),
              ),
              SizedBox(width: theme.spaceMD),
              Expanded(
                child: SizedBox(
                  height: theme.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _saveAndCreateReminder,
                    icon: const Icon(Icons.add_alarm, size: 20),
                    label: Text('创建提醒', style: TextStyle(fontSize: theme.fontSizeButton)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeProvider theme, String label, String value, bool isElderly) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: isElderly ? 16 : 14, color: theme.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: isElderly ? 16 : 14, color: theme.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
