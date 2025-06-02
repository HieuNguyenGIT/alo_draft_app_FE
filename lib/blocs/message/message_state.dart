import 'package:alo_draft_app/models/message_model.dart';

abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<Message> messages;
  MessageLoaded(this.messages);
}

class MessageFailure extends MessageState {
  final String error;
  MessageFailure(this.error);
}
