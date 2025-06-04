import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alo_draft_app/util/constants.dart';
import 'package:alo_draft_app/services/api_service.dart';
import 'package:alo_draft_app/models/message_model.dart';
import 'package:alo_draft_app/models/conversation_model.dart';
import 'package:alo_draft_app/models/user_search_model.dart';

class MessageService {
  // Search users
  static Future<List<UserSearchResult>> searchUsers(String query) async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse(
          '$baseUrl/messages/users/search?query=${Uri.encodeComponent(query)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((user) => UserSearchResult.fromJson(user)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  // Get all conversations
  static Future<List<Conversation>> getConversations() async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((conversation) => Conversation.fromJson(conversation))
          .toList();
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  // Start conversation with user
  static Future<int> startConversation(int otherUserId) async {
    final token = await ApiService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'otherUserId': otherUserId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['conversationId'];
    } else {
      throw Exception('Failed to start conversation');
    }
  }

  // Get messages for conversation
  static Future<List<Message>> getMessages(int conversationId,
      {int page = 1, int limit = 50}) async {
    final token = await ApiService.getToken();
    final response = await http.get(
      Uri.parse(
          '$baseUrl/messages/conversations/$conversationId/messages?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((message) => Message.fromJson(message)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // Send message
  static Future<Message> sendMessage(int conversationId, String content) async {
    final token = await ApiService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'content': content,
        'messageType': 'text',
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Message.fromJson(data);
    } else {
      throw Exception('Failed to send message');
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(int conversationId) async {
    final token = await ApiService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/mark-read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark messages as read');
    }
  }
}
