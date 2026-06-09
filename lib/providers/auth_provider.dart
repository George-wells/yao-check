import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../models/user.dart';

/// 用户认证状态管理 Provider
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final LocalStorageService _storage = LocalStorageService.instance;

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  /// 初始化 - 检查登录状态
  Future<void> init() async {
    _isLoggedIn = await _api.isLoggedIn();
    if (_isLoggedIn) {
      _user = _storage.getCachedUser();
    }
    notifyListeners();
  }

  /// 发送验证码
  Future<bool> sendCode(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post('/auth/send-code', data: {
        'phone': phone,
        'purpose': 'login',
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '发送验证码失败，请重试';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登录
  Future<bool> login(String phone, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/login', data: {
        'phone': phone,
        'code': code,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await _api.saveTokens(
          data['tokens']['accessToken'],
          data['tokens']['refreshToken'],
        );
        _user = User.fromJson(data['user']);
        await _storage.cacheUser(_user!);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? '登录失败';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '网络错误，请检查网络连接';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearTokens();
    await _storage.clearUser();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  /// 更新用户信息
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/users/profile', data: data);
      if (response.data['success'] == true) {
        _user = User.fromJson(response.data['data']);
        await _storage.cacheUser(_user!);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// 更新适老化偏好
  Future<void> updateElderlyPreferences(Map<String, dynamic> data) async {
    try {
      await _api.put('/users/elderly-preferences', data: data);
      if (_user != null) {
        _user = _user!.copyWith(
          isElderlyMode: data['isElderlyMode'],
          fontScale: (data['fontScale'] as num?)?.toDouble(),
          highContrast: data['highContrast'],
          enableVoice: data['enableVoice'],
        );
        await _storage.cacheUser(_user!);
        notifyListeners();
      }
    } catch (_) {}
  }
}
