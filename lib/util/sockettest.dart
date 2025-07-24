import 'dart:async';
import 'package:alo_draft_app/util/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:alo_draft_app/services/api_service.dart';

class SimpleSocketTest {
  // 🔥 FIXED: Test connection using test namespace (no auth required)
  static Future<void> testBasicConnection() async {
    AppLogger.log('🧪 Testing basic Socket.IO connection to test namespace...');

    try {
      // 🔥 CRITICAL: Connect to /test namespace which doesn't require auth
      final socket = io.io(
          '$socketIOUrl/test', // Test namespace path
          io.OptionBuilder()
              .setTransports(['websocket']) // Flutter only supports websocket
              .enableReconnection()
              .setReconnectionAttempts(2)
              .setReconnectionDelay(1000)
              .setTimeout(30000) // 30 second timeout
              .enableForceNew()
              .disableAutoConnect() // Manual connection control
              .build());

      final completer = Completer<bool>();
      bool hasCompleted = false;

      // Set up event listeners BEFORE connecting
      socket.onConnect((_) {
        AppLogger.log('✅ BASIC connection SUCCESS to test namespace!');
        if (!hasCompleted) {
          hasCompleted = true;
          socket.disconnect();
          if (!completer.isCompleted) completer.complete(true);
        }
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ BASIC connection FAILED: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.on('connect_timeout', (_) {
        AppLogger.log('⏰ BASIC connection TIMEOUT');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Listen for test namespace confirmation
      socket.on('connected', (data) {
        AppLogger.log('🎉 Test namespace confirmed: $data');
      });

      socket.on('error', (error) {
        AppLogger.log('❌ Test namespace error: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Connect manually after setting up listeners
      AppLogger.log('🔗 Manually connecting to test namespace...');
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
        AppLogger.log('🎉 Socket.IO test namespace is reachable!');
      } else {
        AppLogger.log('💥 Socket.IO test namespace is NOT reachable!');
      }
    } catch (e) {
      AppLogger.log('💥 Test exception: $e');
    }
  }

  // Test message sending to test namespace
  static Future<void> testMessageSending() async {
    AppLogger.log('🧪 Testing message sending to test namespace...');

    try {
      final socket = io.io(
          '$socketIOUrl/test',
          io.OptionBuilder()
              .setTransports(['websocket'])
              .setTimeout(30000)
              .enableForceNew()
              .disableAutoConnect()
              .build());

      final completer = Completer<bool>();
      bool hasCompleted = false;

      socket.onConnect((_) {
        AppLogger.log('✅ Connected to test namespace for message test');

        // Send test message
        socket.emit('test', {
          'message': 'Hello from Flutter!',
          'timestamp': DateTime.now().toIso8601String(),
        });
        AppLogger.log('📤 Test message sent');
      });

      socket.on('testResponse', (data) {
        AppLogger.log('📨 Received test response: $data');
        if (!hasCompleted) {
          hasCompleted = true;
          socket.disconnect();
          if (!completer.isCompleted) completer.complete(true);
        }
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ Message test connection failed: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.on('error', (error) {
        AppLogger.log('❌ Message test error: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Connect manually
      AppLogger.log('🔗 Manually connecting for message test...');
      socket.connect();

      final result = await completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          AppLogger.log('⏰ Message test timed out');
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
        AppLogger.log('🎉 Message sending works!');
      } else {
        AppLogger.log('💥 Message sending failed!');
      }
    } catch (e) {
      AppLogger.log('💥 Message test exception: $e');
    }
  }

  // 🔥 NEW: Test main Socket.IO connection with real authentication
  static Future<void> testAuthenticatedConnection() async {
    AppLogger.log('🧪 Testing authenticated Socket.IO connection...');

    try {
      // Get real authentication token
      final String? token = await ApiService.getToken();

      if (token == null) {
        AppLogger.log('❌ No authentication token available for test');
        AppLogger.log(
            '💡 Make sure you are logged in before testing authenticated connection');
        return;
      }

      AppLogger.log('🔑 Using auth token: ${token.substring(0, 20)}...');

      final socket = io.io(
          socketIOUrl, // Main namespace (requires auth)
          io.OptionBuilder()
              .setTransports(['websocket']) // Flutter only supports websocket
              .setTimeout(45000) // Longer timeout for auth
              .enableForceNew()
              .disableAutoConnect()
              .setAuth({'token': token}) // Real authentication token
              .build());

      final completer = Completer<bool>();
      bool hasCompleted = false;

      socket.onConnect((_) {
        AppLogger.log('✅ Authenticated connection established!');
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
        AppLogger.log('❌ Authenticated connection FAILED: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.on('connect_timeout', (_) {
        AppLogger.log('⏰ Authenticated connection TIMEOUT');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.on('error', (error) {
        AppLogger.log('❌ Authentication error: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Connect manually
      AppLogger.log('🔗 Manually connecting with authentication...');
      socket.connect();

      final result = await completer.future.timeout(
        const Duration(seconds: 50),
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
        AppLogger.log('🎉 Authenticated Socket.IO works!');
      } else {
        AppLogger.log('💥 Authenticated Socket.IO failed!');
      }
    } catch (e) {
      AppLogger.log('💥 Authenticated test exception: $e');
    }
  }

  // 🔥 NEW: Test authenticated message sending
  static Future<void> testAuthenticatedMessageSending() async {
    AppLogger.log('🧪 Testing authenticated message sending...');

    try {
      final String? token = await ApiService.getToken();

      if (token == null) {
        AppLogger.log(
            '❌ No authentication token available for auth message test');
        return;
      }

      final socket = io.io(
          socketIOUrl,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .setTimeout(45000)
              .enableForceNew()
              .disableAutoConnect()
              .setAuth({'token': token})
              .build());

      final completer = Completer<bool>();
      bool hasCompleted = false;

      socket.on('authenticated', (data) {
        AppLogger.log('✅ Authenticated for message test: $data');

        // Send test message in authenticated mode
        socket.emit('testMessage', {
          'content': 'Hello from authenticated Flutter!',
          'timestamp': DateTime.now().toIso8601String(),
        });
        AppLogger.log('📤 Authenticated test message sent');
      });

      socket.on('testResponse', (data) {
        AppLogger.log('📨 Received authenticated test response: $data');
        if (!hasCompleted) {
          hasCompleted = true;
          socket.disconnect();
          if (!completer.isCompleted) completer.complete(true);
        }
      });

      socket.onConnectError((error) {
        AppLogger.log('❌ Auth message test connection failed: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      socket.on('error', (error) {
        AppLogger.log('❌ Auth message test error: $error');
        if (!hasCompleted) {
          hasCompleted = true;
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Connect manually
      AppLogger.log('🔗 Connecting for authenticated message test...');
      socket.connect();

      final result = await completer.future.timeout(
        const Duration(seconds: 50),
        onTimeout: () {
          AppLogger.log('⏰ Auth message test timed out');
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
        AppLogger.log('🎉 Authenticated message sending works!');
      } else {
        AppLogger.log('💥 Authenticated message sending failed!');
      }
    } catch (e) {
      AppLogger.log('💥 Auth message test exception: $e');
    }
  }

  // 🔥 NEW: Run all tests in sequence
  static Future<void> runAllTests() async {
    AppLogger.log('🚀 Running complete Socket.IO test suite...');

    AppLogger.log('\n=== TEST 1: Basic Connection (Test Namespace) ===');
    await testBasicConnection();
    await Future.delayed(const Duration(seconds: 2));

    AppLogger.log('\n=== TEST 2: Message Sending (Test Namespace) ===');
    await testMessageSending();
    await Future.delayed(const Duration(seconds: 2));

    AppLogger.log(
        '\n=== TEST 3: Authenticated Connection (Main Namespace) ===');
    await testAuthenticatedConnection();
    await Future.delayed(const Duration(seconds: 2));

    AppLogger.log('\n=== TEST 4: Authenticated Message Sending ===');
    await testAuthenticatedMessageSending();

    AppLogger.log('\n🏁 Socket.IO test suite completed!');
  }
}
