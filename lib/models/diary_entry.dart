import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String id;

  final String userId;

  // Judul diary
  final String title;

  // Isi diary
  final String diaryText;

  // Apakah diary sudah dienkripsi
  final bool isEncrypted;

  // Hasil analisis
  final String mood;
  final double confidence;

  // Rekomendasi AI
  final String recommendation;

  // Timestamp
  final DateTime createdAt;

  const DiaryEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.diaryText,
    required this.createdAt,
    required this.mood,
    required this.confidence,

    this.recommendation = '',
    this.isEncrypted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'diaryText': diaryText,
      'isEncrypted': isEncrypted,
      'mood': mood,
      'confidence': confidence,
      'recommendation': recommendation,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DiaryEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DiaryEntry(
      id: doc.id,

      userId: data['userId'] ?? '',

      title: data['title'] ?? '',

      diaryText: data['diaryText'] ?? '',

      isEncrypted: data['isEncrypted'] ?? false,

      mood: data['mood'] ?? '',

      confidence: (data['confidence'] is num)
          ? (data['confidence'] as num).toDouble()
          : 0.0,

      recommendation:
          data['recommendation']?.toString() ?? '',

      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  DiaryEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? diaryText,
    bool? isEncrypted,
    String? mood,
    double? confidence,
    String? recommendation,
    DateTime? createdAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      diaryText: diaryText ?? this.diaryText,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      mood: mood ?? this.mood,
      confidence: confidence ?? this.confidence,
      recommendation:
          recommendation ?? this.recommendation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}