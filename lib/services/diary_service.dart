import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../models/mood_result.dart';
import 'firestore_service.dart';
import 'mood_api_service.dart';

class DiaryService extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final MoodApiService _moodApi = MoodApiService();

  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;

  MoodResult? _lastResult;
  String _lastDiaryText = '';
  DateTime? _lastAnalyzedAt;

  bool get isAnalyzing => _isAnalyzing;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  MoodResult? get lastResult => _lastResult;
  String get lastDiaryText => _lastDiaryText;
  DateTime? get lastAnalyzedAt => _lastAnalyzedAt;

  // =====================================================
  // ANALYZE + SAVE DIARY
  // =====================================================

  Future<bool> analyzeAndSave({
    required String userId,
    required String title,
    required String diaryText,
  }) async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _moodApi.predictMood(diaryText);

      _lastResult = result;
      _lastDiaryText = diaryText;
      _lastAnalyzedAt = DateTime.now();

      final entry = DiaryEntry(
        id: '',
        userId: userId,
        title: title,
        diaryText: diaryText,
        mood: result.mood,
        confidence: result.confidence,
        recommendation: result.recommendation,
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
  }) async {
    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _firestoreService.updateDiary(
        id: id,
        data: {
          'title': title,
          'diaryText': diaryText,
        },
      );

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
  // RE-ANALYZE AND UPDATE DIARY
  // =====================================================

  Future<bool> reanalyzeAndUpdate({
    required String id,
    required String title,
    required String newDiaryText,
    required String oldDiaryText,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'title': title,
        'diaryText': newDiaryText,
      };

      if (newDiaryText.trim() != oldDiaryText.trim()) {
        final result = await _moodApi.predictMood(newDiaryText);
        data['mood'] = result.mood;
        data['confidence'] = result.confidence;
        data['recommendation'] = result.recommendation;
      }

      await _firestoreService.updateDiary(id: id, data: data);

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
  // DELETE DIARY
  // =====================================================

  Future<bool> deleteDiary(String id) async {
    try {
      await _firestoreService.deleteDiary(id);
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
    _lastAnalyzedAt = null;

    notifyListeners();
  }
}