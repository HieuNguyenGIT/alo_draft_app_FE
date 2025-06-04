import 'package:alo_draft_app/models/user_model.dart';
import 'package:alo_draft_app/services/api_service.dart';
import 'package:alo_draft_app/util/shared_preferences_helper.dart';

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
    await ApiService.clearToken();
    await SharedPreferencesHelper.clearUserData();
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }
}
