import 'package:flutter/material.dart';
import 'package:alo_draft_app/services/socket_io_service.dart';
import 'package:alo_draft_app/util/custom_logger.dart';

class SocketIOTestScreen extends StatefulWidget {
  const SocketIOTestScreen({super.key});

  @override
  State<SocketIOTestScreen> createState() => _SocketIOTestScreenState();
}

class _SocketIOTestScreenState extends State<SocketIOTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _logs = [];
  bool _isConnected = false;
  late SocketIOService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = SocketIOService.instance;
    _updateConnectionStatus();
  }

  void _updateConnectionStatus() {
    setState(() {
      _isConnected = _socketService.isConnected;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toLocal()}: $message');
      if (_logs.length > 20) {
        _logs.removeLast();
      }
    });
    AppLogger.log(message);
  }

  Future<void> _connect() async {
    _addLog('Attempting to connect to Socket.IO...');
    try {
      await _socketService.connect();

      // Wait a moment for authentication
      await Future.delayed(const Duration(seconds: 2));

      _updateConnectionStatus();
      _addLog(_isConnected ? 'Connected successfully!' : 'Connection failed');
    } catch (e) {
      _addLog('Connection error: $e');
    }
  }

  void _disconnect() {
    _addLog('Disconnecting from Socket.IO...');
    _socketService.disconnect();
    _updateConnectionStatus();
    _addLog('Disconnected');
  }

  void _sendTestMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _addLog('Sending test message: $message');
      _socketService.sendTestMessage(message);
      _messageController.clear();
    }
  }

  void _joinTestConversation() {
    _addLog('Joining test conversation (ID: 1)');
    _socketService.joinConversation(1);
  }

  void _sendRealMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _addLog('Sending real message to conversation 1: $message');
      _socketService.sendMessage(
        conversationId: 1,
        content: message,
        temporaryId: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${_isConnected ? "Connected & Authenticated" : "Disconnected"}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Connection Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? null : _connect,
                    icon: const Icon(Icons.connect_without_contact),
                    label: const Text('Connect (Auth)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? _disconnect : _connectTest,
                    icon: Icon(_isConnected ? Icons.close : Icons.bug_report),
                    label: Text(_isConnected ? 'Disconnect' : 'Test Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter test message...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isConnected,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnected ? _sendTestMessage : null,
                  child: const Text('Test'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? _joinTestConversation : null,
                    child: const Text('Join Conv 1'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? _sendRealMessage : null,
                    child: const Text('Send Real Msg'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Logs
            const Text(
              'Logs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
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
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Logs'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectTest() async {
    _addLog('Attempting to connect to Socket.IO in TEST MODE (no auth)...');
    try {
      await _socketService.connectTest();

      // Wait a moment for connection
      await Future.delayed(const Duration(seconds: 2));

      _updateConnectionStatus();
      _addLog(_isConnected
          ? 'Test connection successful!'
          : 'Test connection failed');
    } catch (e) {
      _addLog('Test connection error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
