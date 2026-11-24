import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/async_view.dart';
import '../../design/widgets/thread_stripe.dart';
import '../auth/presentation/session_controller.dart';

/// Shown while the stored session is checked, or when the server can't be reached at start.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.appName, style: SutraType.display(56, color: SutraColors.sindoor)),
              const SizedBox(height: 10),
              const SizedBox(width: 160, child: ThreadStripe(height: 5, radius: 3)),
              const SizedBox(height: 10),
              Text(s.tagline, style: SutraType.display(16, color: SutraColors.inkSoft, weight: FontWeight.w600)),
              if (session.hasError)
                ErrorNote(error: session.error!, strings: s, onRetry: () => ref.read(sessionControllerProvider.notifier).retry()),
            ],
          ),
        ),
      ),
    );
  }
}
