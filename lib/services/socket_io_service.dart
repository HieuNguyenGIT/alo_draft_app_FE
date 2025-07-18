import 'dart:async';
import 'package:alo_draft_app/util/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:alo_draft_app/services/api_service.dart';

class SocketIOService {
  static SocketIOService? _instance;
  io.Socket? _socket;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  bool _isTestMode = false;

  static SocketIOService get instance {
    _instance ??= SocketIOService._internal();
    return _instance!;
  }

  SocketIOService._internal();

  bool get isConnected => _isConnected && (_isAuthenticated || _isTestMode);

  // EXISTING METHOD: Connect with authentication
  Future<void> connect() async {
    if (_isConnected) {
      AppLogger.log('🔌 Socket.IO already connected');
      return;
    }

    try {
      // Get the auth token
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      AppLogger.log('🌐 Socket.IO connecting to: $socketIOUrl (WITH AUTH)');

      _socket = io.io(
          socketIOUrl,
          io.OptionBuilder()
              .setTransports(['polling']) // Start with polling only for testing
              .enableReconnection()
              .setReconnectionAttempts(3)
              .setReconnectionDelay(1000)
              .setTimeout(30000) // Increase timeout
              .enableForceNew()
              .setAuth({'token': token}) // for auth mode
              .build());
      _isTestMode = false;
      _setupEventHandlers();
      _socket!.connect();

      AppLogger.log('🔗 Socket.IO connection initiated (AUTH MODE)...');
    } catch (e) {
      AppLogger.log('❌ Socket.IO connection error: $e');
      rethrow;
    }
  }

  // NEW METHOD: Connect without authentication for testing
  Future<void> connectTest() async {
    if (_isConnected) {
      AppLogger.log('🔌 Socket.IO already connected');
      return;
    }

    try {
      AppLogger.log(
          '🌐 Socket.IO connecting to: $socketIOUrl (TEST MODE - NO AUTH)');

      _socket = io.io(
          socketIOUrl,
          io.OptionBuilder()
              .setTransports(['polling']) // Start with polling only
              .enableReconnection()
              .setReconnectionAttempts(3)
              .setReconnectionDelay(1000)
              .setTimeout(30000) // Increase timeout
              .enableForceNew()
              // NO auth for test mode
              .build());
      _isTestMode = true;
      _setupEventHandlers();
      _socket!.connect();

      AppLogger.log('🔗 Socket.IO connection initiated (TEST MODE)...');
    } catch (e) {
      AppLogger.log('❌ Socket.IO connection error: $e');
      rethrow;
    }
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      AppLogger.log('✅ Socket.IO connected to server');
      _isConnected = true;
      if (_isTestMode) {
        AppLogger.log('🧪 Connected in TEST MODE');
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

    // TEST MODE: Server sends 'connected' instead of 'authenticated'
    _socket!.on('connected', (data) {
      AppLogger.log('🧪 Socket.IO test connection confirmed: $data');
      _isAuthenticated = true; // Set this for test mode too
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
  }

  // UPDATED: Test method that works in both modes
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
      } else {
        // Use 'testMessage' event for authenticated mode
        _socket!.emit('testMessage', {
          'content': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      AppLogger.log('📤 Test message sent: $message');
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

  void disconnect() {
    if (_socket != null) {
      AppLogger.log('🔌 Disconnecting Socket.IO...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _isAuthenticated = false;
    _isTestMode = false;
    AppLogger.log('✅ Socket.IO disconnected');
  }

  void dispose() {
    disconnect();
  }
}
