import 'package:alo_draft_app/util/constants.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:alo_draft_app/services/message_service.dart';
import 'package:alo_draft_app/services/socket_io_service.dart';
import 'package:alo_draft_app/models/message_model.dart';
import 'package:alo_draft_app/util/shared_preferences_helper.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String otherUserName;
  final int otherUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isConnecting = false;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  int? _currentUserId;
  Timer? _typingTimer;
  bool _otherUserTyping = false;
  String? _typingUserName;
  Timer? _connectionRetryTimer;

  @override
  void initState() {
    super.initState();
    AppLogger.log(
        '🏠 ChatScreen initialized for conversation ${widget.conversationId}');
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _isConnecting = true;
    });

    try {
      // Get current user ID
      _currentUserId = await SharedPreferencesHelper.getUserId();
      AppLogger.log('🆔 Current user ID: $_currentUserId');

      if (_currentUserId == null) {
        throw Exception('No current user ID available');
      }

      // Test basic connectivity first
      final connectionTest = await MessageService.testConnection();
      if (!connectionTest) {
        AppLogger.log(
            '⚠️ Basic connectivity test failed, continuing anyway...');
      }

      // Load initial messages first
      await _loadMessages();

      // Then handle Socket.IO connection
      await _initializeSocketIO();
    } catch (e) {
      AppLogger.log('❌ Error initializing chat: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to initialize chat: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _initializeSocketIO() async {
    try {
      AppLogger.log('🔌 Initializing Socket.IO connection...');

      // Check if already connected
      if (SocketIOService.instance.isConnected) {
        AppLogger.log('✅ Socket.IO already connected');
        _setupSocketListeners();
        _joinConversation();
        return;
      }

      // Connect with timeout
      await SocketIOService.instance.connect().timeout(
        Duration(seconds: 20),
        onTimeout: () {
          AppLogger.log('⏰ Socket.IO connection timeout');
          throw TimeoutException(
              'Socket.IO connection timeout', Duration(seconds: 20));
        },
      );

      // Wait a bit for authentication
      await Future.delayed(Duration(seconds: 2));

      if (SocketIOService.instance.isConnected) {
        AppLogger.log('✅ Socket.IO connected and authenticated');
        _setupSocketListeners();
        _joinConversation();
      } else {
        AppLogger.log('❌ Socket.IO connection failed after timeout');
        _scheduleReconnection();
      }
    } catch (e) {
      AppLogger.log('❌ Socket.IO initialization error: $e');
      _scheduleReconnection();
    }
  }

  void _setupSocketListeners() {
    AppLogger.log('📡 Setting up Socket.IO listeners...');

    // Listen for new messages
    _messageSubscription?.cancel();
    _messageSubscription = SocketIOService.instance.messageStream.listen(
      (message) {
        AppLogger.log('📨 Received real-time message: ${message.content}');
        if (mounted) {
          setState(() {
            // Avoid duplicates - check if message already exists
            final exists = _messages.any((m) => m.id == message.id);
            if (!exists) {
              _messages.add(message);
              AppLogger.log('➕ Added message to list: ${message.content}');
            } else {
              AppLogger.log('⚠️ Duplicate message ignored: ${message.id}');
            }
          });
          _scrollToBottom();

          // Mark as read if from other user
          if (message.senderId != _currentUserId) {
            MessageService.markMessagesAsRead(widget.conversationId);
          }
        }
      },
      onError: (error) {
        AppLogger.log('❌ Message stream error: $error');
      },
    );

    // Listen for typing indicators
    _typingSubscription?.cancel();
    _typingSubscription = SocketIOService.instance.typingStream.listen(
      (data) {
        AppLogger.log('⌨️ Typing indicator: $data');
        if (mounted && data['conversationId'] == widget.conversationId) {
          setState(() {
            if (data['type'] == 'typing_start' &&
                data['userId'] != _currentUserId) {
              _otherUserTyping = true;
              _typingUserName = data['userName'];
            } else if (data['type'] == 'typing_stop') {
              _otherUserTyping = false;
              _typingUserName = null;
            }
          });
        }
      },
      onError: (error) {
        AppLogger.log('❌ Typing stream error: $error');
      },
    );
  }

  void _joinConversation() {
    if (SocketIOService.instance.isConnected) {
      SocketIOService.instance.joinConversation(widget.conversationId);
      AppLogger.log('🏠 Joined conversation: ${widget.conversationId}');
    } else {
      AppLogger.log('❌ Cannot join conversation: Socket.IO not connected');
    }
  }

  void _scheduleReconnection() {
    _connectionRetryTimer?.cancel();
    _connectionRetryTimer = Timer(Duration(seconds: 5), () {
      if (mounted && !SocketIOService.instance.isConnected) {
        AppLogger.log('🔄 Attempting Socket.IO reconnection...');
        _initializeSocketIO();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      AppLogger.log(
          '📨 Loading messages for conversation ${widget.conversationId}');

      final messages = await MessageService.getMessages(widget.conversationId)
          .timeout(Duration(seconds: 15));

      AppLogger.log('✅ Loaded ${messages.length} messages');

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
        _scrollToBottom();
      }

      // Mark messages as read
      await MessageService.markMessagesAsRead(widget.conversationId);
    } catch (e) {
      AppLogger.log('❌ Error loading messages: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load messages: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    AppLogger.log('📤 Sending message: "$content"');

    setState(() {
      _isSending = true;
    });

    try {
      // Stop typing indicator
      if (SocketIOService.instance.isConnected) {
        SocketIOService.instance.stopTyping(widget.conversationId);
      }

      // Clear the input immediately for better UX
      _messageController.clear();

      // Send via HTTP API first (more reliable)
      final sentMessage =
          await MessageService.sendMessage(widget.conversationId, content)
              .timeout(Duration(seconds: 15));

      AppLogger.log('✅ Message sent via HTTP: ${sentMessage.id}');

      // If Socket.IO is connected, it will broadcast and we'll receive via stream
      // If not connected, manually add to list
      if (!SocketIOService.instance.isConnected) {
        AppLogger.log('⚠️ Socket.IO not connected, adding message manually');
        if (mounted) {
          setState(() {
            _messages.add(sentMessage);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      AppLogger.log('❌ Failed to send message: $e');

      // Restore message content on error
      if (mounted) {
        _messageController.text = content;
        _showErrorSnackBar('Failed to send message: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && SocketIOService.instance.isConnected) {
      // Start typing indicator
      SocketIOService.instance.startTyping(widget.conversationId);

      // Reset the typing timer
      _typingTimer?.cancel();
      _typingTimer = Timer(Duration(seconds: 2), () {
        SocketIOService.instance.stopTyping(widget.conversationId);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            _initializeChat();
          },
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    AppLogger.log('🧹 Disposing ChatScreen...');

    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _connectionRetryTimer?.cancel();

    // Leave conversation
    if (SocketIOService.instance.isConnected) {
      SocketIOService.instance.leaveConversation();
    }

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.otherUserName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // Connection status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: SocketIOService.instance.isConnected
                        ? Colors.green
                        : _isConnecting
                            ? Colors.orange
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (_otherUserTyping && _typingUserName != null)
              Text(
                'typing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[300],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Debug info button
          if (env != 'production')
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                _showDebugInfo();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          if (_isConnecting)
            Container(
              width: double.infinity,
              color: Colors.orange,
              padding: EdgeInsets.all(8),
              child: Text(
                'Connecting to real-time chat...',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

          if (!SocketIOService.instance.isConnected && !_isConnecting)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Real-time chat disconnected. Messages will still be sent.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _initializeSocketIO,
                    child: Text(
                      'RECONNECT',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading messages...'),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet. Start the conversation!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMyMessage =
                                message.senderId == _currentUserId;
                            final showTime = index == 0 ||
                                _messages[index - 1]
                                        .createdAt
                                        .difference(message.createdAt)
                                        .inMinutes
                                        .abs() >
                                    5;

                            return Column(
                              children: [
                                if (showTime)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      _formatMessageTime(message.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                _buildMessageBubble(message, isMyMessage),
                              ],
                            );
                          },
                        ),
                      ),
          ),

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSending,
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _isSending
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
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

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              isMyMessage ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMyMessage ? Radius.circular(4) : null,
            bottomLeft: !isMyMessage ? Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.createdAt),
                  style: TextStyle(
                    color: isMyMessage
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                if (isMyMessage) ...[
                  SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead
                        ? Colors.blue[200]
                        : Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conversation ID: ${widget.conversationId}'),
            Text('Current User ID: $_currentUserId'),
            Text(
                'Socket.IO Connected: ${SocketIOService.instance.isConnected}'),
            Text('Messages Count: ${_messages.length}'),
            Text('Is Loading: $_isLoading'),
            Text('Is Sending: $_isSending'),
            Text('Is Connecting: $_isConnecting'),
            Text('Other User Typing: $_otherUserTyping'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SocketIOService.instance.sendTestMessage('Test from ChatScreen');
            },
            child: Text('Send Test'),
          ),
        ],
      ),
    );
  }
}
