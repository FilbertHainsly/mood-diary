import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  Function(String)? _onErrorCallback;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (SpeechRecognitionError error) {
        _isListening = false;
        final msg = error.errorMsg;
        if (msg.contains('network') || msg.contains('error_network')) {
          _onErrorCallback?.call(
            'Fitur rekam suara membutuhkan koneksi internet',
          );
        } else {
          _onErrorCallback?.call(msg);
        }
        _onErrorCallback = null;
      },
      onStatus: (String status) {
        if (status == 'done' ||
            status == 'notListening' ||
            status == 'doneNoResult') {
          _isListening = false;
        }
      },
    );
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String words) onResult,
    required Function() onListeningStop,
    Function(String error)? onError,
  }) async {
    if (!_isAvailable || _isListening) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Izin mikrofon diperlukan untuk fitur ini';
    }

    _onErrorCallback = (String error) {
      onError?.call(error);
      onListeningStop();
    };

    _isListening = true;

    String? localeId;
    try {
      final locales = await _speech.locales();
      if (locales.any((l) => l.localeId == 'id_ID')) {
        localeId = 'id_ID';
      } else {
        final systemLocale = await _speech.systemLocale();
        localeId = systemLocale?.localeId;
      }
    } catch (_) {
      localeId = null;
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          _onErrorCallback = null;
          onResult(result.recognizedWords);
          onListeningStop();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    _onErrorCallback = null;
    await _speech.stop();
  }

  void dispose() {
    _onErrorCallback = null;
    _speech.cancel();
  }
}
