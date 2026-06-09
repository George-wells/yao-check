import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/guardianship.dart';

/// 家人远程监护状态管理 Provider
/// 功能：绑定/解绑、查看被监护人用药、接收漏服通知、发送提醒
class GuardianProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<GuardianPatientSummary> _patients = [];
  List<Guardianship> _myGuardians = [];
  List<Guardianship> _invitations = [];
  GuardianReport? _selectedReport;
  bool _isLoading = false;
  String? _error;

  List<GuardianPatientSummary> get patients => _patients;
  List<Guardianship> get myGuardians => _myGuardians;
  List<Guardianship> get invitations => _invitations;
  GuardianReport? get selectedReport => _selectedReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载被监护人列表
  Future<void> loadPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/guardians/patients');
      if (response.data['success'] == true) {
        _patients = (response.data['data'] as List<dynamic>)
            .map((e) => GuardianPatientSummary.fromJson(e))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// 加载我的监护人列表
  Future<void> loadMyGuardians() async {
    try {
      final response = await _api.get('/guardians/my-guardians');
      if (response.data['success'] == true) {
        _myGuardians = (response.data['data'] as List<dynamic>)
            .map((e) => Guardianship.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 加载待确认邀请
  Future<void> loadInvitations() async {
    try {
      final response = await _api.get('/guardians/invitations');
      if (response.data['success'] == true) {
        _invitations = (response.data['data'] as List<dynamic>)
            .map((e) => Guardianship.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 发送监护邀请
  Future<bool> sendInvitation(String patientId, String relationship) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/guardians', data: {
        'patientId': patientId,
        'relationship': relationship,
      });
      if (response.data['success'] == true) {
        await loadPatients();
        return true;
      }
      _error = response.data['message'] ?? '发送邀请失败';
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

  /// 确认/拒绝监护邀请
  Future<bool> confirmInvitation(String patientId, bool accept) async {
    try {
      final response = await _api.put('/guardians/$patientId/confirm', data: {
        'action': accept ? 'accept' : 'reject',
      });
      if (response.data['success'] == true) {
        await loadInvitations();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 解除监护关系
  Future<bool> removeGuardianship(String patientId) async {
    try {
      final response = await _api.delete('/guardians/$patientId');
      if (response.data['success'] == true) {
        await loadPatients();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 获取被监护人用药报告
  Future<void> loadReport(String patientId, {int days = 7}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/guardians/$patientId/report', queryParameters: {
        'days': days,
      });
      if (response.data['success'] == true) {
        _selectedReport = GuardianReport.fromJson(response.data['data']);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// 发送提醒服药通知
  Future<bool> sendReminder(String patientId) async {
    try {
      // 通过通知API发送提醒
      final response = await _api.post('/notifications', data: {
        'patientId': patientId,
        'type': 'guardian_reminder',
        'title': '家人提醒您服药',
        'body': '您的家人提醒您按时服药，请注意健康！',
      });
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// 加载所有数据
  Future<void> loadAll() async {
    await Future.wait([
      loadPatients(),
      loadMyGuardians(),
      loadInvitations(),
    ]);
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
