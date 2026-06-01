import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/chat_session.dart';
import '../../services/chat_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dtDate = DateTime(dt.year, dt.month, dt.day);
    if (dtDate == today) return 'Hari ini';
    if (dtDate == yesterday) return 'Kemarin';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _createSession(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final chatService = context.read<ChatService>();
    final session = await chatService.createSession(uid);
    if (session == null) return;

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatRoomScreen(session: session)),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    ChatSession session,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Sesi Chat'),
            content: Text(
                'Hapus "${session.title}"? Semua pesan akan hilang permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSessionOptions(
    BuildContext context,
    ChatService chatService,
    ChatSession session,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Ganti Nama'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, chatService, session);
              },
            ),
            ListTile(
              leading: Icon(
                session.isFavorite ? Icons.star : Icons.star_outline,
                color: session.isFavorite ? Colors.amber : null,
              ),
              title: Text(session.isFavorite
                  ? 'Hapus dari Favorit'
                  : 'Tandai Favorit'),
              onTap: () {
                Navigator.pop(context);
                chatService.toggleFavorite(
                    session.sessionId, session.isFavorite);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    ChatService chatService,
    ChatSession session,
  ) async {
    final controller = TextEditingController(text: session.title);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ganti Nama Sesi'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama sesi'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (confirmed == true && controller.text.trim().isNotEmpty) {
        await chatService.renameSession(session.sessionId, controller.text);
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatService = context.watch<ChatService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Refleksi Diri')),
      floatingActionButton: FloatingActionButton(
        onPressed:
            chatService.isLoading ? null : () => _createSession(context),
        backgroundColor: AppTheme.primaryColor,
        child: chatService.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<ChatSession>>(
        stream: chatService.watchSessions(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Terjadi kesalahan. Pastikan index Firestore sudah dibuat.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada sesi chat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan + untuk mulai refleksi diri',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Dismissible(
                key: Key(session.sessionId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) =>
                    _confirmDelete(context, session),
                onDismissed: (_) =>
                    chatService.deleteSession(session.sessionId),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: AppTheme.errorColor,
                  child:
                      const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: _SessionCard(
                  session: session,
                  formattedDate: _formatDate(session.lastMessageAt),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(session: session),
                    ),
                  ),
                  onLongPress: () =>
                      _showSessionOptions(context, chatService, session),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.formattedDate,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatSession session;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              AppTheme.moodColor(session.relatedMood).withValues(alpha: 0.2),
          child: Text(
            AppTheme.moodEmoji(session.relatedMood),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (session.isFavorite)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.star, size: 16, color: Colors.amber),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            formattedDate,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
