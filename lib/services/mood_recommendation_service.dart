import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/secrets.dart';

class MoodRecommendationService {
  static const String _modelName = 'gemini-2.5-flash';

  static final MoodRecommendationService _instance =
      MoodRecommendationService._internal();
  factory MoodRecommendationService() => _instance;
  MoodRecommendationService._internal();

  final Map<String, List<String>> _cache = {};

  late final GenerativeModel _model = GenerativeModel(
    model: _modelName,
    apiKey: Secrets.geminiApiKey,
    generationConfig: GenerationConfig(temperature: 0.7),
    systemInstruction: Content.system(_systemPrompt),
  );

  static const String _systemPrompt = '''
Kamu adalah Moodly — asisten kesehatan mental yang hangat dan praktis.
Tugasmu: berikan rekomendasi singkat, konkret, dan bisa langsung dilakukan
untuk menjaga atau memperbaiki mood seseorang berdasarkan mood dominan mereka.

ATURAN OUTPUT (WAJIB):
- Keluarkan TEPAT 4 rekomendasi.
- Setiap rekomendasi 1 kalimat singkat (maksimal 15 kata), Bahasa Indonesia santai.
- Format: setiap rekomendasi dipisah baris baru, diawali dengan tanda "- " (dash spasi).
- JANGAN beri pembuka, penutup, judul, atau penjelasan tambahan.
- JANGAN gunakan emoji.
- Fokus aksi nyata yang bisa dilakukan hari ini (bukan filosofis).

CONTOH FORMAT (jangan tiru isinya, hanya formatnya):
- Jalan kaki 10 menit di luar ruangan untuk segarkan pikiran.
- Tulis tiga hal yang kamu syukuri hari ini.
- Hubungi satu teman dekat untuk ngobrol ringan.
- Tidur lebih awal malam ini agar tubuh pulih.
''';

  Future<List<String>> getRecommendations(String mood) async {
    final key = mood.toLowerCase().trim();
    if (_cache.containsKey(key)) return _cache[key]!;

    final prompt = _buildPrompt(key);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return _fallback(key);
      }
      final tips = _parse(text);
      if (tips.isEmpty) return _fallback(key);
      _cache[key] = tips;
      return tips;
    } catch (e) {
      debugPrint('[MoodRecommendationService] Gemini error: $e');
      return _fallback(key);
    }
  }

  String _buildPrompt(String mood) {
    switch (mood) {
      case 'positive':
        return 'Mood dominan user: positive. Berikan 4 rekomendasi untuk MEMPERTAHANKAN mood positif ini.';
      case 'depressed':
        return 'Mood dominan user: depressed. Berikan 4 rekomendasi lembut untuk membantu MENGANGKAT mood, hindari nada menggurui.';
      case 'anxious':
        return 'Mood dominan user: anxious. Berikan 4 rekomendasi praktis untuk MENENANGKAN kecemasan.';
      case 'stressed':
        return 'Mood dominan user: stressed. Berikan 4 rekomendasi praktis untuk MENGURANGI stres dan recharge.';
      case 'stable':
        return 'Mood dominan user: stable. Berikan 4 rekomendasi untuk MENJAGA kestabilan dan menambah energi positif.';
      default:
        return 'Mood dominan user: $mood. Berikan 4 rekomendasi untuk menjaga atau memperbaiki mood.';
    }
  }

  List<String> _parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final tips = <String>[];
    for (final line in lines) {
      var t = line;
      if (t.startsWith('- ')) {
        t = t.substring(2);
      } else if (t.startsWith('-')) {
        t = t.substring(1);
      } else if (RegExp(r'^\d+[\.\)]\s').hasMatch(t)) {
        t = t.replaceFirst(RegExp(r'^\d+[\.\)]\s'), '');
      } else if (t.startsWith('• ')) {
        t = t.substring(2);
      }
      t = t.trim();
      if (t.isNotEmpty) tips.add(t);
    }

    return tips.take(4).toList();
  }

  List<String> _fallback(String mood) {
    switch (mood) {
      case 'positive':
        return const [
          'Catat satu hal yang membuatmu bahagia hari ini.',
          'Bagikan energi baikmu dengan orang terdekat.',
          'Lanjutkan rutinitas sehat yang sudah berjalan.',
          'Sisihkan waktu untuk hobi yang kamu sukai.',
        ];
      case 'depressed':
        return const [
          'Mulai dari langkah kecil — beresin satu sudut kamar.',
          'Keluar sebentar untuk menghirup udara segar.',
          'Hubungi satu orang yang membuatmu merasa aman.',
          'Tidur cukup malam ini agar tubuh dan pikiran pulih.',
        ];
      case 'anxious':
        return const [
          'Tarik napas perlahan 4 detik, tahan 4 detik, hembuskan 4 detik.',
          'Tulis kekhawatiranmu di kertas untuk melepaskannya.',
          'Kurangi kafein dan minum air putih hangat.',
          'Jalan kaki ringan untuk mengalihkan fokus pikiran.',
        ];
      case 'stressed':
        return const [
          'Ambil jeda 10 menit menjauh dari layar.',
          'Pecah tugas besar menjadi langkah kecil yang doable.',
          'Lakukan peregangan ringan untuk lepaskan ketegangan.',
          'Dengarkan musik favorit untuk recharge sebentar.',
        ];
      case 'stable':
        return const [
          'Pertahankan rutinitas tidur dan makan yang teratur.',
          'Coba aktivitas baru ringan untuk tambah variasi.',
          'Luangkan waktu untuk olahraga ringan hari ini.',
          'Refleksikan pencapaian kecilmu minggu ini.',
        ];
      default:
        return const [
          'Luangkan waktu sejenak untuk dirimu sendiri.',
          'Tarik napas dalam dan rasakan momen ini.',
          'Lakukan satu hal kecil yang membuatmu nyaman.',
          'Hubungi orang yang kamu percaya bila perlu.',
        ];
    }
  }
}
