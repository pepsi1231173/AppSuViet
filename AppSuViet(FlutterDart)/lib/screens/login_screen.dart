// screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _auth = AuthService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty) {
      setState(() => _error = 'Nhập tên người dùng');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await _auth.loginLocal(username, password);
      if (ok) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else {
        setState(() => _error = 'Đăng nhập không thành công');
      }
    } catch (e) {
      setState(() => _error = 'Lỗi: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _continueWithoutLogin() {
    _auth.loginLocal('guest', '').then((_) {
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Tên đăng nhập')),
            const SizedBox(height: 8),
            TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? const CircularProgressIndicator() : const Text('Đăng nhập')),
            const SizedBox(height: 8),
            TextButton(onPressed: _continueWithoutLogin, child: const Text('Bắt đầu không đăng nhập')),
          ],
        ),
      ),
    );
  }
}
