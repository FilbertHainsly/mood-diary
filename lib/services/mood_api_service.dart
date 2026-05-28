import 'dart:convert';
import 'dart:math';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/mood_result.dart';

// Service untuk memprediksi mood + rekomendasi menggunakan Google Gemini API.
// Gemini diminta mengembalikan JSON terstruktur berisi label mood, tingkat
// keyakinan, dan rekomendasi singkat berdasarkan isi diary.
class MoodApiService {
  // GANTI dengan Gemini API key milikmu.
  // Cara mendapatkan: https://aistudio.google.com/app/apikey
  static const String _geminiApiKey = 'Your API Key';

  static const String _modelName = 'gemini-2.5-flash';

  // Label mood psikologis formal yang dipakai di seluruh app.
  // Harus sinkron dengan AppTheme.moodColor / moodEmoji di main.dart.
  static const List<String> _allowedMoods = [
    'positive',
    'depressed',
    'anxious',
    'stressed',
    'stable',
  ];

  late final GenerativeModel _model = GenerativeModel(
    model: _modelName,
    apiKey: _geminiApiKey,
    generationConfig: GenerationConfig(
      temperature: 0.4,
      responseMimeType: 'application/json',
    ),
    systemInstruction: Content.system(_systemPrompt),
  );

  static const String _systemPrompt = '''
Kamu adalah asisten psikologi berbahasa Indonesia yang ramah dan empatik.
Tugasmu: menganalisis isi diary pengguna lalu mengembalikan SATU label
emosi dominan beserta rekomendasi tindakan singkat yang sehat.

Aturan label (WAJIB pilih persis salah satu, lowercase):
- "positive"  -> senang, bahagia, syukur, antusias, semangat
- "depressed" -> sedih mendalam, putus asa, kehilangan minat, hampa
- "anxious"   -> cemas, khawatir, takut, panik, gugup
- "stressed"  -> tertekan, kewalahan, marah, frustrasi, lelah berat
- "stable"    -> tenang, biasa saja, netral, tidak ada emosi dominan

Aturan rekomendasi:
- 2-4 kalimat, hangat, suportif, dalam Bahasa Indonesia.
- Berikan saran konkret yang sehat (mis. jurnal, teknik napas, hubungi
  teman, istirahat, journaling, olahraga ringan, mindfulness).
- Jangan mendiagnosis. Jangan menghakimi.
- Jika label "depressed" dan ada tanda bahaya (mis. ingin menyakiti
  diri), sertakan ajakan menghubungi orang terpercaya atau hotline
  kesehatan mental / profesional.

Format keluaran HARUS JSON valid persis seperti ini, tanpa teks lain:
{
  "mood": "<salah satu label lowercase>",
  "confidence": <angka 0..1>,
  "recommendation": "<rekomendasi singkat>"
}
''';

  Future<MoodResult> predictMood(String text) async {
    if (text.trim().isEmpty) {
      throw 'Teks diary tidak boleh kosong';
    }

    // Kalau API key belum diset, langsung pakai fallback supaya app
    // tetap bisa didemonstrasikan.
    if (_geminiApiKey.isEmpty ||
        _geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return _mockPredict(text);
    }

    try {
      final response = await _model.generateContent([
        Content.text('Analisis diary berikut:\n"""\n$text\n"""'),
      ]);

      final raw = response.text;
      if (raw == null || raw.trim().isEmpty) {
        return _mockPredict(text);
      }
      return _parseGeminiResponse(raw);
    } catch (_) {
      // Fallback bila request Gemini gagal (jaringan / quota / key invalid).
      return _mockPredict(text);
    }
  }

  MoodResult _parseGeminiResponse(String body) {
    final cleaned = _stripCodeFence(body).trim();
    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

    final rawMood = (decoded['mood'] ?? 'stable').toString();
    final rawConfidence = decoded['confidence'];
    final rawRec = (decoded['recommendation'] ?? '').toString();

    final mood = _normalizeMood(rawMood);
    final confidence = (rawConfidence is num)
        ? rawConfidence.toDouble().clamp(0.0, 1.0)
        : double.tryParse(rawConfidence?.toString() ?? '') ?? 0.7;

    return MoodResult(
      mood: mood,
      confidence: confidence.toDouble(),
      recommendation: rawRec.trim(),
    );
  }

  // Gemini kadang membungkus JSON dalam ```json ... ``` walaupun sudah
  // diminta JSON murni. Bersihkan dulu sebelum di-decode.
  String _stripCodeFence(String s) {
    final trimmed = s.trim();
    if (!trimmed.startsWith('```')) return trimmed;
    final firstNewline = trimmed.indexOf('\n');
    if (firstNewline == -1) return trimmed;
    final withoutOpening = trimmed.substring(firstNewline + 1);
    final closing = withoutOpening.lastIndexOf('```');
    if (closing == -1) return withoutOpening;
    return withoutOpening.substring(0, closing);
  }

  // Pastikan label hasil model sesuai dengan daftar resmi.
  // Juga peta label lama (happy/sad/...) ke skema baru bila Gemini
  // sempat mengembalikan label legacy.
  String _normalizeMood(String label) {
    final lower = label.toLowerCase().trim();
    for (final m in _allowedMoods) {
      if (m == lower) return m;
    }
    switch (lower) {
      case 'happy':
      case 'joy':
      case 'love':
        return 'positive';
      case 'sad':
      case 'sadness':
      case 'depression':
        return 'depressed';
      case 'fear':
      case 'anxiety':
        return 'anxious';
      case 'angry':
      case 'anger':
        return 'stressed';
      case 'neutral':
      case 'calm':
        return 'stable';
      default:
        return 'stable';
    }
  }

  // === FALLBACK DUMMY PREDICTOR ===
  // Dipakai kalau Gemini API key belum diset atau request gagal.
  MoodResult _mockPredict(String text) {
    final lower = text.toLowerCase();
    final moodKeywords = <String, List<String>>{
      'positive': ['senang', 'bahagia', 'gembira', 'happy', 'asyik', 'seru', 'syukur', 'cinta', 'sayang'],
      'depressed': ['sedih', 'kecewa', 'menangis', 'galau', 'kesepian', 'hampa', 'putus asa', 'depresi'],
      'anxious': ['takut', 'cemas', 'khawatir', 'panik', 'gugup', 'was-was'],
      'stressed': ['marah', 'kesal', 'sebel', 'jengkel', 'benci', 'stres', 'lelah', 'capek', 'kewalahan'],
      'stable': ['biasa', 'oke', 'normal', 'datar', 'tenang'],
    };

    String detected = 'stable';
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
    return MoodResult(
      mood: detected,
      confidence: confidence,
      recommendation: _fallbackRecommendation(detected),
    );
  }

  String _fallbackRecommendation(String mood) {
    switch (mood) {
      case 'positive':
        return 'Senang melihatmu dalam suasana positif! Coba abadikan momen ini lewat foto atau tulisan singkat, lalu bagikan kebahagiaanmu dengan orang terdekat.';
      case 'depressed':
        return 'Perasaanmu valid dan layak didengarkan. Cobalah tarik napas dalam, lakukan satu aktivitas kecil yang biasanya kamu nikmati, dan jangan ragu menghubungi orang yang kamu percaya atau tenaga profesional bila beban terasa berat.';
      case 'anxious':
        return 'Cemas itu manusiawi. Coba teknik grounding 5-4-3-2-1 (sebutkan 5 hal yang kamu lihat, 4 dengar, 3 sentuh, 2 cium, 1 rasakan) untuk menenangkan pikiran.';
      case 'stressed':
        return 'Beri tubuh dan pikiranmu jeda. Coba teknik napas 4-7-8, jalan singkat di luar ruangan, atau tuliskan apa yang membebanimu agar lebih mudah dipetakan.';
      default:
        return 'Tidak apa-apa merasa stabil dan biasa saja. Gunakan momen tenang ini untuk istirahat, refleksi singkat, atau merencanakan satu hal kecil yang menyenangkan.';
    }
  }
}
