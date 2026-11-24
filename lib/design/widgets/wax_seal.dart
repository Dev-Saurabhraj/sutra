import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// A wax seal pressed next to a fact that was checked (GSTIN format, Udyam, a quality mark).
/// Unchecked facts get a plain outline instead: the difference is visible at a glance.
class WaxSeal extends StatelessWidget {
  const WaxSeal({super.key, this.checked = true, this.color = SutraColors.sindoor, this.size = 30, this.icon = Icons.check_rounded});

  final bool checked;
  final Color color;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SealPainter(checked: checked, color: color),
        child: Center(child: Icon(checked ? icon : Icons.remove_rounded, size: size * 0.5, color: checked ? Colors.white : SutraColors.inkSoft)),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter({required this.checked, required this.color});
  final bool checked;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // a blobby, pressed edge: 14 soft lobes
    final edge = Path();
    const lobes = 14;
    for (var i = 0; i <= lobes * 4; i++) {
      final a = i / (lobes * 4) * 2 * math.pi;
      final rr = r * (0.9 + 0.08 * math.sin(a * lobes));
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? edge.moveTo(p.dx, p.dy) : edge.lineTo(p.dx, p.dy);
    }
    edge.close();
    if (!checked) {
      canvas.drawPath(edge, Paint()..color = SutraColors.rule..style = PaintingStyle.stroke..strokeWidth = 1.4);
      return;
    }
    canvas.drawPath(edge, Paint()..color = color);
    // inner pressed ring and a highlight, so it reads as wax
    canvas.drawCircle(c, r * 0.66, Paint()..color = Colors.black.withValues(alpha: 0.14)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.78), -2.6, 1.1, false,
        Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1.6..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _SealPainter old) => old.checked != checked || old.color != color;
}
