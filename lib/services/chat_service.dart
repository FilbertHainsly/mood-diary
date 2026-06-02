import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart' hide ChatSession;

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'firestore_service.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  static const String _geminiApiKey = 'Your API Key';
  static const String _modelName = 'gemini-2.5-flash';

  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  CollectionReference get _chatsRef => _db.collection('chats');

  late final GenerativeModel _model = GenerativeModel(
    model: _modelName,
    apiKey: _geminiApiKey,
    generationConfig: GenerationConfig(temperature: 0.8),
    systemInstruction: Content.system(_systemPrompt),
  );

  static const String _systemPrompt = '''
Kamu adalah Moodly — AI companion yang hangat, cerdas, dan praktis untuk refleksi kesehatan mental.
Kamu bisa jadi pendengar yang baik SEKALIGUS kasih saran konkret, tergantung kebutuhan user.
Bahasa Indonesia santai dan natural, seperti teman pintar yang peduli — bukan terapis formal, bukan chatbot kaku.

=== DETEKSI NIAT & RESPONS ===

[CURHAT / CERITA] — user berbagi perasaan/kejadian tanpa minta solusi.
→ Dengarkan dan validasi, tapi VARIASIKAN cara validasinya (jangan selalu "Wajar banget").
   Kadang cukup akui ("Kedengarannya hari yang panjang ya"), kadang refleksikan balik apa yang kamu tangkap.
   Boleh tanya satu hal lanjutan kalau relevan — tidak wajib.

[MINTA SARAN / SOLUSI] — "gimana caranya", "aku harus apa", "tips", "cara mengatasi", dsb.
→ LANGSUNG beri saran konkret, praktis, bisa langsung dilakukan. Jangan balik tanya, jangan filosofis.
   Format: langkah nyata, boleh pakai poin.

[PERTANYAAN] — diawali kata tanya.
→ Jawab langsung dan jelas. Tanpa basa-basi panjang.

[MELUAPKAN EMOSI] — marah/frustrasi/sangat sedih tanpa minta solusi.
→ Validasi dulu, jangan buru-buru kasih solusi. Beri ruang.

=== GAYA ===
- JANGAN selalu akhiri dengan pertanyaan. Banyak respons justru lebih baik ditutup dengan pernyataan menenangkan.
- VARIASIKAN pembuka. Hindari mengulang frasa yang sama ("Wajar banget", "Aku di sini") di setiap pesan.
- Panjang fleksibel: empati bisa singkat, saran boleh detail.
- Personal: rujuk konteks diary & mood user, TAPI hanya yang benar-benar ada. Jangan mengarang detail yang tidak disebutkan.
- Natural, tidak seperti template.

=== BATASAN ===
- Kamu BUKAN pengganti psikolog/dokter. Jangan mendiagnosis ("kamu kena depresi/anxiety disorder"), jangan kasih nasihat medis atau obat.
- Fokus pada refleksi emosi & dukungan. Kalau user minta hal di luar itu (misal nulis kode, kerjain tugas), arahkan baik-baik kembali ke fungsimu sebagai teman refleksi.
- Jangan ceramah, jangan menghakimi, jangan menggurui.

=== KEAMANAN (PRIORITAS TERTINGGI) ===
Perhatikan tanda krisis — baik eksplisit ("ingin mengakhiri", "menyakiti diri") MAUPUN halus ("capek hidup", "buat apa lagi", "menyerah aja", "tidak ada gunanya", "lebih baik aku tidak ada").
Jika muncul tanda ini:
→ Validasi perasaannya dengan tulus dan lembut, JANGAN panik atau kaku.
→ Dengan hangat dorong user menghubungi orang terpercaya atau profesional.
→ Sampaikan bahwa mereka tidak sendirian dan perasaan berat ini bisa berlalu.
→ Jangan menggurui, jangan menghakimi, jangan kasih solusi instan yang meremehkan.
''';

  // SESSION CRUD
  Future<ChatSession?> createSession(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final latestDiary = await _firestoreService.getLatestDiary(userId);
      final relatedMood = latestDiary?.mood ?? 'stable';

      final now = DateTime.now();
      final title = 'Chat ${now.day}/${now.month}/${now.year}';

      final docRef = await _chatsRef.add({
        'userId': userId,
        'title': title,
        'relatedMood': relatedMood,
        'isFavorite': false,
        'createdAt': Timestamp.fromDate(now),
        'lastMessageAt': Timestamp.fromDate(now),
      });

      final session = ChatSession(
        sessionId: docRef.id,
        userId: userId,
        title: title,
        relatedMood: relatedMood,
        createdAt: now,
        lastMessageAt: now,
      );

      _isLoading = false;
      notifyListeners();
      return session;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Stream<List<ChatSession>> watchSessions(String userId) {
    return _chatsRef
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatSession.fromDoc(d))
            .toList());
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      final msgsSnap = await _chatsRef
          .doc(sessionId)
          .collection('messages')
          .get();
      for (final doc in msgsSnap.docs) {
        await doc.reference.delete();
      }
      await _chatsRef.doc(sessionId).delete();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameSession(String sessionId, String newTitle) async {
    try {
      await _chatsRef.doc(sessionId).update({'title': newTitle.trim()});
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFavorite(String sessionId, bool currentValue) async {
    try {
      await _chatsRef
          .doc(sessionId)
          .update({'isFavorite': !currentValue});
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // MESSAGE CRUD
  Stream<List<ChatMessage>> watchMessages(String sessionId) {
    return _chatsRef
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromDoc(d))
            .toList());
  }

  Future<bool> sendMessage({
    required String userId,
    required String sessionId,
    required String content,
    required String relatedMood,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final msgsRef = _chatsRef.doc(sessionId).collection('messages');

      // Ambil history sebelum menambah pesan baru
      final historySnap = await msgsRef
          .orderBy('timestamp', descending: true)
          .limit(8)
          .get();
      final history = historySnap.docs
          .map((d) => ChatMessage.fromDoc(d))
          .toList()
          .reversed
          .toList();

      // Simpan pesan user
      final userNow = DateTime.now();
      await msgsRef.add({
        'sessionId': sessionId,
        'content': content,
        'sender': 'user',
        'timestamp': Timestamp.fromDate(userNow),
      });

      // Generate dan simpan respons
      final botResponse = await _generateBotResponse(
        userId: userId,
        userMessage: content,
        relatedMood: relatedMood,
        chatHistory: history,
      );

      final botNow = DateTime.now();
      await msgsRef.add({
        'sessionId': sessionId,
        'content': botResponse,
        'sender': 'bot',
        'timestamp': Timestamp.fromDate(botNow),
      });

      await _chatsRef
          .doc(sessionId)
          .update({'lastMessageAt': Timestamp.fromDate(botNow)});

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  // PRIVATE — GEMINI
  Future<String> _generateBotResponse({
    required String userId,
    required String userMessage,
    required String relatedMood,
    required List<ChatMessage> chatHistory,
  }) async {
    try {
      // 1. Mood terkini — ambil langsung dari diary terbaru, bukan dari session
      final latestDiary = await _firestoreService.getLatestDiary(userId);
      final currentMood = latestDiary?.mood ?? relatedMood;

      // 2. 3 diary terakhir tanpa batasan waktu
      final recentDiaries =
          await _firestoreService.getLatestDiaries(userId, limit: 3);

      final diaryContext = recentDiaries.isEmpty
          ? 'Belum ada diary.'
          : recentDiaries.map((d) {
              final snippet = d.diaryText.length > 100
                  ? '${d.diaryText.substring(0, 100)}...'
                  : d.diaryText;
              return '- ${d.createdAt.day}/${d.createdAt.month}'
                  '/${d.createdAt.year} [${d.mood}]: $snippet';
            }).join('\n');

      // 3. History chat (8 pesan terakhir)
      final historyContext = chatHistory.isEmpty
          ? 'Belum ada percakapan sebelumnya.'
          : chatHistory.map((m) {
              final role =
                  m.sender == MessageSender.user ? 'User' : 'Bot';
              return '$role: ${m.content}';
            }).join('\n');

      // 4. Crisis detection — inject instruksi tambahan jika terdeteksi
      final crisisNote = _hasCrisisKeywords(userMessage)
          ? '''
[PENTING] Pesan user mengandung kata-kata yang mengindikasikan kondisi emosional berat.
Tunjukkan empati penuh terlebih dahulu. Kemudian, dengan lembut dan tanpa menghakimi,
sisipkan saran agar user mau berbicara dengan orang yang ia percaya, konselor, atau
profesional kesehatan mental. Jangan mendiagnosis. Jangan terkesan menggurui.
'''
          : '';

      final prompt = '''
Mood terkini user: $currentMood

3 Diary terakhir user:
$diaryContext

Riwayat percakapan (8 pesan terakhir):
$historyContext
$crisisNote
Pesan user sekarang: $userMessage
''';

      return await _callGeminiWithRetry(prompt, currentMood);
    } catch (e) {
      debugPrint('[ChatService] Gemini error: $e');
      return _fallbackResponse(relatedMood);
    }
  }

  static const List<String> _crisisKeywords = [
    'menyerah', 'nyerah', 'putus asa',
    'tidak ada gunanya', 'ga ada gunanya', 'nggak ada gunanya',
    'tidak sanggup', 'ga sanggup', 'nggak sanggup',
    'mengakhiri', 'ngakhirin',
    'capek hidup', 'lelah hidup', 'bosan hidup',
    'mati aja', 'pengen mati', 'ingin mati',
    'bunuh diri', 'tidak mau hidup', 'ga mau hidup',
    'tidak berguna', 'ga berguna', 'nggak berguna',
    'lebih baik mati', 'mending mati',
  ];

  bool _hasCrisisKeywords(String text) {
    final lower = text.toLowerCase();
    return _crisisKeywords.any((k) => lower.contains(k));
  }

  Future<String> _callGeminiWithRetry(String prompt, String relatedMood) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response =
            await _model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          return _fallbackResponse(relatedMood);
        }
        return text.trim();
      } catch (e) {
        final isRetryable = e.toString().contains('503') ||
            e.toString().contains('UNAVAILABLE') ||
            e.toString().contains('high demand');

        if (isRetryable && attempt < maxRetries) {
          debugPrint('[ChatService] 503 — retry $attempt/$maxRetries...');
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        debugPrint('[ChatService] Gemini error: $e');
        return _fallbackResponse(relatedMood);
      }
    }
    return _fallbackResponse(relatedMood);
  }

  String _fallbackResponse(String mood) {
    switch (mood) {
      case 'depressed':
        return 'Aku di sini bersamamu. Perasaanmu valid dan layak didengarkan. Mau cerita lebih banyak tentang apa yang kamu rasakan?';
      case 'anxious':
        return 'Cemas itu berat, dan aku mengerti. Tarik napas perlahan — kamu tidak sendirian. Apa yang paling membuatmu khawatir saat ini?';
      case 'stressed':
        return 'Sepertinya banyak yang sedang kamu tanggung. Yuk, kita petakan bersama apa yang paling menekanmu hari ini?';
      case 'positive':
        return 'Senang mendengar kamu dalam suasana positif! Apa yang membuatmu merasa baik hari ini?';
      default:
        return 'Terima kasih sudah berbagi. Aku selalu di sini untuk mendengarkan. Ada hal lain yang ingin kamu ceritakan?';
    }
  }
}
