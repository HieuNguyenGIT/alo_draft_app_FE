import 'dart:async';

import 'package:flutter/material.dart';
import 'package:alo_draft_app/services/socket_io_service.dart';
import 'package:alo_draft_app/services/message_service.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:http/http.dart' as http;
import 'package:alo_draft_app/util/constants.dart';

class SocketTestScreen extends StatefulWidget {
  const SocketTestScreen({super.key});

  @override
  State<SocketTestScreen> createState() => _SocketTestScreenState();
}

class _SocketTestScreenState extends State<SocketTestScreen> {
  String _status = 'Not tested';
  final List<String> _logs = [];
  bool _isConnected = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _updateConnectionStatus();

    // Listen to Socket.IO status changes
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        final newStatus = SocketIOService.instance.isConnected;
        if (newStatus != _isConnected) {
          setState(() {
            _isConnected = newStatus;
          });
          _addLog(_isConnected
              ? '✅ Socket.IO Connected'
              : '❌ Socket.IO Disconnected');
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _updateConnectionStatus() {
    setState(() {
      _isConnected = SocketIOService.instance.isConnected;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0,
          '${DateTime.now().toLocal().toString().substring(11, 19)}: $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
    AppLogger.log(message);
  }

  Future<void> _testHttpConnection() async {
    _addLog('🧪 Testing HTTP connection...');
    setState(() {
      _isTesting = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$healthCheckUrl'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        _addLog('✅ HTTP connection successful (${response.statusCode})');
        _addLog('📄 Response: ${response.body}');
      } else {
        _addLog('❌ HTTP connection failed (${response.statusCode})');
      }
    } catch (e) {
      _addLog('❌ HTTP connection error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testMessageService() async {
    _addLog('🧪 Testing Message Service...');
    setState(() {
      _isTesting = true;
    });

    try {
      final success = await MessageService.testConnection();
      if (success) {
        _addLog('✅ Message Service connection successful');

        // Try to load conversations
        final conversations = await MessageService.getConversations();
        _addLog('📋 Loaded ${conversations.length} conversations');
      } else {
        _addLog('❌ Message Service connection failed');
      }
    } catch (e) {
      _addLog('❌ Message Service error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testSocketIOConnection() async {
    _addLog('🧪 Testing Socket.IO connection...');
    setState(() {
      _isTesting = true;
      _status = 'Connecting...';
    });

    try {
      if (SocketIOService.instance.isConnected) {
        _addLog('⚠️ Socket.IO already connected, disconnecting first...');
        SocketIOService.instance.disconnect();
        await Future.delayed(Duration(seconds: 1));
      }

      await SocketIOService.instance.connect();

      // Wait for authentication
      await Future.delayed(Duration(seconds: 3));

      if (SocketIOService.instance.isConnected) {
        _addLog('✅ Socket.IO connected and authenticated');
        setState(() {
          _status = 'Connected';
        });

        // Test message sending
        SocketIOService.instance.sendTestMessage('Test from SocketTestScreen');
        _addLog('📤 Test message sent');

        // Test connection check
        final connectionStatus = SocketIOService.instance.checkConnection();
        _addLog('🔍 Connection check result: $connectionStatus');
      } else {
        _addLog('❌ Socket.IO connection failed');
        setState(() {
          _status = 'Failed';
        });
      }
    } catch (e) {
      _addLog('❌ Socket.IO error: $e');
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _disconnect() {
    SocketIOService.instance.disconnect();
    _addLog('🔌 Disconnected manually');
    setState(() {
      _status = 'Disconnected';
      _isConnected = false;
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Socket.IO Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: EdgeInsets.all(16),
            color: _isConnected
                ? Colors.green[100]
                : _status.contains('Error') || _status.contains('Failed')
                    ? Colors.red[100]
                    : Colors.blue[100],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? Colors.green
                              : _isTesting
                                  ? Colors.orange
                                  : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Connection Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _isConnected ? 'Connected & Authenticated' : _status,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isConnected
                          ? Colors.green[800]
                          : _status.contains('Error') ||
                                  _status.contains('Failed')
                              ? Colors.red[800]
                              : Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Test Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isTesting ? null : _testHttpConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Test HTTP'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isTesting ? null : _testMessageService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Test Messages'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isTesting ? null : _testSocketIOConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Test Socket.IO'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isTesting ? null : _disconnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Disconnect'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _clearLogs,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Clear Logs'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isConnected
                            ? () {
                                SocketIOService.instance
                                    .sendTestMessage('Manual test message');
                                _addLog('📤 Manual test message sent');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Send Test'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Logs Section
          Expanded(
            child: Card(
              margin: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Logs (${_logs.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        if (_isTesting)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  Expanded(
                    child: _logs.isEmpty
                        ? Center(
                            child: Text(
                              'No logs yet. Run a test to see logs here.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(8),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              Color textColor = Colors.black87;

                              if (log.contains('✅')) {
                                textColor = Colors.green[700]!;
                              } else if (log.contains('❌')) {
                                textColor = Colors.red[700]!;
                              } else if (log.contains('📤') ||
                                  log.contains('📨')) {
                                textColor = Colors.blue[700]!;
                              } else if (log.contains('⚠️')) {
                                textColor = Colors.orange[700]!;
                              }

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 1),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: textColor,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
