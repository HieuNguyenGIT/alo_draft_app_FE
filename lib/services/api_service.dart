import 'dart:convert';
import 'package:alo_draft_app/util/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Store token
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Clear token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Register user
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await storeToken(data['token']);
    }

    return data;
  }

  // Login user
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await storeToken(data['token']);
    }

    return data;
  }

  // Get all todos
  static Future<List<dynamic>> getTodos() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/todos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load todos');
    }
  }

  // Create a todo
  static Future<Map<String, dynamic>> createTodo(
      String title, String description) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/todos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create todo');
    }
  }

  // Update a todo
  static Future<Map<String, dynamic>> updateTodo(
      int id, String title, String description, bool isCompleted) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/todos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'is_completed': isCompleted ? 1 : 0,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update todo');
    }
  }

  // Delete a todo
  static Future<void> deleteTodo(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/todos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo');
    }
  }
}
