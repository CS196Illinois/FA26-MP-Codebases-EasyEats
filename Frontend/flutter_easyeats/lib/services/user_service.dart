import 'storage_service.dart';

class UserService {
  static int? _currentUserId;
  static Map<String, dynamic>? _currentUserData;
  static String? _token;

  // Set current user and save to persistent storage.
  // Pass [token] after sign-in or sign-up. Leave it out when only the
  // profile data changed, and the existing token is kept.
  static Future<void> setCurrentUser(
    int userId,
    Map<String, dynamic>? userData, {
    String? token,
  }) async {
    _currentUserId = userId;
    if (token != null) _token = token;

    // Keep the token out of the profile data so it is only stored once
    if (userData != null) {
      userData = Map<String, dynamic>.of(userData)..remove('token');
    }
    _currentUserData = userData;

    // Save to persistent storage
    if (userData != null && _token != null) {
      await StorageService.saveUserSession(userId, userData, _token!);
    }
  }

  // Load user session from storage (call on app startup)
  static Future<bool> loadSavedSession() async {
    final session = await StorageService.getSavedSession();

    if (session != null) {
      _currentUserId = session['userId'];
      _currentUserData = session['userData'];
      _token = session['token'];
      return true;
    }

    return false;
  }

  static int? getCurrentUserId() {
    return _currentUserId;
  }

  static Map<String, dynamic>? getCurrentUserData() {
    return _currentUserData;
  }

  // The session token sent to the backend with every request
  static String? getToken() {
    return _token;
  }

  // Clear current user and remove from storage
  static Future<void> clearCurrentUser() async {
    _currentUserId = null;
    _currentUserData = null;
    _token = null;
    await StorageService.clearSession();
  }

  static bool isLoggedIn() {
    return _currentUserId != null && _token != null;
  }

  // Get current user with ID and data combined
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    // Try to load from memory first
    if (_currentUserId != null && _currentUserData != null) {
      return {
        'id': _currentUserId,
        ..._currentUserData!,
      };
    }

    // Try to load from storage
    if (await loadSavedSession()) {
      return {
        'id': _currentUserId,
        ..._currentUserData!,
      };
    }

    return null;
  }

  // Update stored user data when profile changes
  static Future<void> updateStoredUserData(Map<String, dynamic> userData) async {
    _currentUserData = userData;
    await StorageService.updateUserData(userData);
  }

  // Get days remaining in current session
  static Future<int> getSessionDaysRemaining() async {
    return await StorageService.getDaysRemaining();
  }
}
