import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

/// API服务 - 基于Dio的网络请求封装
/// 功能：请求拦截器（自动注入Token）、响应拦截器（自动处理Token过期）、错误处理
class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(_createAuthInterceptor());
    _dio.interceptors.add(_createLogInterceptor());
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  Dio get dio => _dio;

  /// 创建认证拦截器
  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 自动注入Token
        final token = await _secureStorage.read(key: AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) async {
        // Token过期自动刷新
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // 重试原请求
            final token = await _secureStorage.read(key: AppConstants.tokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.next(error);
              return;
            }
          }
        }
        handler.next(error);
      },
    );
  }

  /// 创建日志拦截器
  InterceptorsWrapper _createLogInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // print('[API] ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        // print('[API] ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        // print('[API] ERROR ${error.response?.statusCode} ${error.requestOptions.path}');
        handler.next(error);
      },
    );
  }

  /// 刷新Token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.data['success'] == true) {
        final tokens = response.data['data'];
        await _secureStorage.write(key: AppConstants.tokenKey, value: tokens['accessToken']);
        await _secureStorage.write(key: AppConstants.refreshTokenKey, value: tokens['refreshToken']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 保存Token
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: accessToken);
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  /// 清除Token
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ==================== GET请求 ====================
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ==================== POST请求 ====================
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ==================== PUT请求 ====================
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ==================== DELETE请求 ====================
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
