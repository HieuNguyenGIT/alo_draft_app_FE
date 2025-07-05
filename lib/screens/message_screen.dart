import 'dart:async';

import 'package:alo_draft_app/models/message_model.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/message/message_bloc.dart';
import 'package:alo_draft_app/blocs/message/message_event.dart';
import 'package:alo_draft_app/blocs/message/message_state.dart';
import 'package:alo_draft_app/services/websocket_service.dart';
import 'package:alo_draft_app/models/conversation_model.dart';
import 'package:alo_draft_app/screens/user_search_screen.dart';
import 'package:alo_draft_app/screens/chat_screen.dart';
import 'package:alo_draft_app/util/shared_preferences_helper.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  late MessageBloc _messageBloc;
  int? _currentUserId;

  // Real-time message listening
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;

  // Track typing users per conversation
  final Map<int, String> _typingUsers = {}; // conversationId -> userName

  // Animation controllers for typing dots
  late AnimationController _typingAnimationController;

  // Track conversations for message mapping
  List<Conversation> _currentConversations = [];

  @override
  void initState() {
    super.initState();
    _messageBloc = MessageBloc();

    // Initialize animation controller
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    try {
      // Get current user ID
      _currentUserId = await SharedPreferencesHelper.getUserId();
      AppLogger.log('🆔 Current user ID: $_currentUserId');

      // Connect to WebSocket if not connected
      if (!WebSocketService.instance.isConnected) {
        AppLogger.log('🔗 WebSocket not connected, connecting...');
        await WebSocketService.instance.connect();
        // Wait a bit for authentication
        await Future.delayed(const Duration(seconds: 1));
      }

      // Listen for real-time messages - THIS IS THE KEY FIX
      _messageSubscription = WebSocketService.instance.messageStream.listen(
        (message) {
          AppLogger.log(
              '📨 New message received in conversation list: ${message.content}');
          AppLogger.log(
              '📨 Message sender ID: ${message.senderId}, Current user: $_currentUserId');

          // FIXED: Handle any new message (whether sent by us or received)
          _handleNewMessage(message);
        },
        onError: (error) {
          AppLogger.log('❌ Message stream error in conversation list: $error');
        },
      );

      // Listen for typing indicators
      _typingSubscription = WebSocketService.instance.typingStream.listen(
        (data) {
          AppLogger.log('⌨️ Typing indicator in conversation list: $data');
          _handleTypingIndicator(data);
        },
        onError: (error) {
          AppLogger.log('❌ Typing stream error in conversation list: $error');
        },
      );

      // Load conversations
      _messageBloc.add(ConversationsLoaded());
    } catch (e) {
      AppLogger.log('❌ Error initializing messaging: $e');
    }
  }

  // FIXED: Handle incoming messages properly
  void _handleNewMessage(Message message) {
    AppLogger.log('🔄 Processing new message for conversation list update');
    AppLogger.log(
        '📝 Message: "${message.content}" from sender: ${message.senderId}');

    // Find which conversation this message belongs to
    int? conversationId = _findConversationIdForMessage(message);

    if (conversationId != null) {
      AppLogger.log('✅ Found conversation ID: $conversationId for message');

      // Clear typing indicator for this conversation
      if (_typingUsers.containsKey(conversationId)) {
        setState(() {
          _typingUsers.remove(conversationId);
        });
        AppLogger.log(
            '🔇 Cleared typing indicator for conversation $conversationId');
      }
    } else {
      AppLogger.log(
          '⚠️ Could not find conversation ID for message, refreshing all conversations');
    }

    // Always refresh conversation list to show updated last message
    AppLogger.log('🔄 Refreshing conversation list...');
    _messageBloc.add(ConversationRefreshed());
  }

  // FIXED: Find conversation ID for a message
  int? _findConversationIdForMessage(Message message) {
    for (var conversation in _currentConversations) {
      // Check if this message belongs to this conversation
      if ((conversation.otherUserId == message.senderId &&
              message.senderId != _currentUserId) ||
          (message.senderId == _currentUserId &&
              conversation.otherUserId != _currentUserId)) {
        return conversation.conversationId;
      }
    }
    return null;
  }

  // Handle typing indicators
  void _handleTypingIndicator(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as int?;
    final userId = data['userId'] as int?;
    final userName = data['userName'] as String?;
    final type = data['type'] as String?;

    if (conversationId == null || userId == _currentUserId) return;

    setState(() {
      if (type == 'typing_start' && userName != null) {
        _typingUsers[conversationId] = userName;
        AppLogger.log('👤 $userName is typing in conversation $conversationId');
      } else if (type == 'typing_stop') {
        _typingUsers.remove(conversationId);
        AppLogger.log('👤 Stopped typing in conversation $conversationId');
      }
    });
  }

  @override
  void dispose() {
    // Clean up subscriptions and controllers
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingAnimationController.dispose();
    _messageBloc.close();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _getLastMessagePreview(Conversation conversation) {
    // Show typing indicator if someone is typing
    if (_typingUsers.containsKey(conversation.conversationId)) {
      return '${_typingUsers[conversation.conversationId]} is typing...';
    }

    if (conversation.lastMessage == null) {
      return 'No messages yet';
    }

    final isMyMessage = conversation.lastMessageSenderId == _currentUserId;
    final prefix = isMyMessage ? 'You: ' : '';
    return '$prefix${conversation.lastMessage!}';
  }

  // Get message preview text color
  Color _getMessagePreviewColor(Conversation conversation, bool hasUnread) {
    // Typing indicator gets special color
    if (_typingUsers.containsKey(conversation.conversationId)) {
      return Colors.blue;
    }

    // Unread messages get darker color
    if (hasUnread) {
      return Colors.black87;
    }

    // Regular messages get grey color
    return Colors.grey[600]!;
  }

  // Get message preview font weight
  FontWeight _getMessagePreviewFontWeight(
      Conversation conversation, bool hasUnread) {
    // Typing indicator gets medium weight
    if (_typingUsers.containsKey(conversation.conversationId)) {
      return FontWeight.w500;
    }

    // Unread messages get medium weight
    if (hasUnread) {
      return FontWeight.w500;
    }

    // Regular messages get normal weight
    return FontWeight.normal;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _messageBloc,
      child: Scaffold(
        body: BlocBuilder<MessageBloc, MessageState>(
          builder: (context, state) {
            if (state is MessageLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MessageLoaded) {
              // FIXED: Update current conversations for message mapping
              _currentConversations = state.conversations;
              AppLogger.log(
                  '📋 Updated conversation list with ${state.conversations.length} conversations');

              if (state.conversations.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  AppLogger.log('🔄 Manual refresh triggered');
                  context.read<MessageBloc>().add(ConversationRefreshed());
                },
                child: ListView.builder(
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    return _buildConversationTile(conversation);
                  },
                ),
              );
            }
            if (state is MessageFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.error}'),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MessageBloc>().add(ConversationsLoaded());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return _buildEmptyState();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => const UserSearchScreen(),
              ),
            )
                .then((_) {
              // Refresh conversations when returning from user search
              context.read<MessageBloc>().add(ConversationRefreshed());
            });
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to start a conversation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final hasUnread = conversation.unreadCount > 0;
    final isTyping = _typingUsers.containsKey(conversation.conversationId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor:
                  hasUnread ? Theme.of(context).primaryColor : Colors.grey[300],
              radius: 28,
              child: Text(
                conversation.otherUserName[0].toUpperCase(),
                style: TextStyle(
                  color: hasUnread ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            // Typing indicator on avatar
            if (isTyping)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                conversation.otherUserName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.lastMessageTime != null && !isTyping)
              Text(
                _formatTimestamp(conversation.lastMessageTime!),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread
                      ? Theme.of(context).primaryColor
                      : Colors.grey[500],
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            // Show "typing..." time when user is typing
            if (isTyping)
              Text(
                'now',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Simpler typing animation dots
                    if (isTyping) ...[
                      AnimatedBuilder(
                        animation: _typingAnimationController,
                        builder: (context, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSimpleTypingDot(0),
                              const SizedBox(width: 2),
                              _buildSimpleTypingDot(0.33),
                              const SizedBox(width: 2),
                              _buildSimpleTypingDot(0.66),
                              const SizedBox(width: 8),
                            ],
                          );
                        },
                      ),
                    ],
                    Expanded(
                      child: Text(
                        _getLastMessagePreview(conversation),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              _getMessagePreviewColor(conversation, hasUnread),
                          fontWeight: _getMessagePreviewFontWeight(
                              conversation, hasUnread),
                          fontStyle:
                              isTyping ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread && !isTyping)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(minWidth: 20),
                  child: Text(
                    conversation.unreadCount > 99
                        ? '99+'
                        : conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        onTap: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversation.conversationId,
                otherUserName: conversation.otherUserName,
                otherUserId: conversation.otherUserId,
              ),
            ),
          )
              .then((_) {
            // Clear typing indicator and refresh when returning from chat
            setState(() {
              _typingUsers.remove(conversation.conversationId);
            });
            context.read<MessageBloc>().add(ConversationRefreshed());
          });
        },
      ),
    );
  }

  // Simplified typing indicator dots
  Widget _buildSimpleTypingDot(double delay) {
    final animationValue = (_typingAnimationController.value + delay) % 1.0;
    final opacity =
        (0.3 + 0.7 * (1.0 - (animationValue - 0.5).abs() * 2)).clamp(0.3, 1.0);

    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
