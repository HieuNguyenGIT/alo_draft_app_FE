import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:alo_draft_app/services/message_service.dart';
import 'package:alo_draft_app/services/websocket_service.dart';
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
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  int? _currentUserId;
  Timer? _typingTimer;
  bool _otherUserTyping = false;
  String? _typingUserName;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Get current user ID
      _currentUserId = await SharedPreferencesHelper.getUserId();

      // Connect to WebSocket if not connected
      if (!WebSocketService.instance.isConnected) {
        await WebSocketService.instance.connect();
      }

      // Join this conversation
      WebSocketService.instance.joinConversation(widget.conversationId);

      // Load initial messages
      await _loadMessages();

      // Listen for new messages
      _messageSubscription =
          WebSocketService.instance.messageStream.listen((message) {
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();

          // Mark as read if from other user
          if (message.senderId != _currentUserId) {
            MessageService.markMessagesAsRead(widget.conversationId);
          }
        }
      });

      // Listen for typing indicators
      _typingSubscription =
          WebSocketService.instance.typingStream.listen((data) {
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
      });

      // Mark messages as read
      await MessageService.markMessagesAsRead(widget.conversationId);
    } catch (e) {
      AppLogger.log('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat: $e')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await MessageService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Stop typing indicator
      WebSocketService.instance.stopTyping(widget.conversationId);

      // Clear the input immediately for better UX
      _messageController.clear();

      // Send the message
      await MessageService.sendMessage(widget.conversationId, content);

      // Note: Message will be added via WebSocket stream, not here
      _scrollToBottom();
    } catch (e) {
      // Restore message content on error
      _messageController.text = content;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      // Start typing indicator
      WebSocketService.instance.startTyping(widget.conversationId);

      // Reset the typing timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        WebSocketService.instance.stopTyping(widget.conversationId);
      });
    }
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
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    WebSocketService.instance.leaveConversation();
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
            Text(
              widget.otherUserName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
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

          // Message Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              isMyMessage ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMyMessage ? const Radius.circular(4) : null,
            bottomLeft: !isMyMessage ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMyMessage ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
