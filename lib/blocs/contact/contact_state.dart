import 'package:alo_draft_app/models/contact_model.dart';

abstract class ContactState {}

class ContactInitial extends ContactState {}

class ContactLoading extends ContactState {}

class ContactLoaded extends ContactState {
  final List<Contact> contacts;
  ContactLoaded(this.contacts);
}

class ContactFailure extends ContactState {
  final String error;
  ContactFailure(this.error);
}
