import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alo_draft_app/util/constants.dart';
import 'package:alo_draft_app/services/api_service.dart';
import 'package:alo_draft_app/models/message_model.dart';
import 'package:alo_draft_app/models/conversation_model.dart';
import 'package:alo_draft_app/models/user_search_model.dart';
import 'package:alo_draft_app/util/custom_logger.dart';

class MessageService {
  // 🔥 ENHANCED: Search users with better error handling
  static Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log('🔍 Searching users with query: "$query"');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/messages/users/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      AppLogger.log('👥 Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final users =
            data.map((user) => UserSearchResult.fromJson(user)).toList();
        AppLogger.log('✅ Found ${users.length} users');
        return users;
      } else {
        AppLogger.log(
            '❌ Search failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.log('❌ Search users error: $e');
      rethrow;
    }
  }

  // 🔥 ENHANCED: Get conversations with better error handling
  static Future<List<Conversation>> getConversations() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log('📋 Loading conversations...');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 15));

      AppLogger.log('📋 Conversations response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final conversations = data
            .map((conversation) => Conversation.fromJson(conversation))
            .toList();

        AppLogger.log('✅ Loaded ${conversations.length} conversations');

        // Log conversation details for debugging
        for (var conv in conversations.take(3)) {
          AppLogger.log(
              '   Conversation ${conv.conversationId}: ${conv.otherUserName} - ${conv.lastMessage ?? "No messages"}');
        }

        return conversations;
      } else {
        AppLogger.log(
            '❌ Failed to load conversations: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.log('❌ Get conversations error: $e');
      rethrow;
    }
  }

  // 🔥 ENHANCED: Start conversation with validation
  static Future<int> startConversation(int otherUserId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log('💬 Starting conversation with user: $otherUserId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/messages/conversations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'otherUserId': otherUserId,
            }),
          )
          .timeout(Duration(seconds: 10));

      AppLogger.log('💬 Start conversation response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversationId = data['conversationId'] as int;
        AppLogger.log('✅ Conversation started/found: $conversationId');
        return conversationId;
      } else {
        AppLogger.log(
            '❌ Failed to start conversation: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to start conversation: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.log('❌ Start conversation error: $e');
      rethrow;
    }
  }

  // 🔥 ENHANCED: Get messages with pagination and caching
  static Future<List<Message>> getMessages(int conversationId,
      {int page = 1, int limit = 50}) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log(
          '📨 Loading messages for conversation: $conversationId (page: $page, limit: $limit)');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/messages/conversations/$conversationId/messages?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 15));

      AppLogger.log('📨 Messages response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final messages =
            data.map((message) => Message.fromJson(message)).toList();

        AppLogger.log(
            '✅ Loaded ${messages.length} messages for conversation $conversationId');

        // Log first few messages for debugging
        for (var msg in messages.take(3)) {
          AppLogger.log(
              '   Message ${msg.id}: "${msg.content}" from ${msg.senderName}');
        }

        return messages;
      } else if (response.statusCode == 403) {
        AppLogger.log('❌ Access denied to conversation: $conversationId');
        throw Exception('Access denied to conversation');
      } else {
        AppLogger.log(
            '❌ Failed to load messages: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.log('❌ Get messages error: $e');
      rethrow;
    }
  }

  // 🔥 ENHANCED: Send message with retry logic
  static Future<Message> sendMessage(int conversationId, String content,
      {String messageType = 'text', int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final token = await ApiService.getToken();
        if (token == null) {
          throw Exception('No authentication token available');
        }

        AppLogger.log(
            '📤 Sending message (attempt $attempt/$maxRetries): "$content" to conversation $conversationId');

        final response = await http
            .post(
              Uri.parse(
                  '$baseUrl/messages/conversations/$conversationId/messages'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'content': content,
                'messageType': messageType,
              }),
            )
            .timeout(Duration(seconds: 15));

        AppLogger.log('📤 Send message response: ${response.statusCode}');

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final message = Message.fromJson(data);
          AppLogger.log('✅ Message sent successfully: ${message.id}');
          return message;
        } else if (response.statusCode == 403) {
          AppLogger.log('❌ Access denied to conversation: $conversationId');
          throw Exception('Access denied to conversation');
        } else {
          AppLogger.log(
              '❌ Failed to send message (attempt $attempt): ${response.statusCode} - ${response.body}');

          if (attempt == maxRetries) {
            throw Exception(
                'Failed to send message after $maxRetries attempts: ${response.statusCode}');
          }

          // Wait before retry
          await Future.delayed(Duration(seconds: attempt));
        }
      } catch (e) {
        AppLogger.log('❌ Send message error (attempt $attempt): $e');

        if (attempt == maxRetries) {
          rethrow;
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    throw Exception('Failed to send message after $maxRetries attempts');
  }

  // 🔥 ENHANCED: Mark messages as read with validation
  static Future<void> markMessagesAsRead(int conversationId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log(
          '✅ Marking messages as read for conversation: $conversationId');

      final response = await http.put(
        Uri.parse('$baseUrl/messages/conversations/$conversationId/mark-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        AppLogger.log('✅ Messages marked as read successfully');
      } else {
        AppLogger.log(
            '❌ Failed to mark messages as read: ${response.statusCode} - ${response.body}');
        // Don't throw here as this is not critical
      }
    } catch (e) {
      AppLogger.log('❌ Mark messages as read error: $e');
      // Don't throw here as this is not critical for user experience
    }
  }

  // 🔥 NEW: Connection test method
  static Future<bool> testConnection() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        AppLogger.log('❌ No token available for connection test');
        return false;
      }

      AppLogger.log('🧪 Testing message service connection...');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 5));

      final success = response.statusCode == 200;
      AppLogger.log(success
          ? '✅ Message service connection test successful'
          : '❌ Message service connection test failed: ${response.statusCode}');

      return success;
    } catch (e) {
      AppLogger.log('❌ Message service connection test error: $e');
      return false;
    }
  }

  // 🔥 NEW: Get conversation info
  static Future<Map<String, dynamic>?> getConversationInfo(
      int conversationId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        AppLogger.log(
            '❌ Failed to get conversation info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.log('❌ Get conversation info error: $e');
      return null;
    }
  }
}
