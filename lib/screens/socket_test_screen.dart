import 'package:alo_draft_app/util/sockettest.dart';
import 'package:flutter/material.dart';
import 'package:alo_draft_app/services/socket_io_service.dart';
import 'package:alo_draft_app/services/websocket_service.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:alo_draft_app/util/constants.dart';

class DualConnectionTestScreen extends StatefulWidget {
  const DualConnectionTestScreen({super.key});

  @override
  State<DualConnectionTestScreen> createState() =>
      _DualConnectionTestScreenState();
}

class _DualConnectionTestScreenState extends State<DualConnectionTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _logs = [];

  bool _socketIOConnected = false;
  bool _webSocketConnected = false;

  late SocketIOService _socketService;
  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    _socketService = SocketIOService.instance;
    _webSocketService = WebSocketService.instance;
    _updateConnectionStatus();
  }

  void _updateConnectionStatus() {
    setState(() {
      _socketIOConnected = _socketService.isConnected;
      _webSocketConnected = _webSocketService.isConnected;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toLocal()}: $message');
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
    AppLogger.log(message);
  }

  // Socket.IO Methods
  Future<void> _connectSocketIO() async {
    _addLog('🟦 Connecting Socket.IO...');
    try {
      await _socketService.connect();
      await Future.delayed(const Duration(seconds: 2));
      _updateConnectionStatus();
      _addLog(_socketIOConnected
          ? '🟦 Socket.IO Connected!'
          : '🟦 Socket.IO Failed');
    } catch (e) {
      _addLog('🟦 Socket.IO Error: $e');
    }
  }

  void _disconnectSocketIO() {
    _addLog('🟦 Disconnecting Socket.IO...');
    _socketService.disconnect();
    _updateConnectionStatus();
    _addLog('🟦 Socket.IO Disconnected');
  }

  void _sendSocketIOMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _socketIOConnected) {
      _addLog('🟦 Sending Socket.IO message: $message');
      _socketService.sendTestMessage(message);
      _messageController.clear();
    }
  }

  // WebSocket Methods
  Future<void> _connectWebSocket() async {
    _addLog('🟩 Connecting WebSocket...');
    try {
      await _webSocketService.connect();
      await Future.delayed(const Duration(seconds: 2));
      _updateConnectionStatus();
      _addLog(_webSocketConnected
          ? '🟩 WebSocket Connected!'
          : '🟩 WebSocket Failed');
    } catch (e) {
      _addLog('🟩 WebSocket Error: $e');
    }
  }

  void _disconnectWebSocket() {
    _addLog('🟩 Disconnecting WebSocket...');
    _webSocketService.disconnect();
    _updateConnectionStatus();
    _addLog('🟩 WebSocket Disconnected');
  }

  // Test HTTP endpoint first
  Future<void> _testHttpEndpoint() async {
    _addLog('🌐 Testing HTTP endpoint...');
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api', '')}/socket-test'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addLog('✅ HTTP endpoint works: ${data['message']}');
        _addLog('👥 Connected clients: ${data['connectedClients']}');
      } else {
        _addLog('❌ HTTP endpoint failed: ${response.statusCode}');
      }
    } catch (e) {
      _addLog('❌ HTTP test error: $e');
    }
  }

  // Test basic Socket.IO connection (no auth)
  Future<void> _testBasicSocketIO() async {
    _addLog('🧪 Testing basic Socket.IO (no auth)...');
    try {
      await SimpleSocketTest.testBasicConnection();
    } catch (e) {
      _addLog('❌ Basic test error: $e');
    }
  }

  // Test WebSocket transport
  Future<void> _testWebSocketTransport() async {
    _addLog('🧪 Testing WebSocket transport...');
    try {
      await SimpleSocketTest.testWithWebSocketTransport();
    } catch (e) {
      _addLog('❌ WebSocket transport test error: $e');
    }
  }

  Future<void> _connectBoth() async {
    _addLog('🚀 Connecting both Socket.IO and WebSocket...');
    await Future.wait([
      _connectSocketIO(),
      _connectWebSocket(),
    ]);
  }

  void _disconnectBoth() {
    _addLog('🛑 Disconnecting both connections...');
    _disconnectSocketIO();
    _disconnectWebSocket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual Connection Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color:
                        _socketIOConnected ? Colors.blue[100] : Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Icon(
                            _socketIOConnected
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                _socketIOConnected ? Colors.blue : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Socket.IO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _socketIOConnected
                                  ? Colors.blue[800]
                                  : Colors.red[800],
                            ),
                          ),
                          Text(
                            _socketIOConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              fontSize: 12,
                              color: _socketIOConnected
                                  ? Colors.blue[600]
                                  : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: _webSocketConnected
                        ? Colors.green[100]
                        : Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Icon(
                            _webSocketConnected
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                _webSocketConnected ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'WebSocket',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _webSocketConnected
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                          Text(
                            _webSocketConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              fontSize: 12,
                              color: _webSocketConnected
                                  ? Colors.green[600]
                                  : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Debug Test Buttons
            const Text(
              'Debug Tests:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testHttpEndpoint,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('HTTP Test',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testBasicSocketIO,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Basic IO',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testWebSocketTransport,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo),
                    child: const Text('WS Transport',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(width: 4),
                // 🔥 NEW: Add message test button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testMessageSending,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
                    child: const Text('Messages',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        )),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dual Connection Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!_socketIOConnected || !_webSocketConnected)
                        ? _connectBoth
                        : null,
                    icon: const Icon(Icons.power),
                    label: const Text('Connect Both'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_socketIOConnected || _webSocketConnected)
                        ? _disconnectBoth
                        : null,
                    icon: const Icon(Icons.power_off),
                    label: const Text('Disconnect Both'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Individual Connection Buttons
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: !_socketIOConnected
                            ? _connectSocketIO
                            : _disconnectSocketIO,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _socketIOConnected ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_socketIOConnected
                            ? 'Disconnect IO'
                            : 'Connect IO'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: !_webSocketConnected
                            ? _connectWebSocket
                            : _disconnectWebSocket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _webSocketConnected ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_webSocketConnected
                            ? 'Disconnect WS'
                            : 'Connect WS'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message Input (only for Socket.IO)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter test message for Socket.IO...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _socketIOConnected,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _socketIOConnected ? _sendSocketIOMessage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send to IO'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connection URLs:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🟦 Socket.IO: http://192.168.100.87:3003',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  Text(
                    '🟩 WebSocket: ws://192.168.100.87:3003/ws',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${_socketIOConnected && _webSocketConnected ? '✅ Both Connected' : _socketIOConnected ? '🟦 Only Socket.IO' : _webSocketConnected ? '🟩 Only WebSocket' : '❌ Both Disconnected'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _socketIOConnected && _webSocketConnected
                          ? Colors.green[700]
                          : (_socketIOConnected || _webSocketConnected)
                              ? Colors.orange[700]
                              : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logs Header
            const Text(
              'Connection Logs:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Logs Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: log.contains('🟦')
                                    ? Colors.blue[700]
                                    : log.contains('🟩')
                                        ? Colors.green[700]
                                        : log.contains('Error') ||
                                                log.contains('Failed')
                                            ? Colors.red[700]
                                            : Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Clear Logs Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _logs.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Logs'),
            ),
          ],
        ),
      ),
    );
  }

  // And add this method to your test screen:
  Future<void> _testMessageSending() async {
    _addLog('🧪 Testing message sending...');
    try {
      await SimpleSocketTest.testMessageSending();
    } catch (e) {
      _addLog('❌ Message test error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
