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

  // 🔥 FIXED: Main namespace connection with proper auth
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

      AppLogger.log(
          '🌐 Socket.IO connecting to MAIN namespace: $socketIOUrl (WITH AUTH)');
      AppLogger.log('🔑 Using token: ${token.substring(0, 20)}...');

      // 🔥 CRITICAL: Optimized configuration for Flutter
      _socket = io.io(
          socketIOUrl, // Main namespace
          io.OptionBuilder()
              .setTransports(['websocket']) // Flutter only supports websocket
              .enableReconnection()
              .setReconnectionAttempts(3)
              .setReconnectionDelay(2000)
              .setTimeout(45000) // 45 second timeout
              .enableForceNew()
              .disableAutoConnect() // Manual connection control
              .setAuth({'token': token}) // Authentication token
              .build());

      _isTestMode = false;
      _setupEventHandlers();

      AppLogger.log('🔗 Manually connecting to main namespace...');
      _socket!.connect();

      // Wait for authentication with proper timeout
      await _waitForAuthentication(timeout: 45000);
      AppLogger.log('✅ Socket.IO successfully connected and authenticated!');
    } catch (e) {
      AppLogger.log('❌ Socket.IO connection error: $e');
      _cleanup();
      rethrow;
    }
  }

  // 🔥 FIXED: Test namespace connection (no auth)
  Future<void> connectTest() async {
    if (_isConnected) {
      AppLogger.log('🔌 Socket.IO already connected');
      return;
    }

    try {
      AppLogger.log(
          '🌐 Socket.IO connecting to TEST namespace: $socketIOUrl/test (NO AUTH)');

      // 🔥 CRITICAL: Test namespace configuration
      _socket = io.io(
          '$socketIOUrl/test', // Test namespace
          io.OptionBuilder()
              .setTransports(['websocket']) // Flutter only supports websocket
              .enableReconnection()
              .setReconnectionAttempts(2)
              .setReconnectionDelay(1000)
              .setTimeout(30000) // 30 second timeout for test
              .enableForceNew()
              .disableAutoConnect() // Manual connection control
              // NO auth for test mode
              .build());

      _isTestMode = true;
      _setupEventHandlers();

      AppLogger.log('🔗 Manually connecting to test namespace...');
      _socket!.connect();

      // Wait for test connection
      await _waitForConnection(timeout: 30000);
      AppLogger.log('✅ Socket.IO test connection successful!');
    } catch (e) {
      AppLogger.log('❌ Socket.IO test connection error: $e');
      _cleanup();
      rethrow;
    }
  }

  // 🔥 ENHANCED: Event handler setup with detailed logging
  void _setupEventHandlers() {
    if (_socket == null) return;

    AppLogger.log('🔧 Setting up Socket.IO event handlers...');

    _socket!.onConnect((_) {
      AppLogger.log('✅ Socket.IO engine connected successfully');
      _isConnected = true;
      if (_isTestMode) {
        AppLogger.log('🧪 Connected in TEST MODE');
        // Test mode considers authenticated immediately on connect
        _isAuthenticated = true;
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

    // Handle connection timeout
    _socket!.on('connect_timeout', (_) {
      AppLogger.log('⏰ Socket.IO connection timeout');
      _isConnected = false;
      _isAuthenticated = false;
    });

    // 🔥 TEST MODE: Listen for 'connected' event from test namespace
    _socket!.on('connected', (data) {
      AppLogger.log('🧪 Socket.IO test namespace confirmed: $data');
      _isAuthenticated = true;
    });

    // 🔥 MAIN MODE: Listen for 'authenticated' event from main namespace
    _socket!.on('authenticated', (data) {
      AppLogger.log('✅ Socket.IO main namespace authenticated: $data');
      _isAuthenticated = true;
    });

    // Error handling
    _socket!.on('connect_error', (error) {
      AppLogger.log('❌ Socket.IO connect_error: $error');
      _isAuthenticated = false;
    });

    _socket!.on('error', (error) {
      AppLogger.log('❌ Socket.IO general error: $error');
    });

    // Message handlers
    _socket!.on('testResponse', (data) {
      AppLogger.log('🧪 Socket.IO test response: $data');
    });

    _socket!.on('newMessage', (data) {
      AppLogger.log('📨 Socket.IO new message: $data');
    });

    _socket!.on('joinedConversation',
        (data) => {AppLogger.log('🏠 Socket.IO joined conversation: $data')});

    _socket!.on('messageStatus',
        (data) => {AppLogger.log('📤 Socket.IO message status: $data')});

    _socket!.on('userTyping',
        (data) => {AppLogger.log('⌨️ Socket.IO user typing: $data')});

    _socket!.on('userStoppedTyping',
        (data) => {AppLogger.log('⌨️ Socket.IO user stopped typing: $data')});

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

    AppLogger.log('✅ Event handlers setup complete');
  }

  // 🔥 NEW: Wait for authentication (main namespace)
  Future<void> _waitForAuthentication({int timeout = 45000}) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;
    bool hasCompleted = false;

    AppLogger.log('⏳ Waiting for authentication...');

    // Set up timeout
    timeoutTimer = Timer(Duration(milliseconds: timeout), () {
      if (!hasCompleted) {
        hasCompleted = true;
        if (!completer.isCompleted) {
          completer.completeError('Authentication timeout after ${timeout}ms');
        }
      }
    });

    // Create temporary event handlers
    void onAuthenticatedHandler(data) {
      AppLogger.log('🎉 Authentication confirmed: $data');
      timeoutTimer?.cancel();
      if (!hasCompleted) {
        hasCompleted = true;
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    void onErrorHandler(error) {
      AppLogger.log('❌ Authentication error: $error');
      timeoutTimer?.cancel();
      if (!hasCompleted) {
        hasCompleted = true;
        if (!completer.isCompleted) {
          completer.completeError('Authentication failed: $error');
        }
      }
    }

    void onConnectErrorHandler(error) {
      AppLogger.log('❌ Connection error during auth: $error');
      timeoutTimer?.cancel();
      if (!hasCompleted) {
        hasCompleted = true;
        if (!completer.isCompleted) {
          completer.completeError('Connection error: $error');
        }
      }
    }

    // Listen for the appropriate events based on mode
    if (_isTestMode) {
      _socket!.on('connected', onAuthenticatedHandler);
    } else {
      _socket!.on('authenticated', onAuthenticatedHandler);
    }
    _socket!.on('connect_error', onConnectErrorHandler);
    _socket!.on('error', onErrorHandler);

    try {
      return await completer.future;
    } finally {
      // Clean up temporary listeners
      if (_isTestMode) {
        _socket!.off('connected', onAuthenticatedHandler);
      } else {
        _socket!.off('authenticated', onAuthenticatedHandler);
      }
      _socket!.off('connect_error', onConnectErrorHandler);
      _socket!.off('error', onErrorHandler);
      timeoutTimer.cancel();
    }
  }

  // 🔥 NEW: Wait for basic connection (test namespace)
  Future<void> _waitForConnection({int timeout = 30000}) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;
    bool hasCompleted = false;

    AppLogger.log('⏳ Waiting for basic connection...');

    // Set up timeout
    timeoutTimer = Timer(Duration(milliseconds: timeout), () {
      if (!hasCompleted) {
        hasCompleted = true;
        if (!completer.isCompleted) {
          completer.completeError('Connection timeout after ${timeout}ms');
        }
      }
    });

    // Create temporary event handlers
    void onConnectHandler(_) {
      AppLogger.log('🎉 Basic connection established');
      timeoutTimer?.cancel();
      if (!hasCompleted) {
        hasCompleted = true;
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    void onErrorHandler(error) {
      AppLogger.log('❌ Connection error: $error');
      timeoutTimer?.cancel();
      if (!hasCompleted) {
        hasCompleted = true;
        if (!completer.isCompleted) {
          completer.completeError('Connection error: $error');
        }
      }
    }

    // Set up temporary listeners
    _socket!.onConnect(onConnectHandler);
    _socket!.onConnectError(onErrorHandler);

    try {
      return await completer.future;
    } finally {
      // Clean up temporary listeners
      _socket!.off('connect', onConnectHandler);
      _socket!.off('connect_error', onErrorHandler);
      timeoutTimer.cancel();
    }
  }

  // Send test message (works in both modes)
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
    AppLogger.log('⌨️ Started typing in conversation $conversationId');
  }

  void stopTyping(int conversationId) {
    if (!isConnected || _isTestMode) return;
    _socket!.emit('stopTyping', conversationId);
    AppLogger.log('⌨️ Stopped typing in conversation $conversationId');
  }

  // Get connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'isAuthenticated': _isAuthenticated,
      'isTestMode': _isTestMode,
      'socketId': _socket?.id,
      'transport': _socket?.connected == true ? 'websocket' : 'disconnected',
      'namespace': _isTestMode ? '/test' : '/',
    };
  }

  // 🔥 NEW: Debug connection status
  void logConnectionStatus() {
    final info = getConnectionInfo();
    AppLogger.log('🔍 Socket.IO Connection Status:');
    AppLogger.log('   Connected: ${info['isConnected']}');
    AppLogger.log('   Authenticated: ${info['isAuthenticated']}');
    AppLogger.log('   Test Mode: ${info['isTestMode']}');
    AppLogger.log('   Socket ID: ${info['socketId']}');
    AppLogger.log('   Transport: ${info['transport']}');
    AppLogger.log('   Namespace: ${info['namespace']}');
  }

  void _cleanup() {
    _isConnected = false;
    _isAuthenticated = false;
    _isTestMode = false;
  }

  void disconnect() {
    if (_socket != null) {
      AppLogger.log('🔌 Disconnecting Socket.IO...');
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        AppLogger.log('⚠️ Error during Socket.IO cleanup: $e');
      }
      _socket = null;
    }
    _cleanup();
    AppLogger.log('✅ Socket.IO disconnected and cleaned up');
  }

  void dispose() {
    disconnect();
  }
}
