import 'package:alo_draft_app/blocs/contact/contact_event.dart';
import 'package:alo_draft_app/blocs/contact/contact_state.dart';
import 'package:alo_draft_app/models/contact_model.dart';
import 'package:alo_draft_app/services/contact_service.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  final ContactService _contactService = ContactService();
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];

  ContactBloc() : super(ContactInitial()) {
    on<ContactsLoaded>(_onContactsLoaded);
    on<ContactHidden>(_onContactHidden);
    on<ContactStatusUpdated>(_onContactStatusUpdated);
    on<ContactsFiltered>(_onContactsFiltered);
  }

  void _onContactsLoaded(
      ContactsLoaded event, Emitter<ContactState> emit) async {
    emit(ContactLoading());
    try {
      AppLogger.log('Loading contacts from API...');

      // Try to fetch from API first, fallback to mock data
      final contacts = await _contactService.getContacts();

      // Filter out hidden contacts
      _allContacts =
          contacts.where((contact) => contact.contactHideStatus == 0).toList();
      _filteredContacts = List.from(_allContacts);

      AppLogger.log('Loaded ${_allContacts.length} contacts');
      emit(ContactLoaded(_filteredContacts));
    } catch (e) {
      AppLogger.log('Error loading contacts: $e');
      emit(ContactFailure(e.toString()));
    }
  }

  void _onContactHidden(ContactHidden event, Emitter<ContactState> emit) async {
    try {
      AppLogger.log('Hiding contact with ID: ${event.contactId}');

      // Try to update on server
      await _contactService.hideContact(event.contactId);

      // Update local data
      _allContacts = _allContacts
          .where((contact) => contact.id != event.contactId)
          .toList();
      _filteredContacts = _filteredContacts
          .where((contact) => contact.id != event.contactId)
          .toList();

      emit(ContactLoaded(_filteredContacts));
    } catch (e) {
      AppLogger.log('Error hiding contact: $e');
      emit(ContactFailure(e.toString()));
    }
  }

  void _onContactStatusUpdated(
      ContactStatusUpdated event, Emitter<ContactState> emit) async {
    try {
      AppLogger.log(
          'Updating contact ${event.contactId} status to ${event.newStatus}');

      // Try to update on server
      await _contactService.updateContactStatus(
          event.contactId, event.newStatus);

      // Update local data
      _allContacts = _allContacts.map((contact) {
        if (contact.id == event.contactId) {
          return contact.copyWith(contactStatus: event.newStatus);
        }
        return contact;
      }).toList();

      _filteredContacts = _filteredContacts.map((contact) {
        if (contact.id == event.contactId) {
          return contact.copyWith(contactStatus: event.newStatus);
        }
        return contact;
      }).toList();

      emit(ContactLoaded(_filteredContacts));
    } catch (e) {
      AppLogger.log('Error updating contact status: $e');
      emit(ContactFailure(e.toString()));
    }
  }

  void _onContactsFiltered(ContactsFiltered event, Emitter<ContactState> emit) {
    AppLogger.log(
        'Filtering contacts - Source: ${event.sourceFilter}, Start: ${event.startDate}, End: ${event.endDate}');

    List<Contact> filtered = List.from(_allContacts);

    // Filter by source
    if (event.sourceFilter != null && event.sourceFilter!.isNotEmpty) {
      filtered = filtered
          .where((contact) => contact.origin == event.sourceFilter)
          .toList();
    }

    // Filter by date range
    if (event.startDate != null && event.endDate != null) {
      filtered = filtered.where((contact) {
        final contactDate = contact.contactDate;
        return contactDate.isAfter(event.startDate!) &&
            contactDate.isBefore(event.endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    _filteredContacts = filtered;
    AppLogger.log('Filtered result: ${_filteredContacts.length} contacts');
    emit(ContactLoaded(_filteredContacts));
  }

  // Helper method to get mock data
  List<Contact> getMockContacts() {
    return [
      Contact(
        id: 1,
        phoneNumber: '0988 365 247',
        origin: '0', // Nhận diện số
        contactDate: DateTime.now().subtract(const Duration(hours: 2)),
        isNew: true,
        accessUrl: 'https://nguyenhung2802.github.io/Web-the-band/',
        contactStatus: 0,
        contactHideStatus: 0,
        contactIp: '14.162.167.144',
      ),
      Contact(
        id: 2,
        phoneNumber: '+84 987 654 321',
        origin: '4', // Popup báo giá
        contactDate: DateTime.now().subtract(const Duration(days: 1)),
        isNew: false,
        accessUrl: 'https://example.com/pricing',
        contactStatus: 1,
        contactHideStatus: 0,
        contactIp: '10.0.0.123',
      ),
      Contact(
        id: 3,
        phoneNumber: '+84 123 456 789',
        origin: '21', // Google
        contactDate: DateTime.now().subtract(const Duration(hours: 5)),
        isNew: true,
        accessUrl: 'https://google.com/ads/landing',
        contactStatus: 0,
        contactHideStatus: 0,
        contactIp: '172.16.254.1',
      ),
      Contact(
        id: 4,
        phoneNumber: '+84 555 666 777',
        origin: '20', // Leadform
        contactDate: DateTime.now().subtract(const Duration(days: 3)),
        isNew: false,
        accessUrl: 'https://leadform.example.com',
        contactStatus: 2,
        contactHideStatus: 0,
        contactIp: '203.0.113.42',
      ),
      Contact(
        id: 5,
        phoneNumber: '+84 999 888 777',
        origin: '1', // Popup nút gọi
        contactDate: DateTime.now().subtract(const Duration(minutes: 30)),
        isNew: true,
        accessUrl: 'https://example.com/call-popup',
        contactStatus: 0,
        contactHideStatus: 0,
        contactIp: '198.51.100.78',
      ),
      Contact(
        id: 6,
        phoneNumber: '+84 444 333 222',
        origin: '10', // Báo giá sản phẩm
        contactDate: DateTime.now().subtract(const Duration(hours: 12)),
        isNew: false,
        accessUrl: 'https://example.com/product-quote',
        contactStatus: 1,
        contactHideStatus: 0,
        contactIp: '233.252.0.156',
      ),
    ];
  }
}
