import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_service.dart';

/// Sends requests to the backend with the signed-in user's token attached
/// ("Authorization: Bearer <token>"). Use it for every route that belongs to
/// one user (/api/user/..., /api/recommendations/...).
///
/// If the server replies 401 (token missing, expired or revoked), the saved
/// session is cleared and [onUnauthorized] is called so the app can send the
/// user back to the sign-in screen.
class ApiClient {
  /// Set in main.dart.
  static VoidCallback? onUnauthorized;

  static Map<String, String> _headers() {
    final token = UserService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(Uri uri) =>
      _send(() => http.get(uri, headers: _headers()));

  static Future<http.Response> post(Uri uri, {Object? body}) =>
      _send(() => http.post(uri, headers: _headers(), body: body));

  static Future<http.Response> put(Uri uri, {Object? body}) =>
      _send(() => http.put(uri, headers: _headers(), body: body));

  static Future<http.Response> delete(Uri uri) =>
      _send(() => http.delete(uri, headers: _headers()));

  static Future<http.Response> _send(
      Future<http.Response> Function() request) async {
    final response = await request();

    // Only react once, even if several requests fail at the same time
    if (response.statusCode == 401 && UserService.isLoggedIn()) {
      await UserService.clearCurrentUser();
      onUnauthorized?.call();
    }

    return response;
  }
}
