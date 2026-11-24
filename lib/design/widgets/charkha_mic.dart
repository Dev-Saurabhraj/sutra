import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// The voice button: a charkha (spinning wheel). While listening the wheel turns and thread
/// winds onto it — "spinning your words into entries".
class CharkhaMic extends StatefulWidget {
  const CharkhaMic({
    super.key,
    required this.listening,
    required this.onTap,
    this.size = 132,
    this.enabled = true,
    this.selected = false,
    this.semanticLabel,
  });

  final bool listening;

  /// Shown as the current place (e.g. the voice tab is open) without pretending to record.
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<CharkhaMic> createState() => _CharkhaMicState();
}

class _CharkhaMicState extends State<CharkhaMic> with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late final AnimationController _wind = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant CharkhaMic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listening != widget.listening) _sync();
  }

  void _sync() {
    if (widget.listening) {
      _spin.repeat();
      _wind.forward(from: 0);
    } else {
      _spin.stop();
      _wind.reverse();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _wind.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = !widget.enabled
        ? SutraColors.inkSoft
        : (widget.listening || widget.selected ? SutraColors.sindoor : SutraColors.neel);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: SutraMotion.normal,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.listening ? SutraColors.sindoorWash : SutraColors.neelWash,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: widget.listening ? 28 : 14, spreadRadius: widget.listening ? 4 : 0)],
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_spin, _wind]),
            builder: (_, _) => CustomPaint(
              painter: _CharkhaPainter(turn: _spin.value, wound: _wind.value, color: color),
              child: Center(
                child: Icon(widget.listening ? Icons.stop_rounded : Icons.mic_rounded, color: color, size: widget.size * 0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharkhaPainter extends CustomPainter {
  const _CharkhaPainter({required this.turn, required this.wound, required this.color});

  final double turn;
  final double wound;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.40;
    final rim = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035;
    final spoke = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = size.shortestSide * 0.018
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r, rim);
    // the wheel's two rims are joined by criss-cross string on a real charkha
    canvas.drawCircle(c, r * 0.86, rim..strokeWidth = size.shortestSide * 0.012);

    const spokes = 8;
    for (var i = 0; i < spokes; i++) {
      final a = turn * 2 * math.pi + i * math.pi / spokes * 2;
      final inner = c + Offset(math.cos(a), math.sin(a)) * (r * 0.30);
      final outer = c + Offset(math.cos(a), math.sin(a)) * (r * 0.86);
      canvas.drawLine(inner, outer, spoke);
    }

    // thread winding: an arc of haldi thread that grows around the wheel while listening
    if (wound > 0) {
      final thread = Paint()
        ..color = SutraColors.haldi
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.03
        ..strokeCap = StrokeCap.round;
      final start = -math.pi / 2 + turn * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r * 1.12), start, wound * 2 * math.pi * 0.92, false, thread);
    }
  }

  @override
  bool shouldRepaint(covariant _CharkhaPainter old) => old.turn != turn || old.wound != wound || old.color != color;
}
