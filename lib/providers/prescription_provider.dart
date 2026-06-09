import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/prescription.dart';

/// 处方管理Provider - 本地存储版
class PrescriptionProvider extends ChangeNotifier {
  List<Prescription> _prescriptions = [];
  Prescription? _selectedPrescription;
  bool _isLoading = false;

  List<Prescription> get prescriptions => _prescriptions;
  Prescription? get selectedPrescription => _selectedPrescription;
  bool get isLoading => _isLoading;

  /// 即将过期的处方（7天内）
  List<Prescription> get expiringPrescriptions {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return _prescriptions.where((p) {
      if (p.expiryDate == null) return false;
      final expiry = DateTime.tryParse(p.expiryDate!);
      return expiry != null && expiry.isAfter(now) && expiry.isBefore(sevenDaysLater);
    }).toList();
  }

  Box get _box => Hive.box('medication_data');

  PrescriptionProvider() {
    loadPrescriptions();
  }

  void loadPrescriptions() {
    _isLoading = true;
    notifyListeners();

    final data = _box.get('prescriptions', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _prescriptions = list.map((e) => Prescription.fromJson(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  void _savePrescriptions() {
    final data = jsonEncode(_prescriptions.map((e) => e.toJson()).toList());
    _box.put('prescriptions', data);
  }

  Future<void> addPrescription(Prescription prescription) async {
    _prescriptions.add(prescription);
    _savePrescriptions();
    notifyListeners();
  }

  Future<bool> createPrescription(Map<String, dynamic> data) async {
    final prescription = Prescription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'local',
      hospitalName: data['hospitalName'],
      doctorName: data['doctorName'],
      diagnosis: data['diagnosis'],
      issueDate: data['issueDate'],
      expiryDate: data['expiryDate'],
      status: 'active',
    );
    _prescriptions.add(prescription);
    _savePrescriptions();
    notifyListeners();
    return true;
  }

  Future<void> updatePrescription(Prescription prescription) async {
    final index = _prescriptions.indexWhere((p) => p.id == prescription.id);
    if (index >= 0) {
      _prescriptions[index] = prescription;
      _savePrescriptions();
      notifyListeners();
    }
  }

  Future<void> deletePrescription(String id) async {
    _prescriptions.removeWhere((p) => p.id == id);
    _savePrescriptions();
    notifyListeners();
  }

  Future<void> getPrescriptionDetail(String id) async {
    _isLoading = true;
    notifyListeners();
    _selectedPrescription = _prescriptions.where((p) => p.id == id).firstOrNull;
    _isLoading = false;
    notifyListeners();
  }

  void selectPrescription(Prescription? prescription) {
    _selectedPrescription = prescription;
    notifyListeners();
  }
}
