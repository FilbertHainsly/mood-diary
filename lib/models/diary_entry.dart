import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk entri diary yang disimpan di Firestore.
class DiaryEntry {
  final String id;
  final String userId;
  final String diaryText;
  final String mood;
  final double confidence;
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.diaryText,
    required this.mood,
    required this.confidence,
    required this.createdAt,
  });

  // Konversi ke Map untuk disimpan ke Firestore.
  // ID tidak ikut disimpan karena ID adalah document ID di Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'diaryText': diaryText,
      'mood': mood,
      'confidence': confidence,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Membuat objek DiaryEntry dari DocumentSnapshot Firestore.
  factory DiaryEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      diaryText: data['diaryText'] ?? '',
      mood: data['mood'] ?? '',
      confidence: (data['confidence'] is num)
          ? (data['confidence'] as num).toDouble()
          : 0.0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // copyWith untuk memudahkan update sebagian field.
  DiaryEntry copyWith({
    String? id,
    String? userId,
    String? diaryText,
    String? mood,
    double? confidence,
    DateTime? createdAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      diaryText: diaryText ?? this.diaryText,
      mood: mood ?? this.mood,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
