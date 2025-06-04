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

class _MessagesScreenState extends State<MessagesScreen> {
  late MessageBloc _messageBloc;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _messageBloc = MessageBloc();
    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    try {
      // Get current user ID
      _currentUserId = await SharedPreferencesHelper.getUserId();

      // Connect to WebSocket if not connected
      if (!WebSocketService.instance.isConnected) {
        await WebSocketService.instance.connect();
      }

      // Load conversations
      _messageBloc.add(ConversationsLoaded());
    } catch (e) {
      AppLogger.log('Error initializing messaging: $e');
    }
  }

  @override
  void dispose() {
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
    if (conversation.lastMessage == null) {
      return 'No messages yet';
    }

    final isMyMessage = conversation.lastMessageSenderId == _currentUserId;
    final prefix = isMyMessage ? 'You: ' : '';
    return '$prefix${conversation.lastMessage!}';
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
              if (state.conversations.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async {
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
          heroTag: "message_fab",
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
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
            if (conversation.lastMessageTime != null)
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
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getLastMessagePreview(conversation),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnread ? Colors.black87 : Colors.grey[600],
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (hasUnread)
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
            // Refresh conversations when returning from chat
            context.read<MessageBloc>().add(ConversationRefreshed());
          });
        },
      ),
    );
  }
}
