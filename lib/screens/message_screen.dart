import 'package:alo_draft_app/blocs/message/message_bloc.dart';
import 'package:alo_draft_app/blocs/message/message_event.dart';
import 'package:alo_draft_app/blocs/message/message_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late MessageBloc _messageBloc;

  @override
  void initState() {
    super.initState();
    _messageBloc = MessageBloc();
    _messageBloc.add(MessagesLoaded());
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _messageBloc,
      child: Scaffold(
        body: BlocBuilder<MessageBloc, MessageState>(
          builder: (context, state) {
            if (state is MessageLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is MessageLoaded) {
              if (state.messages.isEmpty) {
                return const Center(
                  child: Text('No messages found'),
                );
              }
              return ListView.builder(
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: message.isRead
                          ? Colors.grey[300]
                          : Theme.of(context).primaryColor,
                      child: Text(
                        message.senderName[0],
                        style: TextStyle(
                          color: message.isRead ? Colors.black54 : Colors.white,
                          fontWeight: message.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: message.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      message.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            message.isRead ? Colors.grey[600] : Colors.black87,
                        fontWeight: message.isRead
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: message.isRead
                                ? Colors.grey[500]
                                : Theme.of(context).primaryColor,
                            fontWeight: message.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        if (!message.isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Handle message tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Opened chat with ${message.senderName}')),
                      );
                    },
                  );
                },
              );
            }
            if (state is MessageFailure) {
              return Center(
                child: Text('Error: ${state.error}'),
              );
            }
            return const Center(
              child: Text('No messages available'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Handle new message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New message feature coming soon!')),
            );
          },
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}
