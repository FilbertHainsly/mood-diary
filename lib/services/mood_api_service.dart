import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/mood_result.dart';

// Service untuk memprediksi mood menggunakan model emotion classifier
// Bahasa Indonesia dari HuggingFace Inference API.
class MoodApiService {
  // Model RoBERTa fine-tuned untuk klasifikasi emosi Bahasa Indonesia.
  // Label output: sadness, anger, happy, love, fear.
  static const String _modelId =
      'StevenLimcorn/indonesian-roberta-base-emotion-classifier';
  static const String _baseUrl =
      'https://api-inference.huggingface.co/models/$_modelId';

  // GANTI dengan HuggingFace API token milikmu.
  // Cara mendapatkan: https://huggingface.co/settings/tokens (buat token "Read").
  static const String _hfToken = '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';

  static const Duration _timeout = Duration(seconds: 30);

  Future<MoodResult> predictMood(String text) async {
    if (text.trim().isEmpty) {
      throw 'Teks diary tidak boleh kosong';
    }

    try {
      var response = await _callHf(text);

      // Model di HF kadang "cold start" (status 503) sampai container siap.
      // Tunggu sebentar lalu coba sekali lagi.
      if (response.statusCode == 503) {
        await Future.delayed(const Duration(seconds: 5));
        response = await _callHf(text);
      }

      if (response.statusCode == 200) {
        return _parseHfResponse(response.body);
      } else {
        throw 'API error (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      // Fallback: jika token belum diset / API gagal, gunakan dummy
      // keyword predictor supaya app tetap dapat didemonstrasikan.
      return _mockPredict(text);
    }
  }

  Future<http.Response> _callHf(String text) {
    return http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_hfToken',
          },
          body: jsonEncode({'inputs': text}),
        )
        .timeout(_timeout);
  }

  // Response dari HF: [[ {label, score}, {label, score}, ... ]]
  MoodResult _parseHfResponse(String body) {
    final decoded = jsonDecode(body);
    final outer = decoded as List<dynamic>;
    final predictions = outer.first as List<dynamic>;

    Map<String, dynamic>? best;
    double bestScore = -1;
    for (final p in predictions) {
      final m = p as Map<String, dynamic>;
      final score = (m['score'] as num).toDouble();
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }

    final rawLabel = (best?['label'] ?? 'neutral').toString();
    return MoodResult(
      mood: _mapLabel(rawLabel),
      confidence: bestScore < 0 ? 0.0 : bestScore,
    );
  }

  // Mapping label HuggingFace -> nama mood yang dipakai UI (AppTheme).
  String _mapLabel(String label) {
    switch (label.toLowerCase()) {
      case 'sadness':
      case 'sad':
        return 'Sad';
      case 'anger':
      case 'angry':
        return 'Angry';
      case 'fear':
        return 'Fear';
      case 'happy':
      case 'joy':
        return 'Happy';
      case 'love':
        return 'Love';
      default:
        return 'Neutral';
    }
  }

  // === FALLBACK DUMMY PREDICTOR ===
  // Dipakai kalau API token belum diset atau request gagal.
  MoodResult _mockPredict(String text) {
    final lower = text.toLowerCase();
    final moodKeywords = <String, List<String>>{
      'Happy': ['senang', 'bahagia', 'gembira', 'happy', 'asyik', 'seru'],
      'Sad': ['sedih', 'kecewa', 'menangis', 'sad', 'galau', 'kesepian'],
      'Angry': ['marah', 'kesal', 'sebel', 'angry', 'jengkel', 'benci'],
      'Fear': ['takut', 'cemas', 'khawatir', 'fear', 'panik', 'gugup'],
      'Love': ['cinta', 'sayang', 'love', 'rindu', 'kangen'],
      'Neutral': ['biasa', 'oke', 'normal', 'datar'],
    };

    String detected = 'Neutral';
    int maxHits = 0;
    moodKeywords.forEach((mood, keywords) {
      final hits = keywords.where((k) => lower.contains(k)).length;
      if (hits > maxHits) {
        maxHits = hits;
        detected = mood;
      }
    });

    final rand = Random();
    final confidence = 0.65 + rand.nextDouble() * 0.30;
    return MoodResult(mood: detected, confidence: confidence);
  }
}
