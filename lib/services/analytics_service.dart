import '../models/diary_entry.dart';

class MoodStat {
  final String mood;
  final int count;
  final double percentage;

  MoodStat({
    required this.mood,
    required this.count,
    required this.percentage,
  });
}

class AnalyticsService {
  // =====================================================
  // FILTER BY DATE RANGE
  // =====================================================

  List<DiaryEntry> filterByDays(
    List<DiaryEntry> diaries,
    int days,
  ) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return diaries
        .where((d) => d.createdAt.isAfter(cutoff))
        .toList();
  }

  // =====================================================
  // COUNT MOODS
  // =====================================================

  Map<String, int> countByMood(List<DiaryEntry> diaries) {
    final result = <String, int>{};
    for (final diary in diaries) {
      final mood = diary.mood.isEmpty ? 'Unknown' : diary.mood;
      result[mood] = (result[mood] ?? 0) + 1;
    }
    return result;
  }

  // =====================================================
  // DOMINANT MOOD
  // =====================================================

  String dominantMood(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return '-';

    final counts = countByMood(diaries);
    if (counts.isEmpty) return '-';

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  // =====================================================
  // MOOD DISTRIBUTION
  // =====================================================

  List<MoodStat> moodDistribution(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return [];

    final counts = countByMood(diaries);
    final total = diaries.length;

    final stats = counts.entries.map((e) {
      return MoodStat(
        mood: e.key,
        count: e.value,
        percentage: e.value / total,
      );
    }).toList();

    stats.sort((a, b) => b.count.compareTo(a.count));
    return stats;
  }

  // =====================================================
  // AVERAGE CONFIDENCE
  // =====================================================

  double averageConfidence(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return 0.0;

    final total = diaries.fold<double>(
      0.0,
      (sum, d) => sum + d.confidence,
    );

    return total / diaries.length;
  }

  // =====================================================
  // EMOTIONAL STREAK
  // Berapa hari berturut-turut user menulis diary
  // (dihitung mundur dari hari ini).
  // =====================================================

  int calculateStreak(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return 0;

    final uniqueDays = <DateTime>{};
    for (final d in diaries) {
      final date = DateTime(
        d.createdAt.year,
        d.createdAt.month,
        d.createdAt.day,
      );
      uniqueDays.add(date);
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime cursor = todayDate;

    if (!uniqueDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!uniqueDays.contains(cursor)) return 0;
    }

    while (uniqueDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  // =====================================================
  // POSITIVITY RATIO
  // Persentase entry yang bermood "positive".
  // =====================================================

  double positivityRatio(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return 0.0;

    final positive = diaries
        .where((d) => d.mood.toLowerCase() == 'positive')
        .length;

    return positive / diaries.length;
  }

  // =====================================================
  // DIARIES PER DAY (untuk grafik trend mingguan)
  // Mengembalikan list 7 hari terakhir (hari ini di kanan).
  // =====================================================

  List<int> diariesPerDayLastWeek(List<DiaryEntry> diaries) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final buckets = List<int>.filled(7, 0);

    for (final d in diaries) {
      final date = DateTime(
        d.createdAt.year,
        d.createdAt.month,
        d.createdAt.day,
      );

      final diff = todayDate.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        buckets[6 - diff] += 1;
      }
    }

    return buckets;
  }

  /// 4 bucket (lama → baru), masing-masing 7 hari, covering 28 hari terakhir.
  /// Index 3 = minggu ini.
  List<int> diariesPerWeekLastMonth(List<DiaryEntry> diaries) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final buckets = List<int>.filled(4, 0);

    for (final d in diaries) {
      final date = DateTime(
        d.createdAt.year,
        d.createdAt.month,
        d.createdAt.day,
      );
      final diff = todayDate.difference(date).inDays;
      if (diff >= 0 && diff < 28) {
        buckets[3 - (diff ~/ 7)] += 1;
      }
    }

    return buckets;
  }
}
