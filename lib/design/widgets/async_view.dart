import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../tokens.dart';
import 'spool_gauge.dart';

/// Loading / error / data for an [AsyncValue], in Sutra's own style (a spool, not a spinner).
class AsyncView<V> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.strings, required this.data, this.onRetry});

  final AsyncValue<V> value;
  final AppStrings strings;
  final Widget Function(V data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: data,
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: _WindingSpool())),
      error: (e, _) => ErrorNote(error: e, strings: strings, onRetry: onRetry),
    );
  }
}

class ErrorNote extends StatelessWidget {
  const ErrorNote({super.key, required this.error, required this.strings, this.onRetry});

  final Object error;
  final AppStrings strings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = ApiException.from(error);
    final message = strings.isHindi ? (e.messageHi ?? strings.somethingWrong) : e.message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: SutraColors.inkSoft, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: Text(strings.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A spool that winds and unwinds while we wait.
class _WindingSpool extends StatefulWidget {
  const _WindingSpool();

  @override
  State<_WindingSpool> createState() => _WindingSpoolState();
}

class _WindingSpoolState extends State<_WindingSpool> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => SpoolGauge(fill: 0.15 + 0.85 * _c.value, tone: Tone.ok, size: const Size(40, 50)),
    );
  }
}
