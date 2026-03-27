// screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _checkLogin);
  }

  void _checkLogin() async {
    final logged = await _auth.isLoggedIn();
    if (logged) {
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } else {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// ⭐ NỀN TRỐNG ĐỒNG (mờ 15%)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                "assets/images/dongson_pattern.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// ⭐ LỚP PHỦ MÀU NÂU ĐẤT NHẸ – tạo chất lịch sử
          Container(
            color: const Color(0xFF5C4631).withOpacity(0.12),
          ),

          /// ⭐ LOGO TRUNG TÂM
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(22),

                    /// ⭐ Viền vàng nhẹ để tăng cảm giác lịch sử
                    border: Border.all(
                      color: const Color(0xFFFFE4A6),
                      width: 3,
                    ),

                    /// ⭐ Bóng nhẹ cho nổi bật nhưng không quá hiện đại
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SỬ VIỆT',
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// ⭐ Slogan phong cách lịch sử
                Text(
                  'Học sử dễ nhớ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.brown.shade900,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
