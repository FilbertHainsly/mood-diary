import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../models/mood_result.dart';
import 'firestore_service.dart';
import 'mood_api_service.dart';

// ChangeNotifier untuk fitur diary: analisis mood, simpan/update/hapus.
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

  Future<bool> analyzeAndSave({
    required String userId,
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
        diaryText: diaryText,
        mood: result.mood,
        confidence: result.confidence,
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

  Stream<List<DiaryEntry>> watchDiaries(String userId) {
    return _firestoreService.getDiaries(userId);
  }

  Future<bool> updateDiary({
    required String id,
    required String newText,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _firestoreService.updateDiary(
        id: id,
        data: {'diaryText': newText},
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
}
