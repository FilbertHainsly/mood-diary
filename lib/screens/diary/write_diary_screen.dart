
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../services/diary_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/storage_service.dart';
import 'result_screen.dart';

class WriteDiaryScreen extends StatefulWidget {
  const WriteDiaryScreen({super.key});

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _diaryController =
      TextEditingController();

  final StorageService _storageService = StorageService();

  File? _selectedImage;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul diary tidak boleh kosong';
    }

    if (value.trim().length < 3) {
      return 'Judul terlalu pendek';
    }

    return null;
  }

  String? _validateDiary(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Diary tidak boleh kosong';
    }

    if (value.trim().length < 10) {
      return 'Minimal 10 karakter';
    }

    return null;
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final file = await _storageService.pickFromGallery();
      if (!mounted) return;
      if (file != null) {
        setState(() => _selectedImage = file);
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
    setState(() => _selectedImage = null);
  }

  Future<void> _handleAnalyze() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser =
        FirebaseAuthService().currentUser();

    if (currentUser == null) return;

    final diaryService =
        context.read<DiaryService>();

    final success =
        await diaryService.analyzeAndSave(
      userId: currentUser.uid,
      title: _titleController.text.trim(),
      diaryText: _diaryController.text.trim(),
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ResultScreen(),
        ),
      );

      _titleController.clear();
      _diaryController.clear();
      setState(() => _selectedImage = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            diaryService.errorMessage ??
                'Gagal menyimpan diary',
          ),
          backgroundColor:
              AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryService =
        context.watch<DiaryService>();

    final now =
        DateFormat(
          'EEEE, dd MMMM yyyy • HH:mm',
        ).format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Diary'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        now,
                        style: const TextStyle(
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller:
                            _titleController,
                        validator:
                            _validateTitle,
                        style:
                            const TextStyle(
                          fontSize: 26,
                          fontWeight:
                              FontWeight.w700,
                        ),
                        decoration:
                            const InputDecoration(
                          hintText:
                              'Judul Diary',
                          border:
                              InputBorder.none,
                        ),
                      ),

                      const Divider(),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller:
                            _diaryController,
                        validator:
                            _validateDiary,
                        maxLines: null,
                        minLines: 12,
                        keyboardType:
                            TextInputType
                                .multiline,
                        textCapitalization:
                            TextCapitalization
                                .sentences,
                        decoration:
                            const InputDecoration(
                          hintText:
                              'Tuliskan apa yang kamu rasakan hari ini...',
                          border:
                              InputBorder.none,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _ImagePickerSection(
                        image: _selectedImage,
                        isLoading: _isPickingImage,
                        onPick: _pickImage,
                        onRemove: _removeImage,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        diaryService
                                .isAnalyzing
                            ? null
                            : _handleAnalyze,
                    icon: diaryService
                            .isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .auto_awesome,
                          ),
                    label: Text(
                      diaryService
                              .isAnalyzing
                          ? 'Analyzing...'
                          : 'Analyze & Save',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final File? image;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerSection({
    required this.image,
    required this.isLoading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null) {
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

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            image!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
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
    );
  }
}
