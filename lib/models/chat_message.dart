import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender { user, bot }

class ChatMessage {
  final String messageId;
  final String sessionId;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.messageId,
    required this.sessionId,
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'content': content,
      'sender': sender == MessageSender.user ? 'user' : 'bot',
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      messageId: doc.id,
      sessionId: data['sessionId'] ?? '',
      content: data['content'] ?? '',
      sender: data['sender'] == 'user' ? MessageSender.user : MessageSender.bot,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
