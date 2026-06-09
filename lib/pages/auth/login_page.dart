import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

/// 登录页
/// 手机号+验证码登录，新用户自动注册
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  int _countdown = 60;
  bool _isCountingDown = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdown = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _isCountingDown = false;
        }
      });
      return _countdown > 0;
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的手机号')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.sendCode(phone);
    if (success && mounted) {
      setState(() => _codeSent = true);
      _startCountdown();
    }
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入6位验证码')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(phone, code);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(theme.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // 标题
              Text(
                '欢迎使用',
                style: TextStyle(
                  fontSize: theme.fontSizeH1,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '智能用药',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '登录后开始管理您的用药计划',
                style: TextStyle(
                  fontSize: theme.fontSizeBodySmall,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // 手机号输入
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  prefixIcon: Icon(Icons.phone_android, color: theme.primary),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),

              // 验证码输入
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: '验证码',
                        hintText: '请输入验证码',
                        prefixIcon: Icon(Icons.lock_outline, color: theme.primary),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: theme.inputHeight,
                    child: ElevatedButton(
                      onPressed: _isCountingDown ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.inputRadius),
                        ),
                      ),
                      child: Text(
                        _isCountingDown ? '${_countdown}s' : '获取验证码',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: theme.buttonHeight,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _login,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '登录',
                          style: TextStyle(
                            fontSize: theme.fontSizeButton,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 提示
              Center(
                child: Text(
                  '首次登录将自动创建账号',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
