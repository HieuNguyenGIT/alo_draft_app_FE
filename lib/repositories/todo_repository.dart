import 'package:alo_draft_app/models/todo_model.dart';
import 'package:alo_draft_app/services/api_service.dart';

class TodoRepository {
  Future<List<Todo>> getTodos() async {
    try {
      final response = await ApiService.getTodos();
      return response.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load todos: $e');
    }
  }

  Future<Todo> createTodo(String title, String description) async {
    try {
      final response = await ApiService.createTodo(title, description);
      return Todo.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }

  Future<Todo> updateTodo(Todo todo) async {
    try {
      final response = await ApiService.updateTodo(
        todo.id,
        todo.title,
        todo.description,
        todo.isCompleted,
      );
      return Todo.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await ApiService.deleteTodo(id);
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }
}
