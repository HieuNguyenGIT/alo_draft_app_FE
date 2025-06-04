import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/message/message_event.dart';
import 'package:alo_draft_app/blocs/message/message_state.dart';
import 'package:alo_draft_app/services/message_service.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  MessageBloc() : super(MessageInitial()) {
    on<ConversationsLoaded>(_onConversationsLoaded);
    on<ConversationRefreshed>(_onConversationRefreshed);
  }

  void _onConversationsLoaded(
      ConversationsLoaded event, Emitter<MessageState> emit) async {
    emit(MessageLoading());
    try {
      final conversations = await MessageService.getConversations();
      emit(MessageLoaded(conversations));
    } catch (e) {
      emit(MessageFailure(e.toString()));
    }
  }

  void _onConversationRefreshed(
      ConversationRefreshed event, Emitter<MessageState> emit) async {
    try {
      final conversations = await MessageService.getConversations();
      emit(MessageLoaded(conversations));
    } catch (e) {
      emit(MessageFailure(e.toString()));
    }
  }
}
