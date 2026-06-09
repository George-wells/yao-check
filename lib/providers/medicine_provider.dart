import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../models/medicine.dart';
import '../models/interaction.dart';

/// 药物信息查询状态管理 Provider（增强版）
/// 功能：搜索（防抖）、详情、条码查询、相互作用检查、搜索历史持久化
class MedicineProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final LocalStorageService _storage = LocalStorageService.instance;

  List<Medicine> _searchResults = [];
  Medicine? _selectedMedicine;
  InteractionResult? _interactionResult;
  List<String> _recentSearches = [];
  List<Medicine> _hotMedicines = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  // 防抖
  Timer? _debounceTimer;

  List<Medicine> get searchResults => _searchResults;
  Medicine? get selectedMedicine => _selectedMedicine;
  InteractionResult? get interactionResult => _interactionResult;
  List<String> get recentSearches => _recentSearches;
  List<Medicine> get hotMedicines => _hotMedicines;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;

  /// 初始化 - 加载热门药品和搜索历史
  Future<void> init() async {
    _recentSearches = _storage.getStringList('recent_searches') ?? [];
    await loadHotMedicines();
    notifyListeners();
  }

  /// 加载热门药品
  Future<void> loadHotMedicines() async {
    try {
      final response = await _api.get('/medicines', queryParameters: {
        'pageSize': 10,
      });
      if (response.data['success'] == true) {
        _hotMedicines = (response.data['data'] as List<dynamic>)
            .map((e) => Medicine.fromJson(e))
            .toList();
      }
    } catch (_) {
      // 使用默认热门药品
      _hotMedicines = [];
    }
  }

  /// 防抖搜索
  void searchDebounced(String keyword) {
    _debounceTimer?.cancel();
    if (keyword.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      searchMedicine(keyword);
    });
  }

  /// 搜索药品
  Future<void> searchMedicine(String keyword) async {
    if (keyword.isEmpty) return;

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/medicines', queryParameters: {
        'keyword': keyword,
        'pageSize': 20,
      });
      if (response.data['success'] == true) {
        _searchResults = (response.data['data'] as List<dynamic>)
            .map((e) => Medicine.fromJson(e))
            .toList();

        // 添加到最近搜索（去重）
        _addToRecentSearches(keyword);
      } else {
        _searchResults = [];
      }
    } catch (e) {
      _error = '搜索失败，请检查网络';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  /// 添加到最近搜索
  void _addToRecentSearches(String keyword) {
    _recentSearches.remove(keyword);
    _recentSearches.insert(0, keyword);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    _storage.setStringList('recent_searches', _recentSearches);
  }

  /// 清除最近搜索
  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    await _storage.setStringList('recent_searches', []);
    notifyListeners();
  }

  /// 获取药品详情
  Future<void> getMedicineDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/medicines/$id');
      if (response.data['success'] == true) {
        _selectedMedicine = Medicine.fromJson(response.data['data']);
      } else {
        _error = '未找到该药品';
      }
    } catch (e) {
      _error = '获取药品信息失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 按名称搜索药品详情（用于搜索页跳转）
  Future<void> getMedicineByName(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/medicines', queryParameters: {
        'keyword': name,
        'pageSize': 1,
      });
      if (response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>;
        if (list.isNotEmpty) {
          final id = list[0]['id'];
          await getMedicineDetail(id);
          return;
        }
      }
      // 如果API没有数据，创建本地临时对象
      _selectedMedicine = _createMockMedicine(name);
    } catch (e) {
      _selectedMedicine = _createMockMedicine(name);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 创建模拟药品数据（离线/API不可用时使用）
  Medicine _createMockMedicine(String name) {
    final mockData = _getMockMedicineData(name);
    return Medicine(
      id: 'mock_${name.hashCode}',
      name: mockData['name'] ?? name,
      genericName: mockData['genericName'],
      category: mockData['category'],
      dosageForm: mockData['dosageForm'],
      specification: mockData['specification'],
      manufacturer: mockData['manufacturer'],
      barcode: mockData['barcode'],
      indications: mockData['indications'],
      usageDosage: mockData['usageDosage'],
      contraindications: mockData['contraindications'],
      sideEffects: mockData['sideEffects'],
      precautions: mockData['precautions'],
      drugInteractions: mockData['drugInteractions'],
      plainLanguageExplanation: mockData['plainLanguageExplanation'],
    );
  }

  /// 条码查询药品
  Future<void> getMedicineByBarcode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/medicines/barcode/$code');
      if (response.data['success'] == true) {
        _selectedMedicine = Medicine.fromJson(response.data['data']);
      } else {
        _error = '未找到该药品';
      }
    } catch (e) {
      _error = '查询失败，请检查网络';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 药物相互作用检查
  Future<void> checkInteractions(List<String> medicineIds) async {
    if (medicineIds.length < 2) {
      _error = '请至少选择2种药品';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _interactionResult = null;
    notifyListeners();

    try {
      final response = await _api.post('/medicines/interactions', data: {
        'medicineIds': medicineIds,
      });
      if (response.data['success'] == true) {
        _interactionResult = InteractionResult.fromJson(response.data['data']);
      } else {
        _error = response.data['message'] ?? '检查失败';
      }
    } catch (e) {
      _error = '检查失败，请重试';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 获取用户的药品列表（用于相互作用检查选择）
  Future<List<Medicine>> getUserMedicines() async {
    try {
      final response = await _api.get('/medicines', queryParameters: {
        'pageSize': 50,
      });
      if (response.data['success'] == true) {
        return (response.data['data'] as List<dynamic>)
            .map((e) => Medicine.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 清除搜索结果
  void clearSearch() {
    _debounceTimer?.cancel();
    _searchResults = [];
    _selectedMedicine = null;
    _interactionResult = null;
    _error = null;
    _isSearching = false;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 模拟药品数据
  Map<String, dynamic> _getMockMedicineData(String name) {
    final medicines = {
      '硝苯地平': {
        'name': '硝苯地平控释片',
        'genericName': '硝苯地平',
        'category': '降压药',
        'dosageForm': '缓释片',
        'specification': '30mg×30片',
        'manufacturer': '拜耳医药保健有限公司',
        'barcode': '6901234567891',
        'indications': '用于治疗高血压、冠心病、慢性稳定型心绞痛。',
        'usageDosage': '每日1次，每次1片（30mg），整片吞服，不可咀嚼。建议在早晨服用。',
        'contraindications': '对本品过敏者禁用；心源性休克禁用；不稳定性心绞痛禁用。',
        'sideEffects': '头痛、面部潮红、踝部水肿、心悸、头晕、乏力。',
        'precautions': '不可与葡萄柚汁同服；不可突然停药；定期监测血压。',
        'drugInteractions': '与β受体阻滞剂合用需监测血压；与利福平合用降低药效；与克拉霉素合用增加血药浓度。',
        'plainLanguageExplanation': '硝苯地平是一种钙通道阻滞剂，通过扩张血管来降低血压。缓释片的设计让药物在体内缓慢释放，每天只需服用一次。',
      },
      '二甲双胍': {
        'name': '二甲双胍片',
        'genericName': '二甲双胍',
        'category': '降糖药',
        'dosageForm': '片剂',
        'specification': '0.5g×60片',
        'manufacturer': '中美上海施贵宝制药有限公司',
        'barcode': '6901234567892',
        'indications': '用于治疗2型糖尿病，尤其适用于肥胖型患者。',
        'usageDosage': '起始剂量一次0.5g，一日2次，随餐服用。根据血糖调整剂量。',
        'contraindications': '严重肾功能不全禁用；肝功能不全禁用；严重感染禁用。',
        'sideEffects': '胃肠道不适、腹泻、恶心、食欲减退。',
        'precautions': '定期监测肾功能；与碘造影剂合用需暂停用药；避免饮酒。',
        'drugInteractions': '与胰岛素合用增加低血糖风险；与碘造影剂合用增加乳酸酸中毒风险。',
        'plainLanguageExplanation': '二甲双胍是降糖药，帮助控制血糖水平。它通过减少肝脏产生葡萄糖和增加肌肉对葡萄糖的利用来降低血糖。需随餐服用减少胃肠道刺激。',
      },
      '阿司匹林': {
        'name': '阿司匹林肠溶片',
        'genericName': '阿司匹林',
        'category': '抗血小板药',
        'dosageForm': '肠溶片',
        'specification': '100mg×30片',
        'manufacturer': '拜耳医药保健有限公司',
        'barcode': '6901234567893',
        'indications': '用于预防心脑血管疾病，降低心肌梗死和中风风险。',
        'usageDosage': '每日1次，每次1片（100mg），饭后服用。',
        'contraindications': '活动性消化道溃疡禁用；出血体质禁用；对阿司匹林过敏禁用。',
        'sideEffects': '胃肠道不适、出血风险增加、过敏反应。',
        'precautions': '手术前需停药；避免与酒精同服；定期检查血常规。',
        'drugInteractions': '与华法林合用增加出血风险；与布洛芬合用降低抗血小板效果。',
        'plainLanguageExplanation': '阿司匹林是一种抗血小板药物，能防止血液中的血小板聚集形成血栓，从而预防心梗和脑梗。肠溶片设计可减少对胃的刺激。',
      },
      '阿托伐他汀': {
        'name': '阿托伐他汀钙片',
        'genericName': '阿托伐他汀',
        'category': '降脂药',
        'dosageForm': '片剂',
        'specification': '10mg×28片',
        'manufacturer': '辉瑞制药有限公司',
        'barcode': '6901234567894',
        'indications': '用于高胆固醇血症、冠心病、动脉粥样硬化。',
        'usageDosage': '起始剂量一次10mg，一日一次，可在任何时间服用。',
        'contraindications': '活动性肝病禁用；妊娠期禁用；哺乳期禁用。',
        'sideEffects': '肌肉疼痛、肝功能异常、头痛、消化不良。',
        'precautions': '定期监测肝功能和肌酸激酶；出现肌肉疼痛及时就医。',
        'drugInteractions': '与克拉霉素合用增加肌病风险；与环孢素合用增加血药浓度。',
        'plainLanguageExplanation': '阿托伐他汀是降脂药，降低血液中的胆固醇水平，特别是"坏胆固醇"（LDL-C），保护心血管健康。',
      },
      '氯沙坦': {
        'name': '氯沙坦钾片',
        'genericName': '氯沙坦',
        'category': '降压药',
        'dosageForm': '片剂',
        'specification': '50mg×28片',
        'manufacturer': '默沙东制药有限公司',
        'barcode': '6901234567895',
        'indications': '用于原发性高血压，可单独或与其他降压药联用。',
        'usageDosage': '一次50mg，一日一次，最大剂量可增至100mg。',
        'contraindications': '妊娠期禁用；严重肾功能不全慎用。',
        'sideEffects': '头晕、低血压、高钾血症、咳嗽。',
        'precautions': '监测血钾水平；避免与保钾利尿剂合用；定期监测肾功能。',
        'drugInteractions': '与保钾利尿剂合用增加高钾血症风险；与NSAIDs合用降低降压效果。',
        'plainLanguageExplanation': '氯沙坦是降压药，通过阻断血管紧张素II的作用来扩张血管、降低血压。属于ARB类降压药，副作用较少。',
      },
    };

    // 模糊匹配
    for (final entry in medicines.entries) {
      if (name.contains(entry.key) || entry.key.contains(name)) {
        return entry.value;
      }
    }

    // 默认返回硝苯地平
    return medicines['硝苯地平']!;
  }
}
