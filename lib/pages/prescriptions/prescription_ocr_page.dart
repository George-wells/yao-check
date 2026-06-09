import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/prescription_provider.dart';

/// OCR拍照识别处方页（增强版）
/// 支持：拍照/相册选择、OCR识别模拟、编辑确认、保存
class PrescriptionOcrPage extends StatefulWidget {
  const PrescriptionOcrPage({super.key});

  @override
  State<PrescriptionOcrPage> createState() => _PrescriptionOcrPageState();
}

class _PrescriptionOcrPageState extends State<PrescriptionOcrPage> {
  final ImagePicker _picker = ImagePicker();
  final _hospitalController = TextEditingController(text: '北京大学第一医院');
  final _doctorController = TextEditingController(text: '张医生');
  final _dateController = TextEditingController(text: '2026-06-01');

  XFile? _imageFile;
  bool _isScanning = false;
  bool _isComplete = false;

  @override
  void dispose() {
    _hospitalController.dispose();
    _doctorController.dispose();
    _dateController.dispose();
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
        });

        // 模拟OCR识别过程
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          setState(() {
            _isScanning = false;
            _isComplete = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拍照失败，请重试')),
        );
      }
    }
  }

  Future<void> _savePrescription() async {
    final provider = context.read<PrescriptionProvider>();
    final data = {
      'hospitalName': _hospitalController.text,
      'doctorName': _doctorController.text,
      'issueDate': _dateController.text,
      'medicines': [
        {'name': '硝苯地平控释片 30mg', 'dosage': '每次1片', 'frequency': '每日1次', 'duration': '30天'},
        {'name': '二甲双胍片 500mg', 'dosage': '每次1片', 'frequency': '每日2次', 'duration': '30天'},
        {'name': '阿司匹林肠溶片 100mg', 'dosage': '每次1片', 'frequency': '每日1次', 'duration': '30天'},
      ],
    };

    final success = await provider.createPrescription(data);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('处方已保存'), backgroundColor: Colors.green),
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
        title: const Text('拍照识别处方'),
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
        // 取景框
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
                  child: Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: isElderly ? 80 : 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: theme.spaceMD),
                      Text(
                        '将处方放在取景框内',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isElderly ? 22 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const Spacer(),
        // 操作按钮
        if (_isScanning)
          Column(
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '正在识别处方...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isElderly ? 20 : 16,
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 相册选择
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  width: isElderly ? 72 : 60,
                  height: isElderly ? 72 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: isElderly ? 32 : 28,
                  ),
                ),
              ),
              SizedBox(width: isElderly ? 40 : 32),
              // 拍照按钮
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: isElderly ? 80 : 72,
                  height: isElderly ? 80 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: theme.primary, width: 4),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: isElderly ? 40 : 32,
                    color: theme.primary,
                  ),
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
                    '识别完成，请逐项核对',
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF52C41A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: theme.spaceLG),

          // 处方照片预览
          if (_imageFile != null)
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(theme.cardRadius),
                image: DecorationImage(
                  image: FileImage(File(_imageFile!.path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (_imageFile != null)
            SizedBox(height: theme.spaceLG),

          // 处方信息（可编辑）
          _buildEditableField(theme, '医院', _hospitalController),
          _buildEditableField(theme, '医生', _doctorController),
          _buildEditableField(theme, '日期', _dateController),
          SizedBox(height: theme.spaceLG),

          // 药品清单
          Text(
            '药品清单',
            style: TextStyle(
              fontSize: theme.fontSizeH3,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          SizedBox(height: theme.spaceMD),
          _buildMedicineItem(theme, '1. 硝苯地平控释片 30mg', '每日1次 每次1片 30天'),
          Divider(color: theme.dividerColor),
          _buildMedicineItem(theme, '2. 二甲双胍片 500mg', '每日2次 每次1片 30天'),
          Divider(color: theme.dividerColor),
          _buildMedicineItem(theme, '3. 阿司匹林肠溶片 100mg', '每日1次 每次1片 30天'),
          SizedBox(height: theme.spaceLG),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: theme.buttonHeight,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isComplete = false;
                      _imageFile = null;
                    }),
                    child: Text('重新拍照', style: TextStyle(fontSize: theme.fontSizeButton)),
                  ),
                ),
              ),
              SizedBox(width: theme.spaceMD),
              Expanded(
                child: SizedBox(
                  height: theme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _savePrescription,
                    child: Text('确认保存', style: TextStyle(fontSize: theme.fontSizeButton)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(ThemeProvider theme, String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spaceMD),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: theme.fontSizeBodySmall,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: theme.fontSizeBody,
                color: theme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Icon(Icons.edit, size: 18, color: theme.primary),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(ThemeProvider theme, String name, String usage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spaceSM),
      child: Row(
        children: [
          Icon(Icons.medication, size: 20, color: theme.primary),
          SizedBox(width: theme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: theme.fontSizeBody, color: theme.textPrimary)),
                Text(usage, style: TextStyle(fontSize: theme.fontSizeCaption, color: theme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
