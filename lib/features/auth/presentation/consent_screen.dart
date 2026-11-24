import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/parchi.dart';
import 'session_controller.dart';

/// DPDP-ready notice in the user's language, shown once per notice version (RULES C2).
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Text(s.consentTitle, style: SutraType.display(28)),
                const SizedBox(height: 20),
                Parchi(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final point in s.consentPoints)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3, right: 10),
                                child: Icon(Icons.check_circle_outline_rounded, color: SutraColors.neel, size: 20),
                              ),
                              Expanded(child: Text(point, style: text.bodyLarge)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ListenChip(
                          label: s.listen,
                          onTap: () => ref.read(speakerProvider).say(s.consentPoints.join('। '), hindi: s.isHindi),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await ref.read(sessionControllerProvider.notifier).acceptConsent();
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Text(s.consentAgree),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
