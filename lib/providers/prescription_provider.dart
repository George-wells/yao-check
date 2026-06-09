import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/prescription.dart';

/// 处方管理状态管理 Provider
/// 功能：处方CRUD、OCR识别、到期提醒、续方提醒
class PrescriptionProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Prescription> _prescriptions = [];
  Prescription? _selectedPrescription;
  bool _isLoading = false;
  String? _error;

  List<Prescription> get prescriptions => _prescriptions;
  Prescription? get selectedPrescription => _selectedPrescription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 获取有效处方列表
  List<Prescription> get activePrescriptions =>
      _prescriptions.where((p) => p.isValid).toList();

  /// 获取即将过期的处方（7天内）
  List<Prescription> get expiringPrescriptions {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return _prescriptions.where((p) {
      if (!p.isValid || p.expiryDate == null) return false;
      final expiry = DateTime.tryParse(p.expiryDate!);
      return expiry != null && expiry.isAfter(now) && expiry.isBefore(sevenDaysLater);
    }).toList();
  }

  /// 获取已过期处方
  List<Prescription> get expiredPrescriptions =>
      _prescriptions.where((p) => p.status == 'expired').toList();

  /// 加载处方列表
  Future<void> loadPrescriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/prescriptions');
      if (response.data['success'] == true) {
        _prescriptions = (response.data['data'] as List<dynamic>)
            .map((e) => Prescription.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = '加载处方列表失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 获取处方详情
  Future<void> getPrescriptionDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/prescriptions/$id');
      if (response.data['success'] == true) {
        _selectedPrescription = Prescription.fromJson(response.data['data']);
      } else {
        _error = '未找到处方';
      }
    } catch (e) {
      _error = '获取处方详情失败';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 创建处方
  Future<bool> createPrescription(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/prescriptions', data: data);
      if (response.data['success'] == true) {
        await loadPrescriptions();
        return true;
      }
      _error = response.data['message'] ?? '创建失败';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '网络错误';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 更新处方
  Future<bool> updatePrescription(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/prescriptions/$id', data: data);
      if (response.data['success'] == true) {
        await loadPrescriptions();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 删除处方
  Future<bool> deletePrescription(String id) async {
    try {
      final response = await _api.delete('/prescriptions/$id');
      if (response.data['success'] == true) {
        await loadPrescriptions();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 提交OCR识别
  Future<bool> submitOcr(String id, String imageUrl) async {
    try {
      final response = await _api.post('/prescriptions/$id/ocr', data: {
        'imageUrl': imageUrl,
      });
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 获取续方提醒列表
  List<Map<String, dynamic>> getRefillReminders() {
    final reminders = <Map<String, dynamic>>[];
    for (final prescription in activePrescriptions) {
      for (final medicine in prescription.medicines) {
        reminders.add({
          'prescriptionId': prescription.id,
          'medicineName': medicine.name,
          'dosage': medicine.dosage ?? '',
          'frequency': medicine.frequency ?? '',
          'hospitalName': prescription.hospitalName ?? '',
          'issueDate': prescription.issueDate ?? '',
          'expiryDate': prescription.expiryDate ?? '',
        });
      }
    }
    return reminders;
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
