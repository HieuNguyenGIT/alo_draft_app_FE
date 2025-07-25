import 'dart:async';
import 'dart:io';
import 'package:alo_draft_app/util/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:alo_draft_app/services/api_service.dart';

class SimpleSocketTest {
  // 🔥 CRITICAL FIX: Test connection with WebSocket-only transport
  static Future<void> testBasicConnection() async {
    AppLogger.log('🧪 Testing basic Socket.IO connection to test namespace...');

    try {
      // 🔥 CRITICAL: WebSocket-only transport for Flutter mobile
      final socket = io.io(
          '$socketIOUrl/test', // Test namespace URL
          io.OptionBuilder()
              // 🔥 CRITICAL: Flutter mobile ONLY supports WebSocket
              .setTransports(['websocket']) // ✅ REQUIRED for Flutter mobile

              .disableAutoConnect() // Manual control
              .enableReconnection()
              .setReconnectionAttempts(2)
              .setReconnectionDelay(1000)
              .setTimeout(30000)
              .enableForceNew()

              // 🔥 DEBUGGING: Add extra headers
              .setExtraHeaders({
                'User-Agent': 'Flutter-WebSocket-Client',
                'Accept': '*/*',
              })
              .build());

      final completer = Completer<bool>();
      bool hasCompleted = false;

      // Set up event listeners BEFORE connecting
      socket.onConnect((_) {
        AppLogger.log('✅ WEBSOCKET connection SUCCESS to test namespace!');
        AppLogger.log('   Socket ID: ${socket.id}');
        AppLogger.log('   Connected: ${socket.connected}');
        if (!hasCompleted) {
          hasCompleted = true;
          socket.disconnect();
          if (!completer.isCompleted) completer.complete(true);
        }
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ WEBSOCKET connection FAILED: $error');
        AppLogger.log('   Error type: ${error.runtimeType}');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.on('connect_timeout', (_) {
        AppLogger.log('⏰ WEBSOCKET connection TIMEOUT');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Listen for test namespace confirmation
      socket.on('connected', (data) {
        AppLogger.log('🎉 Test namespace confirmed: $data');
      });

      socket.onError((error) {
        AppLogger.log('❌ Test namespace error: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      AppLogger.log('🔗 Connecting to test namespace with WebSocket...');
      AppLogger.log('   URL: $socketIOUrl/test');
      AppLogger.log('   Transport: WebSocket ONLY');

      // Manual connection
      socket.connect();

      // Wait for result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          AppLogger.log('⏰ Test timed out after 35 seconds');
          hasCompleted = true;
          return false;
        },
      );

      // Cleanup
      try {
        socket.dispose();
      } catch (e) {
        AppLogger.log('⚠️ Socket disposal error: $e');
      }

      if (result) {
        AppLogger.log('🎉 Socket.IO test namespace works with WebSocket!');
      } else {
        AppLogger.log('💥 Socket.IO test namespace failed with WebSocket!');
      }
    } catch (e) {
      AppLogger.log('💥 Test exception: $e');
      AppLogger.log('   Exception type: ${e.runtimeType}');
    }
  }

  // 🔥 CRITICAL FIX: Authenticated connection with WebSocket-only
  static Future<void> testAuthenticatedConnection() async {
    AppLogger.log('🧪 Testing authenticated Socket.IO connection...');

    try {
      final String? token = await ApiService.getToken();

      if (token == null) {
        AppLogger.log('❌ No authentication token available for test');
        return;
      }

      AppLogger.log('🔑 Using auth token: ${token.substring(0, 20)}...');

      // 🔥 CRITICAL: WebSocket-only for main namespace
      final socket = io.io(
          socketIOUrl, // Main namespace
          io.OptionBuilder()
              // 🔥 CRITICAL: Flutter mobile ONLY supports WebSocket
              .setTransports(['websocket']) // ✅ REQUIRED for Flutter mobile

              .disableAutoConnect()
              .setTimeout(60000)
              .enableForceNew()
              .setAuth({'token': token}) // Authentication token

              .setExtraHeaders({
                'User-Agent': 'Flutter-Auth-WebSocket-Client',
                'Accept': '*/*',
              })
              .build());

      final completer = Completer<bool>();
      bool hasCompleted = false;

      socket.onConnect((_) {
        AppLogger.log('✅ Authenticated WebSocket connection established!');
        AppLogger.log('   Socket ID: ${socket.id}');
        AppLogger.log('   Connected: ${socket.connected}');
      });

      socket.on('authenticated', (data) {
        AppLogger.log('🎉 Authentication confirmed: $data');
        if (!hasCompleted) {
          hasCompleted = true;
          socket.disconnect();
          if (!completer.isCompleted) completer.complete(true);
        }
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ Authenticated WebSocket connection FAILED: $error');
        AppLogger.log('   Error type: ${error.runtimeType}');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.on('connect_timeout', (_) {
        AppLogger.log('⏰ Authenticated WebSocket connection TIMEOUT');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.onError((error) {
        AppLogger.log('❌ Authentication error: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      AppLogger.log('🔗 Connecting with authentication via WebSocket...');
      AppLogger.log('   URL: $socketIOUrl');
      AppLogger.log('   Namespace: / (main)');
      AppLogger.log('   Transport: WebSocket ONLY');

      // Manual connection
      socket.connect();

      final result = await completer.future.timeout(
        const Duration(seconds: 65),
        onTimeout: () {
          AppLogger.log('⏰ Authenticated test timed out');
          hasCompleted = true;
          return false;
        },
      );

      // Cleanup
      try {
        socket.dispose();
      } catch (e) {
        AppLogger.log('⚠️ Socket disposal error: $e');
      }

      if (result) {
        AppLogger.log('🎉 Authenticated Socket.IO works with WebSocket!');
      } else {
        AppLogger.log('💥 Authenticated Socket.IO failed with WebSocket!');
      }
    } catch (e) {
      AppLogger.log('💥 Authenticated test exception: $e');
      AppLogger.log('   Exception type: ${e.runtimeType}');
    }
  }

  // 🔥 NEW: Add HTTP override for potential certificate issues
  static void setupHttpOverrides() {
    HttpOverrides.global = _CustomHttpOverrides();
    AppLogger.log('🔧 HTTP overrides configured for Socket.IO');
  }

  // 🔥 RUN ALL TESTS WITH FIXES
  static Future<void> runAllTests() async {
    AppLogger.log(
        '🚀 Running Socket.IO tests with WebSocket-only transport...');

    // Set up HTTP overrides
    setupHttpOverrides();

    AppLogger.log('\n=== TEST 1: Test Namespace (WebSocket) ===');
    await testBasicConnection();
    await Future.delayed(const Duration(seconds: 3));

    AppLogger.log('\n=== TEST 2: Authenticated Connection (WebSocket) ===');
    await testAuthenticatedConnection();

    AppLogger.log('\n🏁 Socket.IO WebSocket tests completed!');
  }
}

// 🔥 CRITICAL: HTTP overrides for certificate and network issues
class _CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Accept all certificates (for development only)
        AppLogger.log('🔓 Accepting certificate for $host:$port');
        return true;
      }
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30);
  }
}
