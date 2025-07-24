import 'dart:async';
import 'package:alo_draft_app/util/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:alo_draft_app/util/custom_logger.dart';

class SimpleSocketTest {
  // 🔥 FIXED: Test connection using test namespace (no auth required)
  static Future<void> testBasicConnection() async {
    AppLogger.log('🧪 Testing basic Socket.IO connection...');

    try {
      // 🔥 CRITICAL: Connect to /test namespace which doesn't require auth
      final socket = io.io(
          '$socketIOUrl/test', // Added /test namespace
          io.OptionBuilder()
              .setTransports(['polling']) // Start with polling only
              .enableReconnection()
              .setTimeout(15000) // Increased timeout
              .enableForceNew()
              .build());

      final completer = Completer<bool>();

      socket.onConnect((_) {
        AppLogger.log('✅ BASIC connection SUCCESS!');
        socket.disconnect();
        if (!completer.isCompleted) completer.complete(true);
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ BASIC connection FAILED: $error');
        if (!completer.isCompleted) completer.complete(false);
      });

      socket.on('connect_timeout', (_) {
        AppLogger.log('⏰ BASIC connection TIMEOUT');
        if (!completer.isCompleted) completer.complete(false);
      });

      // 🔥 NEW: Listen for test namespace confirmation
      socket.on('connected', (data) {
        AppLogger.log('🎉 Test namespace confirmed: $data');
      });

      socket.connect();

      // Wait for result with longer timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 20), // Increased timeout
        onTimeout: () {
          AppLogger.log('⏰ Test timed out');
          return false;
        },
      );

      socket.dispose();

      if (result) {
        AppLogger.log('🎉 Socket.IO server is reachable!');
      } else {
        AppLogger.log('💥 Socket.IO server is NOT reachable!');
      }
    } catch (e) {
      AppLogger.log('💥 Test exception: $e');
    }
  }

  static Future<void> testWithWebSocketTransport() async {
    AppLogger.log('🧪 Testing with WebSocket transport...');

    try {
      // 🔥 FIXED: Use test namespace for WebSocket transport too
      final socket = io.io(
          '$socketIOUrl/test', // Added /test namespace
          io.OptionBuilder()
              .setTransports(['websocket']) // WebSocket only
              .enableReconnection()
              .setTimeout(15000) // Increased timeout
              .enableForceNew()
              .build());

      final completer = Completer<bool>();

      socket.onConnect((_) {
        AppLogger.log('✅ WebSocket transport SUCCESS!');
        socket.disconnect();
        if (!completer.isCompleted) completer.complete(true);
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ WebSocket transport FAILED: $error');
        if (!completer.isCompleted) completer.complete(false);
      });

      socket.connect();

      final result = await completer.future.timeout(
        const Duration(seconds: 20), // Increased timeout
        onTimeout: () => false,
      );

      socket.dispose();

      if (result) {
        AppLogger.log('🎉 WebSocket transport works!');
      } else {
        AppLogger.log('💥 WebSocket transport does NOT work!');
      }
    } catch (e) {
      AppLogger.log('💥 WebSocket test exception: $e');
    }
  }

  // 🔥 NEW: Test sending messages to test namespace
  static Future<void> testMessageSending() async {
    AppLogger.log('🧪 Testing message sending to test namespace...');

    try {
      final socket = io.io(
          '$socketIOUrl/test',
          io.OptionBuilder()
              .setTransports(['polling'])
              .setTimeout(15000)
              .enableForceNew()
              .build());

      final completer = Completer<bool>();

      socket.onConnect((_) {
        AppLogger.log('✅ Connected to test namespace for message test');

        // Send test message
        socket.emit('test', {
          'message': 'Hello from Flutter!',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });

      socket.on('testResponse', (data) {
        AppLogger.log('📨 Received test response: $data');
        socket.disconnect();
        if (!completer.isCompleted) completer.complete(true);
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ Message test connection failed: $error');
        if (!completer.isCompleted) completer.complete(false);
      });

      socket.connect();

      final result = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => false,
      );

      socket.dispose();

      if (result) {
        AppLogger.log('🎉 Message sending works!');
      } else {
        AppLogger.log('💥 Message sending failed!');
      }
    } catch (e) {
      AppLogger.log('💥 Message test exception: $e');
    }
  }
}
