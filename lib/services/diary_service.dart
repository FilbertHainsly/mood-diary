import 'dart:io';

import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../models/mood_result.dart';
import 'firestore_service.dart';
import 'mood_api_service.dart';
import 'storage_service.dart';

class DiaryService extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final MoodApiService _moodApi = MoodApiService();
  final StorageService _storage = StorageService();

  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;

  MoodResult? _lastResult;
  String _lastDiaryText = '';
  String? _lastImageUrl;
  DateTime? _lastAnalyzedAt;

  bool get isAnalyzing => _isAnalyzing;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  MoodResult? get lastResult => _lastResult;
  String get lastDiaryText => _lastDiaryText;
  String? get lastImageUrl => _lastImageUrl;
  DateTime? get lastAnalyzedAt => _lastAnalyzedAt;

  // =====================================================
  // ANALYZE + SAVE DIARY
  // =====================================================

  Future<bool> analyzeAndSave({
    required String userId,
    required String title,
    required String diaryText,
    File? imageFile,
  }) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storage.uploadDiaryImage(
          userId: userId,
          file: imageFile,
        );
      }

      final result = await _moodApi.predictMood(diaryText);

      _lastResult = result;
      _lastDiaryText = diaryText;
      _lastImageUrl = imageUrl;
      _lastAnalyzedAt = DateTime.now();

      final entry = DiaryEntry(
        id: '',
        userId: userId,
        title: title,
        diaryText: diaryText,
        mood: result.mood,
        confidence: result.confidence,
        recommendation: result.recommendation,
        imageUrl: imageUrl,
        createdAt: _lastAnalyzedAt!,
      );

      await _firestoreService.addDiary(entry);

      _isAnalyzing = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      _isAnalyzing = false;
      notifyListeners();

      return false;
    }
  }

  // =====================================================
  // GET ALL DIARIES
  // =====================================================

  Stream<List<DiaryEntry>> watchDiaries(String userId) {
    return _firestoreService.getDiaries(userId);
  }

  // =====================================================
  // UPDATE DIARY
  // =====================================================

  Future<bool> updateDiary({
    required String id,
    required String title,
    required String diaryText,
    String? newImageUrl,
    String? oldImageUrlToDelete,
    bool removeImage = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final data = <String, dynamic>{
        'title': title,
        'diaryText': diaryText,
      };

      if (removeImage) {
        data['imageUrl'] = null;
      } else if (newImageUrl != null) {
        data['imageUrl'] = newImageUrl;
      }

      await _firestoreService.updateDiary(
        id: id,
        data: data,
      );

      if (oldImageUrlToDelete != null && oldImageUrlToDelete.isNotEmpty) {
        await _storage.deleteImageByUrl(oldImageUrlToDelete);
      }

      _isSaving = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();

      _isSaving = false;
      notifyListeners();

      return false;
    }
  }

  // =====================================================
  // UPLOAD IMAGE (untuk edit screen)
  // =====================================================

  Future<String?> uploadImage({
    required String userId,
    required File file,
  }) async {
    try {
      return await _storage.uploadDiaryImage(userId: userId, file: file);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // =====================================================
  // DELETE DIARY
  // =====================================================

  Future<bool> deleteDiary(String id, {String? imageUrl}) async {
    try {
      await _firestoreService.deleteDiary(id);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storage.deleteImageByUrl(imageUrl);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    }
  }

  // =====================================================
  // SEARCH DIARY
  // =====================================================

  List<DiaryEntry> searchDiaries(
    List<DiaryEntry> diaries,
    String query,
  ) {
    if (query.trim().isEmpty) return diaries;

    final keyword = query.toLowerCase();

    return diaries.where((diary) {
      return diary.title.toLowerCase().contains(keyword) ||
          diary.diaryText.toLowerCase().contains(keyword) ||
          diary.mood.toLowerCase().contains(keyword);
    }).toList();
  }

  // =====================================================
  // CLEAR LAST RESULT
  // =====================================================

  void clearLastResult() {
    _lastResult = null;
    _lastDiaryText = '';
    _lastImageUrl = null;
    _lastAnalyzedAt = null;

    notifyListeners();
  }
}
