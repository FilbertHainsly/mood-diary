import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  Function(String)? _onErrorCallback;
  Function()? _onListeningStopCallback;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (SpeechRecognitionError error) {
        if (!_isListening) return;
        final msg = error.errorMsg;
        // Silence / no-match errors are not fatal — library continues
        if (msg == 'error_speech_timeout' || msg == 'error_no_match') return;
        _isListening = false;
        FirebaseCrashlytics.instance.recordError(
          Exception(msg), null, fatal: false, reason: 'Speech recognition error',
        );
        if (msg.contains('network') || msg.contains('error_network')) {
          _onErrorCallback?.call('Fitur rekam suara membutuhkan koneksi internet');
        } else {
          _onErrorCallback?.call(msg);
        }
        _onErrorCallback = null;
        _onListeningStopCallback = null;
      },
      onStatus: (String status) {
        // 'done' only fires when the whole session truly ends (not between
        // internal restarts that speech_to_text handles automatically)
        if (status == 'done' && _isListening) {
          _isListening = false;
          _onListeningStopCallback?.call();
          _onListeningStopCallback = null;
          _onErrorCallback = null;
        }
      },
    );
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String words) onResult,
    required Function() onListeningStop,
    Function(String error)? onError,
    Function(String partial)? onPartialResult,
  }) async {
    if (!_isAvailable || _isListening) return;

    FirebaseCrashlytics.instance.log('User memulai speech-to-text');
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Izin mikrofon diperlukan untuk fitur ini';
    }

    _onErrorCallback = (String error) {
      onError?.call(error);
      onListeningStop();
    };
    _onListeningStopCallback = onListeningStop;
    _isListening = true;

    String? localeId;
    try {
      final locales = await _speech.locales();
      localeId = locales.any((l) => l.localeId == 'id_ID')
          ? 'id_ID'
          : (await _speech.systemLocale())?.localeId;
    } catch (_) {}

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    _onErrorCallback = null;
    _onListeningStopCallback = null;
    await _speech.stop();
  }

  void dispose() {
    _isListening = false;
    _onErrorCallback = null;
    _onListeningStopCallback = null;
    _speech.cancel();
  }
}
