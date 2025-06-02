import 'package:alo_draft_app/blocs/message/message_event.dart';
import 'package:alo_draft_app/blocs/message/message_state.dart';
import 'package:alo_draft_app/models/message_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc() : super(MessageInitial()) {
    on<MessagesLoaded>(_onMessagesLoaded);
  }

  void _onMessagesLoaded(
      MessagesLoaded event, Emitter<MessageState> emit) async {
    emit(MessageLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      final messages = [
        Message(
          id: 1,
          senderName: 'Alice Johnson',
          lastMessage: 'Hey! Are we still meeting for lunch today?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          isRead: false,
          avatarUrl: '',
        ),
        Message(
          id: 2,
          senderName: 'Bob Wilson',
          lastMessage: 'Thanks for the project update!',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          avatarUrl: '',
        ),
        Message(
          id: 3,
          senderName: 'Carol Davis',
          lastMessage: 'Can you review the document I sent?',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          isRead: false,
          avatarUrl: '',
        ),
        Message(
          id: 4,
          senderName: 'David Brown',
          lastMessage: 'Great job on the presentation!',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
          avatarUrl: '',
        ),
        Message(
          id: 5,
          senderName: 'Emma Taylor',
          lastMessage: 'Let me know if you need any help',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isRead: true,
          avatarUrl: '',
        ),
      ];
      emit(MessageLoaded(messages));
    } catch (e) {
      emit(MessageFailure(e.toString()));
    }
  }
}
