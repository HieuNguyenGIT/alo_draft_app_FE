class Message {
  final int id;
  final String content;
  final int senderId;
  final String senderName;
  final DateTime createdAt;
  final bool isRead;
  final String messageType;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.isRead,
    required this.messageType,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      messageType: json['message_type'] ?? 'text',
    );
  }
}
