import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _diariesRef =>
      _firestore.collection('diaries');

  // =====================================================
  // CREATE
  // =====================================================

  Future<String> addDiary(DiaryEntry entry) async {
    try {
      final docRef = await _diariesRef.add(entry.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Gagal menyimpan diary: $e';
    }
  }

  // =====================================================
  // READ - REALTIME LIST
  // =====================================================

  Stream<List<DiaryEntry>> getDiaries(String userId) {
    return _diariesRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DiaryEntry.fromDoc(doc))
              .toList(),
        );
  }

  // =====================================================
  // READ - SINGLE DIARY
  // =====================================================

  Future<DiaryEntry?> getDiaryById(String id) async {
    try {
      final doc = await _diariesRef.doc(id).get();

      if (!doc.exists) return null;

      return DiaryEntry.fromDoc(doc);
    } catch (e) {
      throw 'Gagal mengambil diary: $e';
    }
  }

  // =====================================================
  // READ - LATEST DIARY
  // =====================================================

  Future<DiaryEntry?> getLatestDiary(String userId) async {
    try {
      final snapshot = await _diariesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return DiaryEntry.fromDoc(snapshot.docs.first);
    } catch (e) {
      throw 'Gagal mengambil diary terakhir: $e';
    }
  }

  // =====================================================
  // READ - LATEST N DIARIES (tanpa batasan waktu)
  // =====================================================

  Future<List<DiaryEntry>> getLatestDiaries(
    String userId, {
    int limit = 3,
  }) async {
    try {
      final snapshot = await _diariesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => DiaryEntry.fromDoc(doc)).toList();
    } catch (e) {
      throw 'Gagal mengambil diary terbaru: $e';
    }
  }

  // =====================================================
  // READ - TOTAL DIARY
  // =====================================================

  Future<int> getDiaryCount(String userId) async {
    try {
      final snapshot = await _diariesRef
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw 'Gagal menghitung diary: $e';
    }
  }

  // =====================================================
  // READ - WEEKLY DIARIES
  // =====================================================

  Future<List<DiaryEntry>> getWeeklyDiaries(
    String userId,
  ) async {
    try {
      final weekAgo = DateTime.now().subtract(
        const Duration(days: 7),
      );

      final snapshot = await _diariesRef
          .where('userId', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(weekAgo),
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DiaryEntry.fromDoc(doc))
          .toList();
    } catch (e) {
      throw 'Gagal mengambil diary mingguan: $e';
    }
  }

  // =====================================================
  // READ - MONTHLY DIARIES
  // =====================================================

  Future<List<DiaryEntry>> getMonthlyDiaries(
    String userId,
  ) async {
    try {
      final monthAgo = DateTime.now().subtract(
        const Duration(days: 30),
      );

      final snapshot = await _diariesRef
          .where('userId', isEqualTo: userId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(monthAgo),
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DiaryEntry.fromDoc(doc))
          .toList();
    } catch (e) {
      throw 'Gagal mengambil diary bulanan: $e';
    }
  }

  // =====================================================
  // UPDATE
  // =====================================================

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

  // =====================================================
  // DELETE
  // =====================================================

  Future<void> deleteDiary(String id) async {
    try {
      await _diariesRef.doc(id).delete();
    } catch (e) {
      throw 'Gagal menghapus diary: $e';
    }
  }
}