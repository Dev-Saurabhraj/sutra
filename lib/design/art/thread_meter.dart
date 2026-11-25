import 'package:flutter/material.dart';

import '../tokens.dart';

/// A woven bar: grows to [value] (0..1) with a diagonal weave texture.
/// Used for amounts that compare against each other (tax collected vs credit) and for limits.
class WovenBar extends StatelessWidget {
  const WovenBar({super.key, required this.value, required this.color, this.height = 18, this.marker});

  final double value;
  final Color color;
  final double height;

  /// Optional tick (0..1), e.g. the 80% "watch" point on a limit.
  final double? marker;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: SutraMotion.curve,
      builder: (_, v, _) => CustomPaint(size: Size.fromHeight(height), painter: _WovenBarPainter(v, color, marker)),
    );
  }
}

class _WovenBarPainter extends CustomPainter {
  const _WovenBarPainter(this.value, this.color, this.marker);
  final double value;
  final Color color;
  final double? marker;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(track, Paint()..color = SutraColors.rule.withValues(alpha: 0.7));
    final w = size.width * value;
    if (w > 0) {
      final bar = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, size.height), r);
      canvas.save();
      canvas.clipRRect(bar);
      canvas.drawRect(Offset.zero & size, Paint()..color = color);
      final weave = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 2;
      for (var x = -size.height; x < w; x += 7) {
        canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), weave);
      }
      canvas.restore();
    }
    if (marker != null) {
      final x = size.width * marker!;
      canvas.drawLine(Offset(x, -3), Offset(x, size.height + 3), Paint()
        ..color = SutraColors.ink
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _WovenBarPainter old) => old.value != value || old.color != color || old.marker != marker;
}
