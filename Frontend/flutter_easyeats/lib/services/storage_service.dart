import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _loginTimeKey = 'login_time';
  static const String _tokenKey = 'session_token';
  static const int _sessionDurationDays = 7; // Stay logged in for 7 days (matches the server)

  // Save user login session
  static Future<void> saveUserSession(
      int userId, Map<String, dynamic> userData, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userDataKey, json.encode(userData));
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Check if session is still valid
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);

    if (loginTime == null) return false;

    final sessionStart = DateTime.fromMillisecondsSinceEpoch(loginTime);
    final now = DateTime.now();
    final difference = now.difference(sessionStart);

    return difference.inDays < _sessionDurationDays;
  }

  // Get saved user session
  static Future<Map<String, dynamic>?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if session is valid
    if (!await isSessionValid()) {
      await clearSession();
      return null;
    }

    final userId = prefs.getInt(_userIdKey);
    final userDataString = prefs.getString(_userDataKey);
    final token = prefs.getString(_tokenKey);

    // Sessions saved before tokens existed have no token: sign in again
    if (userId == null || userDataString == null || token == null) {
      return null;
    }

    try {
      final userData = json.decode(userDataString);
      return {
        'userId': userId,
        'userData': userData,
        'token': token,
      };
    } catch (e) {
      return null;
    }
  }

  // Clear saved session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_tokenKey);
  }

  // Update stored user data (when profile is updated)
  static Future<void> updateUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(userData));
  }

  // Get days remaining in session
  static Future<int> getDaysRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);

    if (loginTime == null) return 0;

    final sessionStart = DateTime.fromMillisecondsSinceEpoch(loginTime);
    final now = DateTime.now();
    final difference = now.difference(sessionStart);

    return _sessionDurationDays - difference.inDays;
  }
}
