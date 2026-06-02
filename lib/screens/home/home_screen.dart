import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/diary_entry.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/diary_service.dart';
import '../../services/firebase_auth_service.dart';
import '../auth/login_screen.dart';
import '../diary/diary_list_screen.dart';
import '../diary/write_diary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Apakah kamu yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthService>().logout();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuthService().currentUser();
    final diaryService = context.read<DiaryService>();
    final analytics = AnalyticsService();

    final displayName =
        currentUser?.displayName ??
        currentUser?.email ??
        'Sahabat';

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Anda belum login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<DiaryEntry>>(
          stream: diaryService.watchDiaries(currentUser.uid),
          builder: (context, snapshot) {
            final diaries = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            final weekDiaries = analytics.filterByDays(diaries, 7);

            final lastDiary = diaries.isNotEmpty ? diaries.first : null;
            final totalDiary = diaries.length;
            final dominantMood = analytics.dominantMood(weekDiaries);
            final streak = analytics.calculateStreak(diaries);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GreetingCard(
                    greeting: _greetingByTime(),
                    name: displayName,
                  ),

                  const SizedBox(height: 20),

                  // Quick stats grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Diary',
                          value: isLoading ? '...' : '$totalDiary',
                          subtitle: 'Entri tersimpan',
                          icon: Icons.menu_book_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Streak',
                          value: isLoading ? '...' : '$streak',
                          subtitle: streak <= 1 ? 'Hari' : 'Hari berturut',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF7043),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Mood Terakhir
                  _SectionTitle(
                    icon: Icons.favorite_rounded,
                    text: 'Mood Terakhir',
                  ),
                  const SizedBox(height: 10),
                  _LastMoodCard(
                    diary: lastDiary,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Dominant mood (7 hari)
                  _SectionTitle(
                    icon: Icons.insights_rounded,
                    text: 'Dominant Mood (7 hari)',
                  ),
                  const SizedBox(height: 10),
                  _DominantMoodCard(
                    mood: dominantMood,
                    totalThisWeek: weekDiaries.length,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Diary terbaru
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        icon: Icons.history_rounded,
                        text: 'Diary Terbaru',
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiaryListScreen(),
                          ),
                        ),
                        child: const Text('Lihat semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (diaries.isEmpty)
                    _EmptyRecent(
                      onWrite: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WriteDiaryScreen(),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: diaries
                          .take(3)
                          .map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecentDiaryTile(diary: d),
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 20),

                  // CTA Tulis diary baru
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WriteDiaryScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Tulis Diary Baru'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =====================================================
// GREETING CARD
// =====================================================
class _GreetingCard extends StatelessWidget {
  final String greeting;
  final String name;

  const _GreetingCard({
    required this.greeting,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryColor,
            Color(0xFF06B6D4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$greeting, $name 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bagaimana perasaanmu hari ini? Tulis diary singkat untuk merefleksikan harimu.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// SECTION TITLE
// =====================================================
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          text,
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
// STAT CARD (kecil, untuk grid)
// =====================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
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
              fontSize: 24,
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
// LAST MOOD CARD
// =====================================================
class _LastMoodCard extends StatelessWidget {
  final DiaryEntry? diary;
  final bool isLoading;

  const _LastMoodCard({required this.diary, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _Placeholder(
        height: 96,
        text: 'Memuat mood terakhir...',
      );
    }

    if (diary == null) {
      return _Placeholder(
        height: 96,
        text: 'Belum ada diary. Yuk mulai menulis!',
      );
    }

    final color = AppTheme.moodColor(diary!.mood);
    final emoji = AppTheme.moodEmoji(diary!.mood);
    final confidence = (diary!.confidence * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.04),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diary!.mood,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy • HH:mm').format(diary!.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Confidence $confidence%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
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
// DOMINANT MOOD CARD
// =====================================================
class _DominantMoodCard extends StatelessWidget {
  final String mood;
  final int totalThisWeek;
  final bool isLoading;

  const _DominantMoodCard({
    required this.mood,
    required this.totalThisWeek,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _Placeholder(height: 80, text: 'Menganalisis...');
    }

    if (totalThisWeek == 0) {
      return _Placeholder(
        height: 80,
        text: 'Belum ada diary dalam 7 hari terakhir.',
      );
    }

    final color = AppTheme.moodColor(mood);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            AppTheme.moodEmoji(mood),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Berdasarkan $totalThisWeek diary minggu ini',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: const Text(
              'Dominan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// RECENT DIARY TILE
// =====================================================
class _RecentDiaryTile extends StatelessWidget {
  final DiaryEntry diary;

  const _RecentDiaryTile({required this.diary});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.moodColor(diary.mood);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                AppTheme.moodEmoji(diary.mood),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diary.title.isEmpty ? diary.mood : diary.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM • HH:mm').format(diary.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            diary.mood,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// EMPTY STATE - RECENT
// =====================================================
class _EmptyRecent extends StatelessWidget {
  final VoidCallback onWrite;

  const _EmptyRecent({required this.onWrite});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'Belum ada diary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Yuk tulis diary pertamamu sekarang.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onWrite,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Mulai Menulis'),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// PLACEHOLDER
// =====================================================
class _Placeholder extends StatelessWidget {
  final double height;
  final String text;

  const _Placeholder({required this.height, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
