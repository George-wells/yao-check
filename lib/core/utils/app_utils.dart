import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 通用工具类
class AppUtils {
  AppUtils._();

  /// 检查网络连接
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// 显示SnackBar
  static void showSnackBar(BuildContext context, String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 显示成功SnackBar
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  /// 显示错误SnackBar
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  /// 显示加载对话框
  static void showLoadingDialog(BuildContext context, {String message = '加载中...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// 显示确认对话框
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确认',
    String cancelText = '取消',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 生成唯一ID（临时方案，生产环境使用服务端UUID）
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 防抖
  static Debounce debounce(Duration duration, VoidCallback callback) {
    return Debounce(duration, callback);
  }
}

/// 防抖工具类
class Debounce {
  final Duration duration;
  final VoidCallback callback;
  DateTime? _lastCall;

  Debounce(this.duration, this.callback);

  void call() {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= duration) {
      _lastCall = now;
      callback();
    }
  }
}
