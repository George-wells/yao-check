import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/volcengine_service.dart';

/// 设置页面 - 包含火山引擎 AI配置
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  String _currentModel = 'doubao-1.5-pro-256k';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final apiKey = await VolcengineService.getApiKey();
    final model = await VolcengineService.getModel();
    if (mounted) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        _currentModel = model;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    await VolcengineService.setApiKey(_apiKeyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key 已保存'), backgroundColor: Colors.green),
    );
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入 API Key'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await VolcengineService.askQuestion('你好，请回复"连接成功"');
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.contains('连接成功') ? '✅ 连接成功！' : '连接失败，请检查 Key'),
        backgroundColor: result.contains('连接成功') ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(isElderly ? 24 : 16),
              children: [
                // ========== 显示设置 ==========
                _buildSectionTitle(theme, '显示设置'),
                SizedBox(height: theme.spaceSM),
                _buildThemeCard(theme, isElderly),

                SizedBox(height: theme.spaceLG),

                // ========== AI 配置 ==========
                _buildSectionTitle(theme, 'AI 配置'),
                SizedBox(height: theme.spaceSM),
                _buildAiConfigCard(theme, isElderly),

                SizedBox(height: theme.spaceLG),

                // ========== 关于 ==========
                _buildSectionTitle(theme, '关于'),
                SizedBox(height: theme.spaceSM),
                _buildAboutCard(theme, isElderly),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(ThemeProvider theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: theme.fontSizeH3,
        fontWeight: FontWeight.bold,
        color: theme.textPrimary,
      ),
    );
  }

  Widget _buildThemeCard(ThemeProvider theme, bool isElderly) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 适老化模式
            SwitchListTile(
              title: Text('适老化模式', style: TextStyle(fontSize: isElderly ? 18 : 16)),
              subtitle: Text(
                '大字体、大按钮、高对比度',
                style: TextStyle(fontSize: isElderly ? 14 : 12, color: theme.textSecondary),
              ),
              value: theme.isElderlyMode,
              onChanged: (v) => theme.toggleMode(),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiConfigCard(ThemeProvider theme, bool isElderly) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Key
            Text(
              '火山引擎 API Key',
              style: TextStyle(
                fontSize: isElderly ? 18 : 16,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceSM),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '输入你的 火山引擎 API Key',
                hintStyle: TextStyle(color: theme.textDisabled),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(theme.radiusMD),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: theme.spaceMD,
                  vertical: isElderly ? 16 : 12,
                ),
              ),
              style: TextStyle(fontSize: isElderly ? 18 : 14),
            ),
            SizedBox(height: theme.spaceMD),

            // 模型选择
            Text(
              '模型选择',
              style: TextStyle(
                fontSize: isElderly ? 18 : 16,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceSM),
            DropdownButtonFormField<String>(
              value: _currentModel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(theme.radiusMD),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: theme.spaceMD,
                  vertical: isElderly ? 16 : 12,
                ),
              ),
              style: TextStyle(fontSize: isElderly ? 18 : 14),
              items: const [
                DropdownMenuItem(value: 'doubao-1.5-pro-256k', child: Text('火山引擎 Chat')),
                DropdownMenuItem(value: 'doubao-1.5-lite-32k', child: Text('火山引擎 Reasoner')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _currentModel = v);
                  VolcengineService.setModel(v);
                }
              },
            ),
            SizedBox(height: theme.spaceMD),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveApiKey,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存'),
                  ),
                ),
                SizedBox(width: theme.spaceMD),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testConnection,
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('测试连接'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(ThemeProvider theme, bool isElderly) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(theme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(theme, '应用名称', AppConstants.appName, isElderly),
            _buildInfoRow(theme, '版本', AppConstants.appVersion, isElderly),
            _buildInfoRow(theme, '数据存储', '仅本地（不上传云端）', isElderly),
            const SizedBox(height: 16),
            Text(
              '本应用所有数据仅存储在您的设备上，不会上传到任何服务器。AI查询功能通过您自行配置的 API Key 调用 火山引擎 官方接口。',
              style: TextStyle(
                fontSize: isElderly ? 14 : 12,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeProvider theme, String label, String value, bool isElderly) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spaceSM),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isElderly ? 16 : 14,
                color: theme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isElderly ? 16 : 14,
                color: theme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
