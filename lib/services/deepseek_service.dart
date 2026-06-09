import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// DeepSeek AI 服务
/// 用于药物信息查询和相互作用检查
class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String _apiKeyKey = 'deepseek_api_key';
  static const String _modelKey = 'deepseek_model';

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
    return prefs.getString(_modelKey) ?? 'deepseek-chat';
  }

  static Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// 查询药物信息
  static Future<String> queryMedicine(String medicineName) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return '请先在设置页面配置 DeepSeek API Key';
    }

    final model = await getModel();
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

    return _callDeepSeek(messages, model);
  }

  /// 药物相互作用检查
  static Future<String> checkInteraction(List<String> medicineNames) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return '请先在设置页面配置 DeepSeek API Key';
    }

    final model = await getModel();
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

    return _callDeepSeek(messages, model);
  }

  /// 通用AI问答
  static Future<String> askQuestion(String question) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return '请先在设置页面配置 DeepSeek API Key';
    }

    final model = await getModel();
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

    return _callDeepSeek(messages, model);
  }

  static Future<String> _callDeepSeek(List<Map<String, String>> messages, String model) async {
    try {
      final apiKey = await getApiKey();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '无法获取回答';
      } else if (response.statusCode == 401) {
        return 'API Key 无效，请在设置页面检查并重新配置。';
      } else {
        return '请求失败 (${response.statusCode})：${response.body}';
      }
    } catch (e) {
      return '网络请求失败：$e';
    }
  }
}
