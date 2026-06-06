import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../models/diary_entry.dart';
import '../../services/diary_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/storage_service.dart';

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

  final StorageService _storageService = StorageService();

  // Status foto saat edit:
  // - _newImageFile != null   => user pilih foto baru (belum upload)
  // - _imageRemoved == true   => user hapus foto lama
  // - keduanya null/false     => pakai foto lama (diary.imageUrl)
  File? _newImageFile;
  bool _imageRemoved = false;
  bool _isPickingImage = false;

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

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final file = await _storageService.pickFromGallery();
      if (!mounted) return;
      if (file != null) {
        setState(() {
          _newImageFile = file;
          _imageRemoved = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _newImageFile = null;
      _imageRemoved = true;
    });
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final diaryService = context.read<DiaryService>();
    final currentUser = FirebaseAuthService().currentUser();
    if (currentUser == null) return;

    final newText = _textController.text.trim();
    final oldImageUrl = widget.diary.imageUrl;

    final textChanged = newText != widget.diary.diaryText;
    final imageChanged = _newImageFile != null || _imageRemoved;

    if (!textChanged && !imageChanged) {
      Navigator.pop(context);
      return;
    }

    String? newImageUrl;
    if (_newImageFile != null) {
      newImageUrl = await diaryService.uploadImage(
        userId: currentUser.uid,
        file: _newImageFile!,
      );
      if (!mounted) return;
      if (newImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(diaryService.errorMessage ?? 'Gagal upload foto'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final success = await diaryService.updateDiary(
      id: widget.diary.id,
      title: widget.diary.title,
      diaryText: newText,
      newImageUrl: newImageUrl,
      removeImage: _imageRemoved && newImageUrl == null,
      oldImageUrlToDelete:
          (newImageUrl != null || _imageRemoved) ? oldImageUrl : null,
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
                const SizedBox(height: 16),

                const Text(
                  '📷 Foto Lampiran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _EditImageSection(
                  newImage: _newImageFile,
                  existingUrl: _imageRemoved ? null : diary.imageUrl,
                  isLoading: _isPickingImage,
                  onPick: _pickImage,
                  onRemove: _removeImage,
                ),
                const SizedBox(height: 16),

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

class _EditImageSection extends StatelessWidget {
  final File? newImage;
  final String? existingUrl;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _EditImageSection({
    required this.newImage,
    required this.existingUrl,
    required this.isLoading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = newImage != null ||
        (existingUrl != null && existingUrl!.isNotEmpty);

    if (!hasImage) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPick,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image_outlined),
        label: Text(isLoading ? 'Memuat...' : 'Tambah Foto'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade300),
          foregroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: newImage != null
                  ? Image.file(
                      newImage!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: existingUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 220,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 220,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.broken_image_outlined,
                            size: 48, color: AppTheme.textSecondary),
                      ),
                    ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withOpacity(0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onPick,
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Ganti Foto'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: Colors.grey.shade300),
            foregroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
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
