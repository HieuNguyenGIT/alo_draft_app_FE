import 'package:alo_draft_app/models/user_model.dart';
import 'package:alo_draft_app/services/api_service.dart';
import 'package:alo_draft_app/util/shared_preferences_helper.dart';
import 'package:alo_draft_app/services/websocket_service.dart';
import 'package:alo_draft_app/util/custom_logger.dart';

class AuthRepository {
  Future<User> register(String name, String email, String password) async {
    final response = await ApiService.register(name, email, password);

    if (response['message'] != null && response['token'] != null) {
      final user = User.fromJson(response['user'], response['token']);

      // Save user data to SharedPreferences
      await SharedPreferencesHelper.saveUserData(
          response['user'], response['token']);

      return user;
    } else {
      throw Exception(response['message'] ?? 'Registration failed');
    }
  }

  Future<User> login(String email, String password) async {
    final response = await ApiService.login(email, password);

    if (response['message'] != null && response['token'] != null) {
      final user = User.fromJson(response['user'], response['token']);

      // Save user data to SharedPreferences
      await SharedPreferencesHelper.saveUserData(
          response['user'], response['token']);

      return user;
    } else {
      throw Exception(response['message'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    AppLogger.log("🔄 Starting logout process...");

    // 🔥 CRITICAL: Disconnect WebSocket first
    AppLogger.log("🔌 Disconnecting WebSocket...");
    await WebSocketService.instance.disconnect();

    // Clear API token
    AppLogger.log("🗑️ Clearing API token...");
    await ApiService.clearToken();

    // Clear user data from SharedPreferences
    AppLogger.log("🗑️ Clearing user data...");
    await SharedPreferencesHelper.clearUserData();

    AppLogger.log("✅ Logout process completed");
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }
}
