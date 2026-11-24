import 'package:flutter_tts/flutter_tts.dart';

/// Reads results aloud (RULES B1: every result can be heard).
abstract interface class Speaker {
  Future<void> say(String text, {required bool hindi});
  Future<void> stop();
}

class DeviceSpeaker implements Speaker {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> say(String text, {required bool hindi}) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(hindi ? 'hi-IN' : 'en-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (_) {
      // No TTS engine on this device: the text is on screen anyway.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
