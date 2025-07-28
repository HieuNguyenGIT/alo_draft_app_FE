import 'dart:async';
import 'package:alo_draft_app/util/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:alo_draft_app/services/api_service.dart';
import 'package:alo_draft_app/models/message_model.dart';

class SocketIOService {
  static SocketIOService? _instance;
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  int? _currentConversationId;
  Timer? _typingTimer;
  Timer? _reconnectTimer;

  // Stream controllers for real-time data
  StreamController<Message>? _messageController;
  StreamController<Map<String, dynamic>>? _typingController;

  static SocketIOService get instance {
    _instance ??= SocketIOService._internal();
    return _instance!;
  }

  SocketIOService._internal();

  bool get isConnected => _isConnected && _isAuthenticated;

  // Streams for UI to listen to
  Stream<Message> get messageStream {
    _messageController ??= StreamController<Message>.broadcast();
    return _messageController!.stream;
  }

  Stream<Map<String, dynamic>> get typingStream {
    _typingController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _typingController!.stream;
  }

  // 🔥 CRITICAL FIX: Mobile-optimized connection
  Future<void> connect() async {
    if (_isConnected && _isAuthenticated) {
      AppLogger.log('🔌 Socket.IO already connected and authenticated');
      return;
    }

    try {
      // Get the auth token
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log('🌐 Socket.IO connecting to: $socketIOUrl');
      AppLogger.log('🔑 Using token: ${token.substring(0, 20)}...');

      // 🔥 CRITICAL FIX: Mobile-optimized configuration
      _socket = io.io(
          socketIOUrl,
          io.OptionBuilder()
              // 🔥 FIX: Start with polling for mobile compatibility
              .setTransports(['websocket'])

              // 🔥 FIX: Authentication setup
              .setAuth({'token': token})
              .setExtraHeaders({'authorization': 'Bearer $token'})

              // 🔥 FIX: Connection settings
              .enableAutoConnect()
              .enableReconnection()
              .setReconnectionAttempts(10)
              .setReconnectionDelay(1000)
              .setReconnectionDelayMax(5000)
              .setTimeout(20000)

              // 🔥 FIX: Force new connection
              .enableForceNew()
              .build());

      _setupEventHandlers();

      // Wait for connection with proper timeout
      await _waitForAuthentication();
    } catch (e) {
      AppLogger.log('❌ Socket.IO connection error: $e');
      rethrow;
    }
  }

  // 🔥 NEW: Proper authentication waiting
  Future<void> _waitForAuthentication({int timeoutSeconds = 15}) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;

    // Set up timeout
    timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
      if (!completer.isCompleted) {
        AppLogger.log('⏰ Authentication timeout after $timeoutSeconds seconds');
        completer.completeError('Authentication timeout');
      }
    });

    // Listen for authentication success
    void onAuthenticated() {
      timeoutTimer?.cancel();
      if (!completer.isCompleted) {
        AppLogger.log('✅ Authentication successful');
        completer.complete();
      }
    }

    void onError(dynamic error) {
      timeoutTimer?.cancel();
      if (!completer.isCompleted) {
        AppLogger.log('❌ Authentication failed: $error');
        completer.completeError('Authentication failed: $error');
      }
    }

    // Set up one-time listeners
    StreamSubscription? authSub;

    authSub = Stream.periodic(Duration(milliseconds: 100))
        .take(timeoutSeconds * 10)
        .listen((_) {
      if (_isAuthenticated) {
        authSub?.cancel();
        onAuthenticated();
      }
    });

    // Listen for errors
    _socket?.onConnectError((error) => onError(error));

    try {
      await completer.future;
    } finally {
      timeoutTimer.cancel();
      authSub.cancel();
    }
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    // 🔥 FIX: Connection events
    _socket!.onConnect((_) {
      AppLogger.log('✅ Socket.IO connected to server');
      _isConnected = true;
    });

    _socket!.onDisconnect((reason) {
      AppLogger.log('🔌 Socket.IO disconnected: $reason');
      _isConnected = false;
      _isAuthenticated = false;
      _currentConversationId = null;

      // 🔥 FIX: Auto-reconnect logic
      if (reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      AppLogger.log('❌ Socket.IO connection error: $error');
      _isConnected = false;
      _isAuthenticated = false;
      _scheduleReconnect();
    });

    // 🔥 FIX: Authentication events
    _socket!.on('authenticated', (data) {
      AppLogger.log('✅ Socket.IO authenticated: $data');
      _isAuthenticated = true;
      _cancelReconnectTimer();
    });

    // Handle authentication errors
    _socket!.on('connect_error', (error) {
      AppLogger.log('❌ Socket.IO authentication error: $error');
      _isAuthenticated = false;
    });

    // 🔥 FIX: Message handling
    _socket!.on('newMessage', (data) {
      AppLogger.log('📨 Received message: $data');
      try {
        final message = Message.fromJson(data as Map<String, dynamic>);
        _messageController?.add(message);
        AppLogger.log('📤 Message added to stream: ${message.content}');
      } catch (e) {
        AppLogger.log('❌ Error parsing message: $e');
        AppLogger.log('❌ Raw data: $data');
      }
    });

    // 🔥 FIX: Typing indicators
    _socket!.on('userTyping', (data) {
      AppLogger.log('⌨️ User typing: $data');
      _typingController?.add({
        'type': 'typing_start',
        'userId': data['userId'],
        'userName': data['userName'],
        'conversationId': data['conversationId'],
      });
    });

    _socket!.on('userStoppedTyping', (data) {
      AppLogger.log('⌨️ User stopped typing: $data');
      _typingController?.add({
        'type': 'typing_stop',
        'userId': data['userId'],
        'conversationId': data['conversationId'],
      });
    });

    // 🔥 FIX: Conversation events
    _socket!.on('joinedConversation', (data) {
      AppLogger.log('🏠 Joined conversation: $data');
    });

    _socket!.on('messageStatus', (data) {
      AppLogger.log('📤 Message status: $data');
    });

    // Error handling
    _socket!.on('error', (error) {
      AppLogger.log('❌ Socket.IO error: $error');
    });
  }

  // 🔥 NEW: Smart reconnection logic
  void _scheduleReconnect() {
    _cancelReconnectTimer();

    _reconnectTimer = Timer(Duration(seconds: 3), () {
      if (!_isConnected) {
        AppLogger.log('🔄 Attempting to reconnect...');
        connect().catchError((e) {
          AppLogger.log('❌ Reconnection failed: $e');
        });
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // 🔥 FIX: Enhanced conversation management
  void joinConversation(int conversationId) {
    if (!isConnected) {
      AppLogger.log('❌ Cannot join conversation: Not connected/authenticated');
      return;
    }

    // Leave current conversation if any
    if (_currentConversationId != null &&
        _currentConversationId != conversationId) {
      leaveConversation();
    }

    _currentConversationId = conversationId;
    _socket!.emit('joinConversation', conversationId);
    AppLogger.log('🏠 Joining conversation: $conversationId');
  }

  void leaveConversation() {
    if (!isConnected) return;

    if (_currentConversationId != null) {
      _socket!.emit('leaveConversation');
      AppLogger.log('🚪 Left conversation: $_currentConversationId');
      _currentConversationId = null;
    }
  }

  // 🔥 FIX: Message sending
  void sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
    String? temporaryId,
  }) {
    if (!isConnected) {
      AppLogger.log('❌ Cannot send message: Not connected/authenticated');
      return;
    }

    final messageData = {
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType,
      if (temporaryId != null) 'temporaryId': temporaryId,
    };

    _socket!.emit('sendMessage', messageData);
    AppLogger.log('📤 Message sent: $content');
  }

  // 🔥 FIX: Typing indicators
  void startTyping(int conversationId) {
    if (!isConnected) return;

    _socket!.emit('startTyping', conversationId);
    AppLogger.log('⌨️ Started typing in: $conversationId');

    // Auto-stop typing after 3 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(Duration(seconds: 3), () {
      stopTyping(conversationId);
    });
  }

  void stopTyping(int conversationId) {
    if (!isConnected) return;

    _socket!.emit('stopTyping', conversationId);
    _typingTimer?.cancel();
  }

  // 🔥 FIX: Test functionality
  void sendTestMessage(String message) {
    if (!isConnected) {
      AppLogger.log('❌ Cannot send test message: Not connected');
      return;
    }

    _socket!.emit('testMessage', {
      'content': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
    AppLogger.log('📤 Test message sent: $message');
  }

  // 🔥 FIX: Connection check
  bool checkConnection() {
    final socketConnected = _socket?.connected ?? false;
    final serviceConnected = _isConnected && _isAuthenticated;

    AppLogger.log('🔍 Connection status:');
    AppLogger.log('   Socket connected: $socketConnected');
    AppLogger.log('   Service connected: $_isConnected');
    AppLogger.log('   Authenticated: $_isAuthenticated');
    AppLogger.log('   Overall status: $serviceConnected');

    return serviceConnected;
  }

  // 🔥 FIX: Clean disconnect
  void disconnect() {
    AppLogger.log('🔌 Disconnecting Socket.IO...');

    _cancelReconnectTimer();
    _typingTimer?.cancel();

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
    _isAuthenticated = false;
    _currentConversationId = null;

    AppLogger.log('✅ Socket.IO disconnected');
  }

  // 🔥 FIX: Resource cleanup
  void dispose() {
    disconnect();
    _messageController?.close();
    _typingController?.close();
    _messageController = null;
    _typingController = null;
    AppLogger.log('♻️ Socket.IO service disposed');
  }
}
