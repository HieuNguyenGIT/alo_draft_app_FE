import 'package:alo_draft_app/blocs/contact/contact_event.dart';
import 'package:alo_draft_app/blocs/contact/contact_state.dart';
import 'package:alo_draft_app/models/contact_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  ContactBloc() : super(ContactInitial()) {
    on<ContactsLoaded>(_onContactsLoaded);
  }

  void _onContactsLoaded(
      ContactsLoaded event, Emitter<ContactState> emit) async {
    emit(ContactLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      final contacts = [
        Contact(
          id: 1,
          phoneNumber: '+1234567890',
          phoneNumberOrigin: '192.168.1.45',
          contactDate: DateTime.now().subtract(const Duration(hours: 2)),
          isNew: true,
        ),
        Contact(
          id: 2,
          phoneNumber: '+0987654321',
          phoneNumberOrigin: '10.0.0.123',
          contactDate: DateTime.now().subtract(const Duration(days: 1)),
          isNew: false,
        ),
        Contact(
          id: 3,
          phoneNumber: '+1122334455',
          phoneNumberOrigin: '172.16.254.1',
          contactDate: DateTime.now().subtract(const Duration(hours: 5)),
          isNew: true,
        ),
        Contact(
          id: 4,
          phoneNumber: '+5566778899',
          phoneNumberOrigin: '203.0.113.42',
          contactDate: DateTime.now().subtract(const Duration(days: 3)),
          isNew: false,
        ),
        Contact(
          id: 5,
          phoneNumber: '+9988776655',
          phoneNumberOrigin: '198.51.100.78',
          contactDate: DateTime.now().subtract(const Duration(minutes: 30)),
          isNew: true,
        ),
        Contact(
          id: 6,
          phoneNumber: '+4433221100',
          phoneNumberOrigin: '233.252.0.156',
          contactDate: DateTime.now().subtract(const Duration(hours: 12)),
          isNew: false,
        ),
      ];
      emit(ContactLoaded(contacts));
    } catch (e) {
      emit(ContactFailure(e.toString()));
    }
  }
}
