import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_exception.dart';
import '../../home/data/home_repository.dart';
import '../../khata/data/khata_repository.dart';
import '../../stock/data/stock_repository.dart';
import '../data/voice_repository.dart';
import '../domain/voice_models.dart';

enum VoicePhase { idle, listening, understanding, preview, saving, saved }

class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.idle,
    this.transcript = '',
    this.preview,
    this.results = const [],
    this.error,
    this.micAvailable = true,
  });

  final VoicePhase phase;
  final String transcript;
  final VoicePreview? preview;
  final List<VoiceResult> results;
  final ApiException? error;
  final bool micAvailable;

  bool get busy => phase == VoicePhase.understanding || phase == VoicePhase.saving;

  VoiceState copyWith({
    VoicePhase? phase,
    String? transcript,
    VoicePreview? preview,
    bool clearPreview = false,
    List<VoiceResult>? results,
    ApiException? error,
    bool clearError = false,
    bool? micAvailable,
  }) =>
      VoiceState(
        phase: phase ?? this.phase,
        transcript: transcript ?? this.transcript,
        preview: clearPreview ? null : preview ?? this.preview,
        results: results ?? this.results,
        error: clearError ? null : error ?? this.error,
        micAvailable: micAvailable ?? this.micAvailable,
      );
}

/// Speak → preview → confirm. Nothing is written until the user says yes (RULES B2).
class VoiceController extends AutoDisposeNotifier<VoiceState> {
  @override
  VoiceState build() {
    ref.onDispose(() => ref.read(voiceInputProvider).stop());
    return const VoiceState();
  }

  bool get _hindi => ref.read(stringsProvider).isHindi;

  Future<void> toggleMic() async {
    final mic = ref.read(voiceInputProvider);
    if (state.phase == VoicePhase.listening) {
      await mic.stop();
      state = state.copyWith(phase: VoicePhase.idle);
      if (state.transcript.trim().isNotEmpty) await understand();
      return;
    }
    if (!await mic.init()) {
      state = state.copyWith(micAvailable: false);
      return;
    }
    state = const VoiceState(phase: VoicePhase.listening);
    await mic.listen(
      localeId: _hindi ? 'hi_IN' : 'en_IN',
      onText: (text, isFinal) {
        state = state.copyWith(transcript: text);
        if (isFinal && state.phase == VoicePhase.listening) {
          state = state.copyWith(phase: VoicePhase.idle);
          understand();
        }
      },
    );
  }

  void setText(String text) => state = state.copyWith(transcript: text, clearError: true);

  Future<void> understand([String? text]) async {
    final transcript = (text ?? state.transcript).trim();
    if (transcript.isEmpty) return;
    state = state.copyWith(phase: VoicePhase.understanding, transcript: transcript, clearError: true, clearPreview: true, results: const []);
    try {
      final preview = await ref.read(voiceRepositoryProvider).preview(transcript);
      state = state.copyWith(phase: VoicePhase.preview, preview: preview);
      ref.read(speakerProvider).say('${preview.replyHi} सही है?', hindi: true);
    } catch (e) {
      state = state.copyWith(phase: VoicePhase.idle, error: ApiException.from(e));
    }
  }

  Future<void> confirm() async {
    final preview = state.preview;
    if (preview == null || !preview.canSave) return;
    state = state.copyWith(phase: VoicePhase.saving, clearError: true);
    try {
      final results = await ref.read(voiceRepositoryProvider).confirm(preview.entryId);
      state = state.copyWith(phase: VoicePhase.saved, results: results, clearPreview: true);
      ref.read(speakerProvider).say(results.map((r) => _hindi ? r.textHi : r.text).join('। '), hindi: _hindi);
      ref
        ..invalidate(homeProvider)
        ..invalidate(materialsProvider)
        ..invalidate(productsProvider)
        ..invalidate(khataPageProvider);
    } catch (e) {
      state = state.copyWith(phase: VoicePhase.preview, error: ApiException.from(e));
    }
  }

  void discard() => state = const VoiceState();
}

final voiceControllerProvider = NotifierProvider.autoDispose<VoiceController, VoiceState>(VoiceController.new);
