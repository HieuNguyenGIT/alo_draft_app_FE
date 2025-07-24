import 'dart:async';
import 'package:alo_draft_app/util/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:alo_draft_app/services/api_service.dart';

class SocketIOService {
  static SocketIOService? _instance;

  // 🔥 FIXED: Properly declare all class variables
  io.Socket? _socket; // This was missing!
  bool _isConnected = false;
  bool _isAuthenticated = false;
  bool _isTestMode = false;

  static SocketIOService get instance {
    _instance ??= SocketIOService._internal();
    return _instance!;
  }

  SocketIOService._internal();

  bool get isConnected => _isConnected && (_isAuthenticated || _isTestMode);

  // FIXED: Connect with authentication
  Future<void> connect() async {
    if (_isConnected) {
      AppLogger.log('🔌 Socket.IO already connected');
      return;
    }

    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log('🌐 Socket.IO connecting to: $socketIOUrl (WITH AUTH)');

      // 🔥 FIXED: Matching timeouts with server
      _socket = io.io(
          socketIOUrl,
          io.OptionBuilder()
              .setTransports(['polling', 'websocket']) // Try polling first
              .enableReconnection()
              .setReconnectionAttempts(3)
              .setReconnectionDelay(2000)

              // 🔥 CRITICAL: Match server timeout settings
              .setTimeout(15000) // Increased from 10000 to 15000

              .enableForceNew()
              .disableAutoConnect()
              .setAuth({'token': token})
              .build());

      _isTestMode = false;
      _setupEventHandlers();

      // Manual connect for auth mode
      _socket!.connect();

      AppLogger.log('🔗 Socket.IO connection initiated (AUTH MODE)...');

      // Wait for connection with longer timeout
      await _waitForConnection(timeout: 15000);
    } catch (e) {
      AppLogger.log('❌ Socket.IO connection error: $e');
      _cleanup();
      rethrow;
    }
  }

  // FIXED: Test connection method
  Future<void> connectTest() async {
    if (_isConnected) {
      AppLogger.log('🔌 Socket.IO already connected');
      return;
    }

    try {
      AppLogger.log(
          '🌐 Socket.IO connecting to: $socketIOUrl (TEST MODE - NO AUTH)');

      // 🔥 FIXED: Better test configuration with matching timeouts
      _socket = io.io(
          socketIOUrl,
          io.OptionBuilder()
              .setTransports(['polling']) // Start with polling only for test
              .enableReconnection()
              .setReconnectionAttempts(2)
              .setReconnectionDelay(1000)

              // 🔥 CRITICAL: Match server settings
              .setTimeout(15000) // Match server expectations

              .enableForceNew()
              .disableAutoConnect()
              // NO auth for test mode
              .build());

      _isTestMode = true;
      _setupEventHandlers();
      _socket!.connect();

      AppLogger.log('🔗 Socket.IO connection initiated (TEST MODE)...');

      // Wait for connection
      await _waitForConnection(timeout: 15000);
    } catch (e) {
      AppLogger.log('❌ Socket.IO test connection error: $e');
      _cleanup();
      rethrow;
    }
  }

  // UPDATED: Wait for connection helper with configurable timeout
  Future<void> _waitForConnection({int timeout = 15000}) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;

    // Set up timeout
    timeoutTimer = Timer(Duration(milliseconds: timeout), () {
      if (!completer.isCompleted) {
        completer.completeError('Connection timeout after ${timeout}ms');
      }
    });

    // Listen for connection events
    _socket!.onConnect((_) {
      timeoutTimer?.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    _socket!.onConnectError((error) {
      timeoutTimer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError('Connection error: $error');
      }
    });

    return completer.future;
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      AppLogger.log('✅ Socket.IO connected to server');
      _isConnected = true;
      if (_isTestMode) {
        AppLogger.log('🧪 Connected in TEST MODE');
        _isAuthenticated =
            true; // For test mode, consider authenticated immediately
      }
    });

    _socket!.onDisconnect((reason) {
      AppLogger.log('🔌 Socket.IO disconnected: $reason');
      _isConnected = false;
      _isAuthenticated = false;
    });

    _socket!.onConnectError((error) {
      AppLogger.log('❌ Socket.IO connection error: $error');
      _isConnected = false;
      _isAuthenticated = false;
    });

    // Handle timeout specifically
    _socket!.on('connect_timeout', (_) {
      AppLogger.log('⏰ Socket.IO connection timeout');
      _isConnected = false;
      _isAuthenticated = false;
    });

    // TEST MODE: Server sends 'connected' instead of 'authenticated'
    _socket!.on('connected', (data) {
      AppLogger.log('🧪 Socket.IO test connection confirmed: $data');
      _isAuthenticated = true;
    });

    // AUTH MODE: Server sends 'authenticated'
    _socket!.on('authenticated', (data) {
      AppLogger.log('✅ Socket.IO authenticated successfully: $data');
      _isAuthenticated = true;
    });

    _socket!.on('connect_error', (error) {
      AppLogger.log('❌ Socket.IO authentication failed: $error');
      _isAuthenticated = false;
    });

    // Message received
    _socket!.on('newMessage', (data) {
      AppLogger.log('📨 Socket.IO message received: $data');
    });

    // Test response
    _socket!.on('testResponse', (data) {
      AppLogger.log('🧪 Socket.IO test response: $data');
    });

    // Conversation joined confirmation
    _socket!.on('joinedConversation', (data) {
      AppLogger.log('🏠 Socket.IO joined conversation: $data');
    });

    // Message status updates
    _socket!.on('messageStatus', (data) {
      AppLogger.log('📤 Socket.IO message status: $data');
    });

    // Typing indicators
    _socket!.on('userTyping', (data) {
      AppLogger.log('⌨️ Socket.IO user typing: $data');
    });

    _socket!.on('userStoppedTyping', (data) {
      AppLogger.log('⌨️ Socket.IO user stopped typing: $data');
    });

    // General error handling
    _socket!.on('error', (error) {
      AppLogger.log('❌ Socket.IO error: $error');
    });

    // Reconnection events
    _socket!.on('reconnect', (attemptNumber) {
      AppLogger.log('🔄 Socket.IO reconnected after $attemptNumber attempts');
    });

    _socket!.on('reconnect_attempt', (attemptNumber) {
      AppLogger.log('🔄 Socket.IO reconnection attempt $attemptNumber');
    });

    _socket!.on('reconnect_failed', (_) {
      AppLogger.log('❌ Socket.IO reconnection failed');
    });
  }

  // Test method that works in both modes
  void sendTestMessage(String message) {
    if (!isConnected) {
      AppLogger.log(
          '❌ Cannot send test message: Socket not connected or authenticated');
      return;
    }

    try {
      if (_isTestMode) {
        // Use 'test' event for test mode
        _socket!.emit('test', {
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
        AppLogger.log('📤 Test message sent (test mode): $message');
      } else {
        // Use 'testMessage' event for authenticated mode
        _socket!.emit('testMessage', {
          'content': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
        AppLogger.log('📤 Test message sent (auth mode): $message');
      }
    } catch (e) {
      AppLogger.log('❌ Error sending test message: $e');
    }
  }

  // Join a conversation (only works in authenticated mode)
  void joinConversation(int conversationId) {
    if (!isConnected) {
      AppLogger.log('❌ Cannot join conversation: Socket not connected');
      return;
    }

    if (_isTestMode) {
      AppLogger.log(
          '❌ Cannot join conversation: Test mode does not support conversations');
      return;
    }

    _socket!.emit('joinConversation', conversationId);
    AppLogger.log('🏠 Joining conversation: $conversationId');
  }

  // Send a real message (only works in authenticated mode)
  void sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
    String? temporaryId,
  }) {
    if (!isConnected) {
      AppLogger.log('❌ Cannot send message: Socket not connected');
      return;
    }

    if (_isTestMode) {
      AppLogger.log(
          '❌ Cannot send message: Test mode does not support real messages');
      return;
    }

    _socket!.emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType,
      if (temporaryId != null) 'temporaryId': temporaryId,
    });

    AppLogger.log('📤 Message sent to conversation $conversationId: $content');
  }

  // Typing indicators (only works in authenticated mode)
  void startTyping(int conversationId) {
    if (!isConnected || _isTestMode) return;
    _socket!.emit('startTyping', conversationId);
  }

  void stopTyping(int conversationId) {
    if (!isConnected || _isTestMode) return;
    _socket!.emit('stopTyping', conversationId);
  }

  void _cleanup() {
    _isConnected = false;
    _isAuthenticated = false;
    _isTestMode = false;
  }

  void disconnect() {
    if (_socket != null) {
      AppLogger.log('🔌 Disconnecting Socket.IO...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _cleanup();
    AppLogger.log('✅ Socket.IO disconnected');
  }

  void dispose() {
    disconnect();
  }
}
