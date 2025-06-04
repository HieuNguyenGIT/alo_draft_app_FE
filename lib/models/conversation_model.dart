class Conversation {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;
  final String otherUserEmail;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int? lastMessageSenderId;
  final int unreadCount;
  final DateTime lastActivity;

  Conversation({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.lastActivity,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversation_id'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      otherUserEmail: json['other_user_email'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      lastMessageSenderId: json['last_message_sender_id'],
      unreadCount: json['unread_count'] ?? 0,
      lastActivity: DateTime.parse(json['last_activity']),
    );
  }
}
