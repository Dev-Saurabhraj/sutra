import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/gst/gstin.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_models.dart';

/// The steps, in order. Traders skip raw materials (they buy finished goods).
enum OnbStep { welcome, you, trade, place, gst, materials, products, team, done }

class OnboardingState {
  const OnboardingState({this.step = OnbStep.welcome, this.draft = const OnboardingDraft(), this.submitting = false, this.error});

  final OnbStep step;
  final OnboardingDraft draft;
  final bool submitting;
  final ApiException? error;

  List<OnbStep> get steps => [for (final s in OnbStep.values) if (!(draft.isTrader && s == OnbStep.materials)) s];
  int get index => steps.indexOf(step);
  bool get isLast => step == OnbStep.done;

  /// Can the user move on from this step?
  bool get canContinue => switch (step) {
        OnbStep.welcome || OnbStep.team || OnbStep.done => true,
        OnbStep.you => draft.name.trim().length >= 2 && draft.businessName.trim().length >= 2,
        OnbStep.trade => draft.industryKey != null,
        OnbStep.place => draft.city.trim().length >= 2 && draft.state != null && draft.machines >= 1,
        OnbStep.gst => draft.gst == GstChoice.unregistered || checkGstin(draft.gstin, state: draft.state) == null,
        OnbStep.materials => draft.materials.any((m) => m.include),
        OnbStep.products => draft.products.any((p) => p.include && p.price > 0),
      };

  OnboardingState copyWith({OnbStep? step, OnboardingDraft? draft, bool? submitting, ApiException? error, bool clearError = false}) => OnboardingState(
        step: step ?? this.step,
        draft: draft ?? this.draft,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : error ?? this.error,
      );
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void update(OnboardingDraft Function(OnboardingDraft d) change) => state = state.copyWith(draft: change(state.draft), clearError: true);

  /// Choosing what they make loads that industry's materials, products and usual way of paying workers.
  void chooseIndustry(IndustryTemplate t) {
    final d = state.draft;
    if (d.industryKey == t.key) return;
    state = state.copyWith(draft: d.copyWith(industryKey: t.key, materials: t.materials, products: t.products), clearError: true);
  }

  void next() {
    final s = state;
    if (!s.canContinue) return;
    final i = s.index;
    if (i < s.steps.length - 1) state = s.copyWith(step: s.steps[i + 1], clearError: true);
  }

  void back() {
    final i = state.index;
    if (i > 0) state = state.copyWith(step: state.steps[i - 1], clearError: true);
  }

  Future<void> submit() async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await ref.read(onboardingRepositoryProvider).submit(state.draft, language: ref.read(langProvider).code);
      await ref.read(sessionControllerProvider.notifier).reload();
    } catch (e) {
      state = state.copyWith(submitting: false, error: ApiException.from(e));
    }
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, OnboardingState>(OnboardingController.new);
