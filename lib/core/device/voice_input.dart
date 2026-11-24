import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-text behind an interface, so screens don't depend on the plugin (and tests can fake it).
abstract interface class VoiceInput {
  Future<bool> init();
  Future<void> listen({required String localeId, required void Function(String text, bool isFinal) onText});
  Future<void> stop();
  bool get isListening;
}

class DeviceVoiceInput implements VoiceInput {
  final SpeechToText _stt = SpeechToText();
  bool? _available;

  @override
  Future<bool> init() async {
    try {
      return _available ??= await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    } catch (_) {
      return _available = false;
    }
  }

  @override
  Future<void> listen({required String localeId, required void Function(String text, bool isFinal) onText}) async {
    if (!await init()) return;
    await _stt.listen(
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stop() => _stt.stop();

  @override
  bool get isListening => _stt.isListening;
}
