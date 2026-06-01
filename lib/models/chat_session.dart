import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSession {
  final String sessionId;
  final String userId;
  final String title;
  final String relatedMood;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  const ChatSession({
    required this.sessionId,
    required this.userId,
    required this.title,
    required this.relatedMood,
    this.isFavorite = false,
    required this.createdAt,
    required this.lastMessageAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'relatedMood': relatedMood,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
    };
  }

  factory ChatSession.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      sessionId: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      relatedMood: data['relatedMood'] ?? 'stable',
      isFavorite: data['isFavorite'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  ChatSession copyWith({
    String? sessionId,
    String? userId,
    String? title,
    String? relatedMood,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return ChatSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      relatedMood: relatedMood ?? this.relatedMood,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}
