class Message {
  final int id;
  final String senderName;
  final String lastMessage;
  final DateTime timestamp;
  final bool isRead;
  final String avatarUrl;

  Message({
    required this.id,
    required this.senderName,
    required this.lastMessage,
    required this.timestamp,
    required this.isRead,
    required this.avatarUrl,
  });
}
