import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 火山引擎 AI 服务
/// 支持：药物查询、相互作用检查、OCR药品识别
class VolcengineService {
  static const String _baseUrl = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  static const String _apiKeyKey = 'volcengine_api_key';
  static const String _modelKey = 'volcengine_model';

  // ==================== API Key 管理 ====================

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  static Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  static Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? 'doubao-1.5-pro-256k';
  }

  static Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  // ==================== 核心 API 调用 ====================

  static Future<String> _callVolcengine(List<Map<String, dynamic>> messages) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return '请先在设置页面配置火山引擎 API Key';
      }

      final model = await getModel();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.3,
          'max_tokens': 4096,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '无法获取回答';
      } else if (response.statusCode == 401) {
        return 'API Key 无效，请在设置页面检查并重新配置。';
      } else {
        final body = response.body;
        try {
          final err = jsonDecode(body);
          return '请求失败: ${err['error']?['message'] ?? body}';
        } catch (_) {
          return '请求失败 ($response.statusCode)';
        }
      }
    } catch (e) {
      return '网络请求失败：$e';
    }
  }

  /// 带图片的 API 调用（用于 OCR）
  static Future<String> _callVolcengineWithImage(List<Map<String, dynamic>> messages, String base64Image) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return '请先在设置页面配置火山引擎 API Key';
      }

      final model = await getModel();
      // 添加图片消息
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}},
        ],
      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.1,
          'max_tokens': 4096,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '无法识别';
      } else if (response.statusCode == 401) {
        return 'API Key 无效，请在设置页面检查并重新配置。';
      } else {
        return '请求失败 ($response.statusCode)';
      }
    } catch (e) {
      return '识别失败：$e';
    }
  }

  // ==================== 功能接口 ====================

  /// 查询药物信息
  static Future<String> queryMedicine(String medicineName) async {
    final messages = [
      {
        'role': 'system',
        'content': '你是一个专业的药物信息助手。请提供关于药物的详细信息，包括：'
            '1. 药品通用名和商品名\n'
            '2. 适应症\n'
            '3. 用法用量\n'
            '4. 不良反应\n'
            '5. 禁忌症\n'
            '6. 注意事项\n'
            '7. 药物相互作用\n'
            '请用中文回答，语言简洁明了，适合普通患者理解。'
      },
      {
        'role': 'user',
        'content': '请查询药物"$medicineName"的详细信息。'
      }
    ];
    return _callVolcengine(messages);
  }

  /// 药物相互作用检查
  static Future<String> checkInteraction(List<String> medicineNames) async {
    final medicineList = medicineNames.join('、');
    final messages = [
      {
        'role': 'system',
        'content': '你是一个专业的药物相互作用分析助手。请分析以下药物之间可能存在的相互作用，'
            '包括：\n'
            '1. 已知的相互作用及严重程度\n'
            '2. 可能的机制\n'
            '3. 临床建议\n'
            '4. 需要监测的指标\n'
            '请用中文回答，按严重程度排序，对严重相互作用给出明确警告。'
      },
      {
        'role': 'user',
        'content': '请分析以下药物之间的相互作用：$medicineList'
      }
    ];
    return _callVolcengine(messages);
  }

  /// OCR 识别药品包装/说明书图片
  /// 返回结构化药品信息
  static Future<Map<String, dynamic>> recognizeMedicineImage(String base64Image) async {
    final messages = [
      {
        'role': 'system',
        'content': '你是一个药品识别助手。请识别图片中的药品信息，并以严格的 JSON 格式返回。'
            '只返回 JSON，不要包含其他文字。JSON 字段如下：\n'
            '{\n'
            '  "name": "药品名称",\n'
            '  "genericName": "通用名",\n'
            '  "specification": "规格（如 0.5g*12片）",\n'
            '  "dosageForm": "剂型（片剂/胶囊/口服液等）",\n'
            '  "manufacturer": "生产厂家",\n'
            '  "indications": "适应症",\n'
            '  "usageDosage": "用法用量（如 每次1片，每日3次）",\n'
            '  "contraindications": "禁忌",\n'
            '  "sideEffects": "不良反应",\n'
            '  "precautions": "注意事项",\n'
            '  "drugInteractions": "药物相互作用",\n'
            '  "frequency": "服用频率（如 daily/每隔N小时）",\n'
            '  "timesPerDay": 每日次数（数字）,\n'
            '  "dosagePerTime": "每次用量（如 1片/1粒）",\n'
            '  "duration": "服用周期说明",\n'
            '  "mealTiming": "服用时间（饭前/饭后/空腹/随餐）",\n'
            '  "suggestedTimes": ["建议服药时间数组，如 08:00", "13:00", "19:00"]\n'
            '}\n'
            '如果某些信息无法识别，设为 null 或空字符串。'
      },
    ];
    // 注意：图片消息在 _callVolcengineWithImage 中添加
    final result = await _callVolcengineWithImage(messages, base64Image);

    // 尝试解析 JSON
    try {
      // 清理可能的 markdown 代码块标记
      var clean = result.trim();
      if (clean.startsWith('```')) {
        clean = clean.replaceAll(RegExp(r'```(json)?'), '').trim();
      }
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return {
        'name': result,
        'error': '无法解析为结构化数据',
      };
    }
  }

  /// 通用 AI 问答
  static Future<String> askQuestion(String question) async {
    final messages = [
      {
        'role': 'system',
        'content': '你是一个专业的用药助手，帮助用户解答关于药物使用、健康管理的问题。'
            '请用中文回答，语言通俗易懂。注意：你的回答仅供参考，不能替代专业医疗建议。'
      },
      {
        'role': 'user',
        'content': question
      }
    ];
    return _callVolcengine(messages);
  }
}
