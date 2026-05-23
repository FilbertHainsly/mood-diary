import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry.dart';

// Service untuk semua operasi CRUD pada collection "diaries" di Firestore.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referensi ke collection "diaries".
  CollectionReference get _diariesRef => _firestore.collection('diaries');

  // Menambahkan diary baru. Mengembalikan ID dokumen yang baru dibuat.
  Future<String> addDiary(DiaryEntry entry) async {
    try {
      final docRef = await _diariesRef.add(entry.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Gagal menyimpan diary: $e';
    }
  }

  // Stream realtime daftar diary milik user tertentu, terurut dari terbaru.
  // Gunakan ini di StreamBuilder pada History Screen.
  Stream<List<DiaryEntry>> getDiaries(String userId) {
    return _diariesRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DiaryEntry.fromDoc(doc)).toList());
  }

  // Update sebagian data diary (umumnya diaryText).
  Future<void> updateDiary({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _diariesRef.doc(id).update(data);
    } catch (e) {
      throw 'Gagal memperbarui diary: $e';
    }
  }

  // Hapus diary berdasarkan ID dokumen.
  Future<void> deleteDiary(String id) async {
    try {
      await _diariesRef.doc(id).delete();
    } catch (e) {
      throw 'Gagal menghapus diary: $e';
    }
  }
}
