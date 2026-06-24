import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  bool _manualStop = false;

  Function(String words)? _onResultCallback;
  Function(String partial)? _onPartialResultCallback;
  Function(String)? _onErrorCallback;
  Function()? _onListeningStopCallback;
  String? _localeId;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (SpeechRecognitionError error) {
        if (!_isListening) return;
        final msg = error.errorMsg;
        if (msg == 'error_speech_timeout' || msg == 'error_no_match') return;
        _isListening = false;
        _manualStop = true;
        FirebaseCrashlytics.instance.recordError(
          Exception(msg), null, fatal: false, reason: 'Speech recognition error',
        );
        if (msg.contains('network') || msg.contains('error_network')) {
          _onErrorCallback?.call('Fitur rekam suara membutuhkan koneksi internet');
        } else {
          _onErrorCallback?.call(msg);
        }
        _clearCallbacks();
      },
      onStatus: (String status) {
        if (!_isListening) return;
        
        if (status == 'done') {
          if (_manualStop) {
            _isListening = false;
            _onListeningStopCallback?.call();
            _clearCallbacks();
          } else {
            _restartListening();
          }
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

    _onResultCallback = onResult;
    _onPartialResultCallback = onPartialResult;
    _onErrorCallback = (String error) {
      onError?.call(error);
      onListeningStop();
    };
    _onListeningStopCallback = onListeningStop;
    _manualStop = false;
    _isListening = true;

    _localeId = null;
    try {
      final locales = await _speech.locales();
      _localeId = locales.any((l) => l.localeId == 'id_ID')
          ? 'id_ID'
          : (await _speech.systemLocale())?.localeId;
    } catch (_) {}

    await _listen();
  }

  Future<void> _listen() async {
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (result.recognizedWords.isNotEmpty) {
            _onResultCallback?.call(result.recognizedWords);
          }
        } else {
          _onPartialResultCallback?.call(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        listenFor: const Duration(seconds: 120),
        
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  Future<void> _restartListening() async {
  
    await Future.delayed(const Duration(milliseconds: 50));
    if (!_isListening || _manualStop || _speech.isListening) return;
    try {
      await _listen();
    } catch (e) {
      _isListening = false;
      FirebaseCrashlytics.instance.recordError(
        e, null, fatal: false, reason: 'Speech restart failed',
      );
      _onErrorCallback?.call('Gagal melanjutkan rekaman suara');
      _clearCallbacks();
    }
  }

  Future<void> stopListening() async {
    _manualStop = true;
    _isListening = false;
    _clearCallbacks();
    await _speech.stop();
  }

  void dispose() {
    _manualStop = true;
    _isListening = false;
    _clearCallbacks();
    _speech.cancel();
  }

  void _clearCallbacks() {
    _onResultCallback = null;
    _onPartialResultCallback = null;
    _onErrorCallback = null;
    _onListeningStopCallback = null;
  }
}
