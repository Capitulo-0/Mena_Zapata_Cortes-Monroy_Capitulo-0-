import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract interface class ChatDictation {
  Future<void> start({
    required ValueChanged<String> onText,
    required ValueChanged<String> onError,
    required VoidCallback onDone,
  });
  Future<void> stop();
  Future<void> cancel();
}

class DeviceChatDictation implements ChatDictation {
  DeviceChatDictation._();
  static final instance = DeviceChatDictation._();

  final _speech = SpeechToText();
  VoidCallback? _done;
  ValueChanged<String>? _error;
  int _session = 0;

  @override
  Future<void> start({
    required ValueChanged<String> onText,
    required ValueChanged<String> onError,
    required VoidCallback onDone,
  }) async {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      onError(
        'El dictado está disponible en navegadores compatibles y Android. Puedes escribir tu mensaje.',
      );
      return;
    }
    final session = ++_session;
    _done = onDone;
    _error = onError;
    try {
      final ready = await _speech.initialize(
        options: [SpeechToText.androidNoBluetooth],
        onStatus: (status) {
          if (status == SpeechToText.doneStatus) {
            final done = _done;
            _done = null;
            _error = null;
            done?.call();
          }
        },
        onError: (error) => _error?.call(switch (error.errorMsg) {
          'not-allowed' ||
          'service-not-allowed' ||
          'error_permission' ||
          'error_insufficient_permissions' ||
          'error_speech_recognizer_disabled' => 'El micrófono o el servicio de voz está bloqueado. Revisa los permisos o escribe tu mensaje.',
          'audio-capture' || 'error_audio_error' =>
            'No se pudo usar el micrófono. Conecta uno o escribe tu mensaje.',
          'no-speech' || 'error_no_match' || 'error_speech_timeout' =>
            'No se reconoció voz. Puedes intentarlo de nuevo o escribir.',
          _ => 'El servicio de voz no respondió. Puedes escribir tu mensaje.',
        }),
      );
      if (session != _session) return;
      if (!ready) {
        onError(
          'El dictado no está disponible. Revisa el permiso de micrófono y usa Chrome compatible en HTTPS o localhost, o escribe tu mensaje.',
        );
        return;
      }
      await _speech.listen(
        onResult: (result) {
          if (session == _session && result.finalResult) {
            onText(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: 'es-CL',
          listenMode: ListenMode.dictation,
          partialResults: false,
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
        ),
      );
      if (session != _session && _done == null) await _speech.cancel();
    } catch (_) {
      if (session == _session) {
        onError('No se pudo iniciar el dictado. Puedes escribir tu mensaje.');
      }
    }
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() {
    _session++;
    _done = null;
    _error = null;
    return _speech.cancel();
  }
}
