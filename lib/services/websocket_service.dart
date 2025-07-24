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
  int? _currentConversationId;

  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal();

  Stream<Message> get messageStream {
    _messageController ??= StreamController<Message>.broadcast();
    return _messageController!.stream;
  }

  Stream<Map<String, dynamic>> get typingStream {
    _typingController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _typingController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // Use the corrected WebSocket URL with /ws path
      AppLogger.log('🔗 Connecting to WebSocket: $webSocketUrl');

      _channel = WebSocketChannel.connect(Uri.parse(webSocketUrl));

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
      AppLogger.log('🔍 Handling WebSocket message type: ${message['type']}');

      switch (message['type']) {
        case 'authenticated':
          AppLogger.log(
              '✅ WebSocket authenticated for user: ${message['user']['name']}');
          break;

        case 'new_message':
          AppLogger.log(
              '📨 WebSocket new message received: ${message['data']}');
          final messageData = Message.fromJson(message['data']);
          _messageController?.add(messageData);
          AppLogger.log('📤 WebSocket message broadcasted to all listeners');
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
          AppLogger.log('❓ Unknown WebSocket message type: ${message['type']}');
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
          AppLogger.log('❌ WebSocket reconnection failed: $e');
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
      AppLogger.log('🏠 WebSocket joined conversation: $conversationId');
    }
  }

  void leaveConversation() {
    if (_isConnected && _currentConversationId != null) {
      _send({
        'type': 'leave_conversation',
      });
      AppLogger.log('🚪 WebSocket left conversation: $_currentConversationId');
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
      AppLogger.log('❌ Cannot send WebSocket message: not connected');
    }
  }

  Future<void> disconnect() async {
    _typingTimer?.cancel();
    _isConnected = false;
    _currentConversationId = null;
    await _channel?.sink.close();
    _channel = null;
    AppLogger.log('✅ WebSocket disconnected');
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _typingController?.close();
    _messageController = null;
    _typingController = null;
  }
}
