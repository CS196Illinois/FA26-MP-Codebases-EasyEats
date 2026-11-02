import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'user_service.dart';

class AuthService {
  // Change this to your computer's IP address when testing on a physical device
  // For emulator, localhost or 10.0.2.2 works
  static const String baseUrl = 'http://localhost:3000/api';

  // Register a new user
  static Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile(
    int userId,
    String? goal,
    int? age,
    String? sex,
    int? calories, {
    List<String>? dietaryRestrictions,
    bool? notificationsEnabled,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (goal != null) body['goal'] = goal;
      if (age != null) body['age'] = age;
      if (sex != null) body['sex'] = sex;
      if (calories != null) body['calories'] = calories;
      if (dietaryRestrictions != null) body['dietary_restrictions'] = dietaryRestrictions;
      if (notificationsEnabled != null) body['notifications_enabled'] = notificationsEnabled;

      final response = await ApiClient.put(
        Uri.parse('$baseUrl/user/$userId/profile'),
        body: json.encode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Profile update failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/user/$userId/profile'),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Change password. The server keeps this device signed in and signs out
  // every other device.
  static Future<Map<String, dynamic>> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/user/$userId/change-password'),
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to change password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Log out: tell the server to delete this device's token. Uses plain http
  // (not ApiClient) because a 401 here just means the token was already gone.
  static Future<void> logout() async {
    final token = UserService.getToken();
    if (token == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      // Server unreachable: still sign out on this device
    }
  }
}
