import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/diary_entry.dart';
import '../../services/analytics_service.dart';
import '../../services/diary_service.dart';
import '../../services/firebase_auth_service.dart';

enum _Period { week, month, all }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _Period _period = _Period.week;

  final _analytics = AnalyticsService();

  List<DiaryEntry> _applyPeriod(List<DiaryEntry> all) {
    switch (_period) {
      case _Period.week:
        return _analytics.filterByDays(all, 7);
      case _Period.month:
        return _analytics.filterByDays(all, 30);
      case _Period.all:
        return all;
    }
  }

  String get _periodLabel {
    switch (_period) {
      case _Period.week:
        return '7 Hari';
      case _Period.month:
        return '30 Hari';
      case _Period.all:
        return 'Semua';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuthService().currentUser();
    final diaryService = context.read<DiaryService>();

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Anda belum login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<DiaryEntry>>(
          stream: diaryService.watchDiaries(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Terjadi kesalahan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              );
            }

            final all = snapshot.data ?? [];
            final filtered = _applyPeriod(all);

            final totalEntries = filtered.length;
            final dominantMood = _analytics.dominantMood(filtered);
            final avgConfidence = _analytics.averageConfidence(filtered);
            final streak = _analytics.calculateStreak(all);
            final positivity = _analytics.positivityRatio(filtered);
            final distribution = _analytics.moodDistribution(filtered);
            final weeklyTrend = _analytics.diariesPerDayLastWeek(all);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _periodSelector(),
                  const SizedBox(height: 20),

                  // Summary
                  Row(
                    children: [
                      Expanded(
                        child: _SmallStat(
                          title: 'Total Diary',
                          value: '$totalEntries',
                          subtitle: 'Periode $_periodLabel',
                          icon: Icons.menu_book_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          title: 'Streak',
                          value: '$streak',
                          subtitle: streak <= 1
                              ? 'Hari'
                              : 'Hari berturut',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF7043),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _SmallStat(
                          title: 'Avg. Confidence',
                          value:
                              '${(avgConfidence * 100).toStringAsFixed(0)}%',
                          subtitle: 'Rata-rata akurasi AI',
                          icon: Icons.verified_rounded,
                          color: const Color(0xFF42A5F5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallStat(
                          title: 'Positivity',
                          value:
                              '${(positivity * 100).toStringAsFixed(0)}%',
                          subtitle: 'Mood positif',
                          icon: Icons.sentiment_very_satisfied_rounded,
                          color: const Color(0xFFFFCA28),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Dominant mood
                  _SectionHeader(
                    icon: Icons.insights_rounded,
                    title: 'Dominant Mood',
                  ),
                  const SizedBox(height: 10),
                  _DominantMoodCard(
                    mood: dominantMood,
                    total: totalEntries,
                  ),

                  const SizedBox(height: 24),

                  // Mood distribution
                  _SectionHeader(
                    icon: Icons.pie_chart_rounded,
                    title: 'Distribusi Mood',
                  ),
                  const SizedBox(height: 10),
                  _DistributionCard(
                    distribution: distribution,
                  ),

                  const SizedBox(height: 24),

                  // Weekly activity trend
                  _SectionHeader(
                    icon: Icons.show_chart_rounded,
                    title: 'Aktivitas 7 Hari Terakhir',
                  ),
                  const SizedBox(height: 10),
                  _WeeklyTrendCard(buckets: weeklyTrend),

                  const SizedBox(height: 24),

                  // Recent entries (small list)
                  _SectionHeader(
                    icon: Icons.timeline_rounded,
                    title: 'Timeline Mood',
                  ),
                  const SizedBox(height: 10),
                  _TimelineCard(diaries: filtered.take(8).toList()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: _Period.values.map((p) {
          final selected = p == _period;
          final label = switch (p) {
            _Period.week => '7 Hari',
            _Period.month => '30 Hari',
            _Period.all => 'Semua',
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =====================================================
// SECTION HEADER
// =====================================================
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =====================================================
// SMALL STAT CARD
// =====================================================
class _SmallStat extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SmallStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DOMINANT MOOD CARD
// =====================================================
class _DominantMoodCard extends StatelessWidget {
  final String mood;
  final int total;

  const _DominantMoodCard({required this.mood, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return _EmptyBox(
        text: 'Belum ada diary pada periode ini.',
      );
    }

    final color = AppTheme.moodColor(mood);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.20),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                AppTheme.moodEmoji(mood),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mood paling sering muncul dari $total diary',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DISTRIBUTION CARD (horizontal bars)
// =====================================================
class _DistributionCard extends StatelessWidget {
  final List<MoodStat> distribution;

  const _DistributionCard({required this.distribution});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return _EmptyBox(
        text: 'Belum cukup data untuk menghitung distribusi.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: distribution
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _DistributionBar(stat: s),
                ))
            .toList(),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final MoodStat stat;

  const _DistributionBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.moodColor(stat.mood);
    final pct = (stat.percentage * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppTheme.moodEmoji(stat.mood),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stat.mood,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              '${stat.count} • $pct%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: stat.percentage.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// WEEKLY TREND BAR CHART
// =====================================================
class _WeeklyTrendCard extends StatelessWidget {
  final List<int> buckets;

  const _WeeklyTrendCard({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.isEmpty
        ? 0
        : buckets.reduce((a, b) => a > b ? a : b);

    final today = DateTime.now();
    final labels = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(day);
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = buckets[i];
                final ratio = maxVal == 0 ? 0.0 : v / maxVal;
                final isToday = i == 6;
                final color = isToday
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.45);

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$v',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          height: 8 + (110 * ratio),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color,
                                color.withOpacity(0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i == 6 ? FontWeight.w800 : FontWeight.w500,
                    color: i == 6
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// TIMELINE
// =====================================================
class _TimelineCard extends StatelessWidget {
  final List<DiaryEntry> diaries;

  const _TimelineCard({required this.diaries});

  @override
  Widget build(BuildContext context) {
    if (diaries.isEmpty) {
      return _EmptyBox(text: 'Belum ada entri pada periode ini.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(diaries.length, (i) {
          final diary = diaries[i];
          final color = AppTheme.moodColor(diary.mood);
          final isLast = i == diaries.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(0.35),
                          width: 3,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppTheme.moodEmoji(diary.mood),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              diary.mood,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM • HH:mm')
                                  .format(diary.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diary.title.isEmpty
                              ? (diary.diaryText.length > 60
                                  ? '${diary.diaryText.substring(0, 60)}...'
                                  : diary.diaryText)
                              : diary.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// =====================================================
// EMPTY BOX
// =====================================================
class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            size: 36,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
