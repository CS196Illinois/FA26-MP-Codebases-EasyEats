import 'dart:convert';
import 'package:http/http.dart' as http;

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

      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
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

  // Add a food to the user's favorites. On success, 'favorites' is the updated list.
  static Future<Map<String, dynamic>> addFavorite(int userId, String foodName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/$userId/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'foodItem': foodName}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'favorites': data['favorites'] ?? []};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to add favorite'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Remove the favorite at [index]. On success, 'favorites' is the updated list.
  static Future<Map<String, dynamic>> removeFavorite(int userId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId/favorites/$index'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'favorites': data['favorites'] ?? []};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to remove favorite'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
