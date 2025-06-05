abstract class ContactEvent {}

class ContactsLoaded extends ContactEvent {}

class ContactHidden extends ContactEvent {
  final int contactId;
  ContactHidden(this.contactId);
}

class ContactStatusUpdated extends ContactEvent {
  final int contactId;
  final int newStatus;
  ContactStatusUpdated(this.contactId, this.newStatus);
}

class ContactsFiltered extends ContactEvent {
  final String? sourceFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  ContactsFiltered({
    this.sourceFilter,
    this.startDate,
    this.endDate,
  });
}
