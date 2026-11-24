import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// A thread spool whose wound thread shrinks as stock runs out. Replaces progress bars for stock.
/// [fill] is 0..1 (share of a comfortable stock level); [tone] colours the thread.
class SpoolGauge extends StatelessWidget {
  const SpoolGauge({super.key, required this.fill, required this.tone, this.size = const Size(34, 42)});

  final double fill;
  final Tone tone;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fill.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: SutraMotion.curve,
      builder: (_, value, _) => CustomPaint(size: size, painter: _SpoolPainter(fill: value, thread: tone.ink)),
    );
  }
}

class _SpoolPainter extends CustomPainter {
  const _SpoolPainter({required this.fill, required this.thread});

  final double fill;
  final Color thread;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const flangeH = 5.0;
    final coreW = w * 0.28;
    final woundMax = w * 0.86;
    final wound = coreW + (woundMax - coreW) * fill;
    final top = flangeH;
    final bottom = h - flangeH;

    final wood = Paint()..color = const Color(0xFFC9A27A);
    final woodDark = Paint()..color = const Color(0xFF9C7350);

    // core
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, h / 2), width: coreW, height: bottom - top), woodDark);

    // wound thread: stacked rows with alternating shade, slight diagonal to suggest winding
    if (fill > 0.02) {
      final rows = ((bottom - top) / 3).floor();
      for (var i = 0; i < rows; i++) {
        final y = top + i * 3 + 1.5;
        final shade = i.isEven ? thread : Color.lerp(thread, Colors.white, 0.22)!;
        final bulge = math.sin((i / rows) * math.pi) * 1.5; // slightly fuller in the middle
        final half = wound / 2 + bulge * fill;
        final p = Paint()
          ..color = shade
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - half, y - 0.6), Offset(cx + half, y + 0.6), p);
      }
    }

    // flanges
    final flange = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, flangeH / 2), width: w, height: flangeH), const Radius.circular(2));
    canvas.drawRRect(flange, wood);
    canvas.drawRRect(flange.shift(Offset(0, h - flangeH)), wood);

    // a loose end of thread when nearly empty: it is about to run out
    if (fill < 0.25) {
      final loose = Paint()
        ..color = thread
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(cx + coreW / 2, h / 2)
        ..quadraticBezierTo(w, h * 0.65, w * 0.92, h - 2);
      canvas.drawPath(path, loose);
    }
  }

  @override
  bool shouldRepaint(covariant _SpoolPainter old) => old.fill != fill || old.thread != thread;
}
