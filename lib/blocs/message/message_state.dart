import 'package:alo_draft_app/models/conversation_model.dart';

abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<Conversation> conversations;
  MessageLoaded(this.conversations);
}

class MessageFailure extends MessageState {
  final String error;
  MessageFailure(this.error);
}
