import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/art/thread_progress.dart';
import '../../../design/tokens.dart';
import 'onboarding_controller.dart';
import 'onboarding_steps.dart';
import 'onboarding_text.dart';

/// First-run setup for any small business. One question per screen, big choices,
/// and the answers decide how the app looks afterwards (industry words, making vs trading, GST bills, team).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final st = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: st.index > 0 && !st.submitting ? ctrl.back : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: s.tr(OnbText.back),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: ThreadProgress(steps: st.steps.length, current: st.index)),
                      const SizedBox(width: 12),
                      Text('${st.index + 1}/${st.steps.length}', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: SutraMotion.normal,
                    switchInCurve: SutraMotion.curve,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim), child: child),
                    ),
                    child: KeyedSubtree(key: ValueKey(st.step), child: stepView(st.step)),
                  ),
                ),
                _BottomBar(state: st, strings: s, onNext: st.isLast ? ctrl.submit : ctrl.next),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.strings, required this.onNext});

  final OnboardingState state;
  final AppStrings strings;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final err = state.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(strings.isHindi ? (err.messageHi ?? err.message) : err.message, style: const TextStyle(color: SutraColors.kumkum)),
            ),
          FilledButton(
            onPressed: state.canContinue && !state.submitting ? onNext : null,
            child: state.submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(strings.tr(state.isLast ? OnbText.start : OnbText.next)),
          ),
        ],
      ),
    );
  }
}
