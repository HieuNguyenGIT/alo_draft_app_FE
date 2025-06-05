class Contact {
  final int id;
  final String phoneNumber;
  final String origin; // Source ID (0-21) - where contact data was stored
  final DateTime contactDate;
  final bool isNew;
  final String accessUrl;
  final int contactStatus; // 0=null, 1=contacted, 2=purchased
  final int contactHideStatus; // 0=visible, 1=hidden
  final String contactIp; // IP address (separate from origin)

  Contact({
    required this.id,
    required this.phoneNumber,
    required this.origin,
    required this.contactDate,
    required this.isNew,
    required this.accessUrl,
    required this.contactStatus,
    required this.contactHideStatus,
    required this.contactIp,
  });

  // Origin ID to Name mapping
  static const Map<String, String> originMapping = {
    '0': 'Nhận diện số',
    '1': 'Popup nút gọi',
    '2': 'Popup voucher',
    '3': 'Popup lái thử',
    '4': 'Popup báo giá',
    '5': 'Báo giá lăn bánh',
    '6': 'Báo giá trả góp',
    '10': 'Báo giá sản phẩm',
    '20': 'Leadform',
    '21': 'Google',
  };

  // Get origin name from ID
  String get originName => originMapping[origin] ?? 'Unknown';

  // Contact status names
  String get statusName {
    switch (contactStatus) {
      case 0:
        return 'Chưa liên hệ';
      case 1:
        return 'Đã liên hệ';
      case 2:
        return 'Đã mua hàng';
      default:
        return 'Unknown';
    }
  }

  Contact copyWith({
    int? id,
    String? phoneNumber,
    String? origin,
    DateTime? contactDate,
    bool? isNew,
    String? accessUrl,
    int? contactStatus,
    int? contactHideStatus,
    String? contactIp,
  }) {
    return Contact(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      origin: origin ?? this.origin,
      contactDate: contactDate ?? this.contactDate,
      isNew: isNew ?? this.isNew,
      accessUrl: accessUrl ?? this.accessUrl,
      contactStatus: contactStatus ?? this.contactStatus,
      contactHideStatus: contactHideStatus ?? this.contactHideStatus,
      contactIp: contactIp ?? this.contactIp,
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      phoneNumber: json['phone_number'],
      origin: json['origin'].toString(),
      contactDate: DateTime.parse(json['contact_date']),
      isNew: json['is_new'] == 1 || json['is_new'] == true,
      accessUrl: json['access_url'] ?? '',
      contactStatus: json['contact_status'] ?? 0,
      contactHideStatus: json['contact_hide_status'] ?? 0,
      contactIp: json['contact_ip'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'origin': origin,
      'contact_date': contactDate.toIso8601String(),
      'is_new': isNew ? 1 : 0,
      'access_url': accessUrl,
      'contact_status': contactStatus,
      'contact_hide_status': contactHideStatus,
      'contact_ip': contactIp,
    };
  }
}
