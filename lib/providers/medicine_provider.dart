import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/medicine.dart';

/// 药品信息Provider - 本地存储版
class MedicineProvider extends ChangeNotifier {
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Box get _box => Hive.box('medication_data');

  MedicineProvider() {
    loadMedicines();
  }

  void loadMedicines() {
    _isLoading = true;
    notifyListeners();

    final data = _box.get('medicines', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _medicines = list.map((e) => Medicine.fromJson(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  void _saveMedicines() {
    final data = jsonEncode(_medicines.map((e) => e.toJson()).toList());
    _box.put('medicines', data);
  }

  Future<void> addMedicine(Medicine medicine) async {
    _medicines.add(medicine);
    _saveMedicines();
    notifyListeners();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index >= 0) {
      _medicines[index] = medicine;
      _saveMedicines();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Medicine> searchMedicines(String query) {
    if (query.isEmpty) return _medicines;
    final q = query.toLowerCase();
    return _medicines.where((m) =>
      m.name.toLowerCase().contains(q) ||
      (m.genericName?.toLowerCase().contains(q) ?? false)
    ).toList();
  }
}
