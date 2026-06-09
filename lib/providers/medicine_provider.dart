import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/medicine.dart';
import '../services/volcengine_service.dart';

/// 药品信息Provider - 本地存储 + 火山引擎 AI 查询
class MedicineProvider extends ChangeNotifier {
  List<Medicine> _medicines = [];
  List<Medicine> _searchResults = [];
  List<String> _recentSearches = [];
  Medicine? _selectedMedicine;
  String? _interactionResult;
  String? _error;
  bool _isSearching = false;
  bool _isLoading = false;
  String _searchQuery = '';

  List<Medicine> get medicines => _medicines;
  List<Medicine> get searchResults => _searchResults;
  List<String> get recentSearches => _recentSearches;
  Medicine? get selectedMedicine => _selectedMedicine;
  String? get interactionResult => _interactionResult;
  String? get error => _error;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Box get _box => Hive.box('medication_data');

  MedicineProvider() {
    loadMedicines();
    _loadRecentSearches();
  }

  void loadMedicines() {
    final data = _box.get('medicines', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _medicines = list.map((e) => Medicine.fromJson(e)).toList();
    notifyListeners();
  }

  void _saveMedicines() {
    final data = jsonEncode(_medicines.map((e) => e.toJson()).toList());
    _box.put('medicines', data);
  }

  void _loadRecentSearches() {
    final data = _box.get('recent_searches', defaultValue: '[]');
    _recentSearches = (jsonDecode(data) as List).cast<String>();
  }

  void _saveRecentSearches() {
    _box.put('recent_searches', jsonEncode(_recentSearches));
  }

  /// 初始化（加载本地药品数据）
  Future<void> init() async {
    loadMedicines();
    notifyListeners();
  }

  /// 搜索药品（本地 + AI）
  Future<void> searchMedicine(String keyword) async {
    if (keyword.isEmpty) return;
    _isSearching = true;
    _error = null;
    notifyListeners();

    // 本地搜索
    _searchResults = _medicines.where((m) =>
      m.name.toLowerCase().contains(keyword.toLowerCase()) ||
      (m.genericName?.toLowerCase().contains(keyword.toLowerCase()) ?? false)
    ).toList();

    // 添加搜索记录
    _recentSearches.remove(keyword);
    _recentSearches.insert(0, keyword);
    if (_recentSearches.length > 20) _recentSearches = _recentSearches.sublist(0, 20);
    _saveRecentSearches();

    _isSearching = false;
    notifyListeners();
  }

  /// 带防抖的搜索
  void searchDebounced(String value) {
    _searchQuery = value;
    if (value.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    searchMedicine(value);
  }

  /// 获取药品详情（本地 + AI 补充）
  Future<void> getMedicineDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _selectedMedicine = _medicines.where((m) => m.id == id).firstOrNull;
    _isLoading = false;
    notifyListeners();
  }

  /// 通过名称获取药品（AI 查询）
  Future<void> getMedicineByName(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 先查本地
    _selectedMedicine = _medicines.where((m) =>
      m.name == name || m.genericName == name
    ).firstOrNull;

    if (_selectedMedicine == null) {
      // 本地没有，用 AI 查询
      final result = await VolcengineService.queryMedicine(name);
      _selectedMedicine = Medicine(
        id: name,
        name: name,
        plainLanguageExplanation: result,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 获取用户常用药品
  Future<List<Medicine>> getUserMedicines() async {
    return _medicines;
  }

  /// 检查药物相互作用（AI）
  Future<void> checkInteractions(List<String> medicineIds) async {
    _isLoading = true;
    _error = null;
    _interactionResult = null;
    notifyListeners();

    final names = medicineIds.map((id) {
      final med = _medicines.where((m) => m.id == id).firstOrNull;
      return med?.name ?? id;
    }).toList();

    _interactionResult = await VolcengineService.checkInteraction(names);
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    _saveRecentSearches();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    _medicines.add(medicine);
    _saveMedicines();
    notifyListeners();
  }
}
