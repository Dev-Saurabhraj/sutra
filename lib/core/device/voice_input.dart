import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-text behind an interface, so screens don't depend on the plugin (and tests can fake it).
abstract interface class VoiceInput {
  Future<bool> init();

  /// [onDone] fires when listening stops by itself (silence, time limit or an error),
  /// so the screen never stays stuck on "listening".
  Future<void> listen({required String localeId, required void Function(String text, bool isFinal) onText, void Function()? onDone});
  Future<void> stop();
  bool get isListening;
}

class DeviceVoiceInput implements VoiceInput {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  void Function()? _onDone;
  Set<String>? _locales;

  /// Asks for the mic permission when needed. A "no" is not remembered: the next tap asks again,
  /// so allowing the mic in settings later works without restarting the app.
  @override
  Future<bool> init() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(
        onError: (_) => _finish(),
        onStatus: (status) {
          if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) _finish();
        },
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  void _finish() {
    final done = _onDone;
    _onDone = null;
    done?.call();
  }

  @override
  Future<void> listen({required String localeId, required void Function(String text, bool isFinal) onText, void Function()? onDone}) async {
    if (!await init()) return;
    _onDone = onDone;
    // Phones without the Hindi speech pack fail on hi_IN: fall back to the phone's own language.
    _locales ??= {for (final l in await _stt.locales()) l.localeId.replaceAll('-', '_')};
    final locale = _locales!.isEmpty || _locales!.contains(localeId) ? localeId : null;
    await _stt.listen(
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: locale,
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
