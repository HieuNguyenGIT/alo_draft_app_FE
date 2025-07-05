import 'dart:async';
import 'dart:convert';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:alo_draft_app/util/constants.dart';
import 'package:alo_draft_app/services/api_service.dart';
import 'package:alo_draft_app/models/message_model.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<Message>? _messageController;
  StreamController<Map<String, dynamic>>? _typingController;
  bool _isConnected = false;
  Timer? _typingTimer;
  int? _currentConversationId; // Track current conversation

  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal();

  // Stream for receiving new messages
  Stream<Message> get messageStream {
    _messageController ??= StreamController<Message>.broadcast();
    return _messageController!.stream;
  }

  // Stream for typing indicators
  Stream<Map<String, dynamic>> get typingStream {
    _typingController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _typingController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // Use the corrected WebSocket URL from constants
      final wsUrl = baseUrl.replaceFirst('http', 'ws').replaceFirst('/api', '');

      AppLogger.log('🔗 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for connection to be established
      await Future.delayed(const Duration(milliseconds: 500));

      _isConnected = true;

      // Authenticate immediately after connection
      final token = await ApiService.getToken();
      if (token != null) {
        _send({
          'type': 'authenticate',
          'token': token,
        });
        AppLogger.log('🔐 Authentication message sent');
      }

      // Listen to messages
      _channel!.stream.listen(
        (data) {
          AppLogger.log('📥 WebSocket received: $data');
          _handleMessage(data);
        },
        onError: (error) {
          AppLogger.log('❌ WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          AppLogger.log('🔌 WebSocket connection closed');
          _handleDisconnection();
        },
      );

      AppLogger.log('✅ WebSocket connected successfully');
    } catch (e) {
      AppLogger.log('❌ Failed to connect WebSocket: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      AppLogger.log('🔍 Handling message type: ${message['type']}');

      switch (message['type']) {
        case 'authenticated':
          AppLogger.log(
              '✅ WebSocket authenticated for user: ${message['user']['name']}');
          break;

        case 'new_message':
          AppLogger.log('📨 New message received: ${message['data']}');
          final messageData = Message.fromJson(message['data']);

          // FIXED: Always broadcast messages to ALL listeners
          // Both the chat screen AND the conversation list need to receive messages
          _messageController?.add(messageData);
          AppLogger.log(
              '📤 Message broadcasted to all listeners (chat screen + conversation list)');
          break;

        case 'user_typing':
          _typingController?.add({
            'type': 'typing_start',
            'userId': message['userId'],
            'userName': message['userName'],
            'conversationId': message['conversationId'],
          });
          break;

        case 'user_stopped_typing':
          _typingController?.add({
            'type': 'typing_stop',
            'userId': message['userId'],
            'conversationId': message['conversationId'],
          });
          break;

        case 'error':
          AppLogger.log('❌ WebSocket error: ${message['message']}');
          break;

        default:
          AppLogger.log('❓ Unknown message type: ${message['type']}');
      }
    } catch (e) {
      AppLogger.log('❌ Error parsing WebSocket message: $e');
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _channel = null;
    _currentConversationId = null;

    // Try to reconnect after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (!_isConnected) {
        AppLogger.log('🔄 Attempting to reconnect WebSocket...');
        connect().catchError((e) {
          AppLogger.log('❌ Reconnection failed: $e');
        });
      }
    });
  }

  void joinConversation(int conversationId) {
    _currentConversationId = conversationId;
    if (_isConnected) {
      _send({
        'type': 'join_conversation',
        'conversationId': conversationId,
      });
      AppLogger.log('🏠 Joined conversation: $conversationId');
    }
  }

  void leaveConversation() {
    if (_isConnected && _currentConversationId != null) {
      _send({
        'type': 'leave_conversation',
      });
      AppLogger.log('🚪 Left conversation: $_currentConversationId');
    }
    _currentConversationId = null;
  }

  void startTyping(int conversationId) {
    if (_isConnected) {
      _send({
        'type': 'typing_start',
        'conversationId': conversationId,
      });

      // Auto-stop typing after 3 seconds
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        stopTyping(conversationId);
      });
    }
  }

  void stopTyping(int conversationId) {
    if (_isConnected) {
      _send({
        'type': 'typing_stop',
        'conversationId': conversationId,
      });
      _typingTimer?.cancel();
    }
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      final jsonData = jsonEncode(data);
      AppLogger.log('📤 Sending WebSocket message: $jsonData');
      _channel!.sink.add(jsonData);
    } else {
      AppLogger.log('❌ Cannot send message: WebSocket not connected');
    }
  }

  Future<void> disconnect() async {
    _typingTimer?.cancel();
    _isConnected = false;
    _currentConversationId = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _typingController?.close();
    _messageController = null;
    _typingController = null;
  }
}
