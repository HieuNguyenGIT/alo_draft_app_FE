class Contact {
  final int id;
  final String phoneNumber;
  final String phoneNumberOrigin;
  final DateTime contactDate;
  final bool isNew;

  Contact({
    required this.id,
    required this.phoneNumber,
    required this.phoneNumberOrigin,
    required this.contactDate,
    required this.isNew,
  });

  Contact copyWith({
    int? id,
    String? phoneNumber,
    String? phoneNumberOrigin,
    DateTime? contactDate,
    bool? isNew,
  }) {
    return Contact(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumberOrigin: phoneNumberOrigin ?? this.phoneNumberOrigin,
      contactDate: contactDate ?? this.contactDate,
      isNew: isNew ?? this.isNew,
    );
  }
}
