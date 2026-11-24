import 'package:flutter/material.dart';

import '../tokens.dart';

/// A rubber-stamp status mark: inked double border, uppercase, slightly rotated.
/// With [thunk], it lands with a small press (scale 1.15 → 1.0) — used when an entry is saved.
class Stamp extends StatefulWidget {
  const Stamp(this.label, {super.key, this.tone = Tone.neutral, this.thunk = false, this.angle = -0.07, this.size = 11});

  final String label;
  final Tone tone;
  final bool thunk;
  final double angle;
  final double size;

  @override
  State<Stamp> createState() => _StampState();
}

class _StampState extends State<Stamp> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(vsync: this, duration: SutraMotion.normal, value: widget.thunk ? 0 : 1);

  @override
  void initState() {
    super.initState();
    if (widget.thunk) _press.forward();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.tone.ink;
    final scale = Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)).animate(_press);
    return Semantics(
      label: widget.label,
      child: ScaleTransition(
        scale: scale,
        child: FadeTransition(
          opacity: _press,
          child: Transform.rotate(
            angle: widget.angle,
            child: Container(
              padding: const EdgeInsets.all(1.6),
              decoration: BoxDecoration(
                border: Border.all(color: ink.withValues(alpha: 0.85), width: 1.6),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.6, vertical: widget.size * 0.18),
                decoration: BoxDecoration(
                  border: Border.all(color: ink.withValues(alpha: 0.6), width: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.9),
                    fontSize: widget.size,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
