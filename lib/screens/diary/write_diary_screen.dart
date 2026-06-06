
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../services/diary_service.dart';
import '../../services/firebase_auth_service.dart';
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
                        minLines: 15,
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

