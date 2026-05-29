import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/diary_entry.dart';
import '../../services/diary_service.dart';

// Screen untuk mengedit isi diary yang sudah ada.
class EditDiaryScreen extends StatefulWidget {
  final DiaryEntry diary;

  const EditDiaryScreen({super.key, required this.diary});

  @override
  State<EditDiaryScreen> createState() => _EditDiaryScreenState();
}

class _EditDiaryScreenState extends State<EditDiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.diary.diaryText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _validateDiary(String? value) {
    if (value == null || value.trim().isEmpty) return 'Diary tidak boleh kosong';
    if (value.trim().length < 10) return 'Tulis minimal 10 karakter';
    return null;
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final diaryService = context.read<DiaryService>();
    final newText = _textController.text.trim();

    if (newText == widget.diary.diaryText) {
      Navigator.pop(context);
      return;
    }

    final success = await diaryService.updateDiary(
      id: widget.diary.id,
      title: widget.diary.title,
      diaryText: newText,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diary berhasil diperbarui'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(diaryService.errorMessage ?? 'Gagal update'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryService = context.watch<DiaryService>();
    final diary = widget.diary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Diary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      _MoodBadge(mood: diary.mood),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM yyyy').format(diary.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  '📝 Edit isi diary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _textController,
                  maxLines: 12,
                  minLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Tulis perasaanmu di sini...',
                    alignLabelWithHint: true,
                  ),
                  validator: _validateDiary,
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Color(0xFFD68910)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mood lama tetap dipertahankan. Buat entri baru untuk analisis ulang.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8B6F1A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        diaryService.isSaving ? null : _handleUpdate,
                    icon: diaryService.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(diaryService.isSaving ? '' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Badge kecil untuk menampilkan mood dengan emoji + warna.
class _MoodBadge extends StatelessWidget {
  final String mood;

  const _MoodBadge({required this.mood});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.moodColor(mood);
    final emoji = AppTheme.moodEmoji(mood);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            mood,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
