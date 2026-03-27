// screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  String _username = 'Guest';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final u = await _auth.username;
    setState(() {
      _username = u ?? 'Guest';
    });
  }

  void _logout() async {
    await _auth.logout();
    // after logout, navigate back to login
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 40, child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'G', style: const TextStyle(fontSize: 28))),
        const SizedBox(height: 12),
        Text(_username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Đăng xuất')),
      ]),
    );
  }
}
