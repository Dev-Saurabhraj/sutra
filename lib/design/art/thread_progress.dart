import 'package:flutter/material.dart';

import '../tokens.dart';

/// Onboarding progress as cloth being woven: finished steps are woven stripes,
/// the current step has a needle going in and out, the rest is bare warp.
class ThreadProgress extends StatefulWidget {
  const ThreadProgress({super.key, required this.steps, required this.current});

  final int steps;
  final int current;

  @override
  State<ThreadProgress> createState() => _ThreadProgressState();
}

class _ThreadProgressState extends State<ThreadProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _needle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _needle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.current + 1} / ${widget.steps}',
      child: SizedBox(
        height: 14,
        child: AnimatedBuilder(
          animation: _needle,
          builder: (_, _) => CustomPaint(
            size: Size.infinite,
            painter: _WeavePainter(steps: widget.steps, current: widget.current, needle: _needle.value),
          ),
        ),
      ),
    );
  }
}

class _WeavePainter extends CustomPainter {
  const _WeavePainter({required this.steps, required this.current, required this.needle});

  final int steps;
  final int current;
  final double needle;

  static const _dyes = [SutraColors.sindoor, SutraColors.haldi, SutraColors.neel];

  @override
  void paint(Canvas canvas, Size size) {
    final gap = 4.0;
    final w = (size.width - gap * (steps - 1)) / steps;
    for (var i = 0; i < steps; i++) {
      final x = i * (w + gap);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, 3, w, size.height - 6), const Radius.circular(4));
      if (i < current) {
        canvas.drawRRect(r, Paint()..color = _dyes[i % 3]);
        // little weft ticks so it reads as woven, not a plain bar
        for (var k = x + 4; k < x + w - 2; k += 6) {
          canvas.drawLine(Offset(k, 5), Offset(k, size.height - 5), Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..strokeWidth = 1);
        }
      } else if (i == current) {
        canvas.drawRRect(r, Paint()..color = SutraColors.rule);
        final fillW = w * (0.35 + 0.3 * needle);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 3, fillW, size.height - 6), const Radius.circular(4)), Paint()..color = _dyes[i % 3]);
        canvas.drawCircle(Offset(x + fillW, size.height / 2), 4, Paint()..color = SutraColors.ink);
      } else {
        canvas.drawRRect(r, Paint()..color = SutraColors.rule.withValues(alpha: 0.7));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeavePainter old) => old.current != current || old.needle != needle || old.steps != steps;
}
