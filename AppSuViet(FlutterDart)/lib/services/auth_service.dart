// services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _keyUsername = 'sv_username';
  static const String _keyToken = 'sv_token';

  final ApiService _api = ApiService();

  Future<bool> loginLocal(String username, String password) async {
    // Tùy: nếu bạn có api, gọi api login ở đây
    try {
      final res = await _api.login(username, password);
      // Giả sử API trả {'token': '...', 'displayName': '...'}
      final prefs = await SharedPreferences.getInstance();
      if (res.containsKey('token')) {
        await prefs.setString(_keyUsername, username);
        await prefs.setString(_keyToken, res['token'].toString());
        return true;
      } else {
        // nếu API trả user object mà không có token
        await prefs.setString(_keyUsername, username);
        return true;
      }
    } catch (e) {
      // Nếu muốn cho phép login offline: lưu username
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsername, username);
      return true;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyToken);
  }

  Future<String?> get username async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUsername);
  }
}
