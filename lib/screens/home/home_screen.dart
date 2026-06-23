import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import '../diary/edit_diary_screen.dart';
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
        currentUser?.displayName ?? currentUser?.email ?? 'Sahabat';

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Anda belum login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Diary'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'logout') _handleLogout(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Keluar'),
                  ],
                ),
              ),
            ],
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

            final totalDiary = diaries.length;
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

                  const SizedBox(height: 16),

                  _TodayStatusCard(
                    diaries: diaries,
                    isLoading: isLoading,
                    onWrite: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WriteDiaryScreen()),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                          value: isLoading
                              ? '...'
                              : streak == 0
                                  ? '-'
                                  : '$streak',
                          subtitle: streak == 0
                              ? 'Mulai tulis!'
                              : streak == 1
                                  ? 'Hari'
                                  : 'Hari berturut',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF7043),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle(
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
                      child:
                          Center(child: CircularProgressIndicator()),
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
                              padding:
                                  const EdgeInsets.only(bottom: 10),
                              child: _RecentDiaryTile(diary: d),
                            ),
                          )
                          .toList(),
                    ),

                  const SizedBox(height: 20),
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

  const _GreetingCard({required this.greeting, required this.name});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, dd MMMM yyyy', 'id').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            'Bagaimana perasaanmu hari ini?',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// STATUS HARI INI
// =====================================================
class _TodayStatusCard extends StatelessWidget {
  final List<DiaryEntry> diaries;
  final bool isLoading;
  final VoidCallback onWrite;

  const _TodayStatusCard({
    required this.diaries,
    required this.isLoading,
    required this.onWrite,
  });

  static const _prompts = [
    'Apa yang membuatmu bahagia hari ini?',
    'Ceritakan 1 hal yang kamu syukuri',
    'Bagaimana progres targetmu minggu ini?',
    'Apa yang kamu pelajari hari ini?',
    'Ceritakan momen favoritmu hari ini',
    'Apa yang ingin kamu ingat dari hari ini?',
    'Refleksikan harimu dalam beberapa kalimat',
  ];

  DiaryEntry? _todayDiary() {
    final today = DateTime.now();
    for (final d in diaries) {
      if (d.createdAt.year == today.year &&
          d.createdAt.month == today.month &&
          d.createdAt.day == today.day) {
        return d;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _Placeholder(height: 90, text: 'Memuat...');
    }

    final todayDiary = _todayDiary();

    if (todayDiary != null) {
      final emoji = AppTheme.moodEmoji(todayDiary.mood);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_rounded,
                    color: AppTheme.successColor, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sudah nulis hari ini!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$emoji ${todayDiary.mood}  •  ${todayDiary.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
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

    final prompt =
        _prompts[DateTime.now().weekday % _prompts.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belum nulis hari ini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prompt,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onWrite,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Tulis Sekarang'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('✏️', style: TextStyle(fontSize: 36)),
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
// STAT CARD
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
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
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// RECENT DIARY TILE — tappable, preview text
// =====================================================
class _RecentDiaryTile extends StatelessWidget {
  final DiaryEntry diary;

  const _RecentDiaryTile({required this.diary});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hari ini';
    if (dateOnly == yesterday) return 'Kemarin';
    if (date.year == now.year) return DateFormat('d MMM', 'id').format(date);
    return DateFormat('d MMM yy', 'id').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.moodColor(diary.mood);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditDiaryScreen(diary: diary)),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  AppTheme.moodEmoji(diary.mood),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diary.title.isEmpty ? '(Tanpa judul)' : diary.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    diary.diaryText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(diary.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// EMPTY STATE
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
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
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
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
