import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/diary_entry.dart';
import '../../services/diary_service.dart';
import '../../services/speech_service.dart';

class EditDiaryScreen extends StatefulWidget {
  final DiaryEntry diary;

  const EditDiaryScreen({super.key, required this.diary});

  @override
  State<EditDiaryScreen> createState() => _EditDiaryScreenState();
}

class _EditDiaryScreenState extends State<EditDiaryScreen>
    with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.diary.title);
    _textController = TextEditingController(text: widget.diary.diaryText);
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speechService.initialize();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) &&
        _isListening) {
      _speechService.stopListening();
      if (mounted) setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speechService.stopListening();
    _speechService.dispose();
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    try {
      setState(() => _isListening = true);
      await _speechService.startListening(
        onResult: (words) {
          if (!mounted) return;
          if (words.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Suara tidak terdeteksi, coba lagi'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          final current = _textController.text;
          final separator =
              current.isEmpty || current.endsWith(' ') ? '' : ' ';
          _textController.text = '$current$separator$words';
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        },
        onListeningStop: () {
          if (mounted) setState(() => _isListening = false);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } on String {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izin mikrofon ditolak'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Buka Pengaturan',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    final newTitle = _titleController.text.trim();
    final newText = _textController.text.trim();

    if (newTitle.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul minimal 3 karakter'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (newText.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulis minimal 10 karakter'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final titleChanged = newTitle != widget.diary.title;
    final textChanged = newText != widget.diary.diaryText;

    if (!titleChanged && !textChanged) {
      Navigator.pop(context);
      return;
    }

    final diaryService = context.read<DiaryService>();

    final success = await diaryService.reanalyzeAndUpdate(
      id: widget.diary.id,
      title: newTitle,
      newDiaryText: newText,
      oldDiaryText: widget.diary.diaryText,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diary diperbarui ✓'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              diaryService.errorMessage ?? 'Gagal memperbarui diary'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DiaryService>().isSaving;
    final isMicAvailable = _speechService.isAvailable;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _isListening ? null : _handleSave,
              child: Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isListening
                      ? AppTheme.textSecondary
                      : AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Judul',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const Divider(height: 24, thickness: 1),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  TextField(
                    controller: _textController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      height: 1.6,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tulis diarimu di sini...',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    minLines: 20,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Tooltip(
                      message: isMicAvailable
                          ? ''
                          : 'Speech-to-text tidak tersedia di perangkat ini',
                      child: Opacity(
                        opacity: isMicAvailable ? 1.0 : 0.3,
                        child: GestureDetector(
                          onTap: isMicAvailable ? _toggleMic : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening
                                  ? Colors.red
                                  : Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isListening)
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sedang mendengarkan... Tap mic untuk berhenti',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
