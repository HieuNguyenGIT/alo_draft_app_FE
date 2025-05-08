import 'package:alo_draft_app/models/user_model.dart';
import 'package:alo_draft_app/services/api_service.dart';

class AuthRepository {
  Future<User> register(String name, String email, String password) async {
    try {
      final response = await ApiService.register(name, email, password);
      return User.fromJson(response['user'], response['token']);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      return User.fromJson(response['user'], response['token']);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }
}
