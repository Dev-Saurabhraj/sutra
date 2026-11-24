import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// A tarazu (balance scale): money to receive on the left pan, money to pay on the right.
/// It tilts toward the heavier side and settles with a small sway, so "am I owed or do I owe?" is seen at a glance.
class BalanceScale extends StatefulWidget {
  const BalanceScale({super.key, required this.receive, required this.pay, this.size = const Size(150, 96)});

  final double receive;
  final double pay;
  final Size size;

  @override
  State<BalanceScale> createState() => _BalanceScaleState();
}

class _BalanceScaleState extends State<BalanceScale> with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void didUpdateWidget(covariant BalanceScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receive != widget.receive || oldWidget.pay != widget.pay) _settle.forward(from: 0);
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  /// -1 (all to pay) … +1 (all to receive), mapped to at most ~14° of tilt.
  double get _target {
    final total = widget.receive + widget.pay;
    if (total <= 0) return 0;
    return ((widget.receive - widget.pay) / total).clamp(-1.0, 1.0) * 0.24;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: _settle,
      builder: (_, _) {
        final p = reduce ? 1.0 : _settle.value;
        // damped sway around the target angle
        final sway = math.sin(p * math.pi * 3) * (1 - p) * 0.12;
        return CustomPaint(size: widget.size, painter: _ScalePainter(angle: -(_target * Curves.easeOut.transform(p)) + sway));
      },
    );
  }
}

class _ScalePainter extends CustomPainter {
  const _ScalePainter({required this.angle});
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = size.height * 0.16;
    final brass = Paint()..color = const Color(0xFFB8862B);
    final dark = Paint()..color = const Color(0xFF7A5210);

    // stand
    canvas.drawRect(Rect.fromLTWH(cx - 2, top, 4, size.height * 0.72), dark);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, size.height - 4), width: size.width * 0.34, height: 6), const Radius.circular(3)), dark);
    canvas.drawCircle(Offset(cx, top), 5, brass);

    // beam
    final half = size.width * 0.42;
    final left = Offset(cx - math.cos(angle) * half, top - math.sin(angle) * half);
    final right = Offset(cx + math.cos(angle) * half, top + math.sin(angle) * half);
    canvas.drawLine(left, right, Paint()
      ..color = const Color(0xFF9A6B12)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);

    _pan(canvas, left, size, SutraColors.neel); // लेना
    _pan(canvas, right, size, SutraColors.sindoor); // देना
  }

  void _pan(Canvas canvas, Offset hook, Size size, Color coins) {
    final drop = size.height * 0.36;
    final w = size.width * 0.26;
    final string = Paint()
      ..color = const Color(0xFF9A6B12)
      ..strokeWidth = 1;
    final panCenter = hook + Offset(0, drop);
    canvas.drawLine(hook, panCenter + Offset(-w / 2, 0), string);
    canvas.drawLine(hook, panCenter + Offset(w / 2, 0), string);
    // coins stacked in the pan
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(Rect.fromCenter(center: panCenter + Offset((i - 1) * 7.0, -3 - (i == 1 ? 3 : 0)), width: 9, height: 4.5), Paint()..color = coins);
    }
    final pan = Path()
      ..moveTo(panCenter.dx - w / 2, panCenter.dy)
      ..quadraticBezierTo(panCenter.dx, panCenter.dy + 12, panCenter.dx + w / 2, panCenter.dy)
      ..close();
    canvas.drawPath(pan, Paint()..color = const Color(0xFFE9C46A));
  }

  @override
  bool shouldRepaint(covariant _ScalePainter old) => old.angle != angle;
}
