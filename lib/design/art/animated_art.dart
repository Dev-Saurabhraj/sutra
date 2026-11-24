import 'package:flutter/material.dart';

/// Builds a painter for a moment `t` in a looping 0..1 cycle.
typedef ArtPainter = CustomPainter Function(double t);

/// A looping, code-drawn illustration. Vector art, no image files: crisp at any size,
/// tiny on a 2 GB phone, works offline. Shows a still frame when the OS asks for reduced motion.
class AnimatedArt extends StatefulWidget {
  const AnimatedArt({super.key, required this.painter, this.period = const Duration(seconds: 3), this.still = 0.3, this.semanticLabel});

  final ArtPainter painter;
  final Duration period;

  /// The frame shown when animations are disabled.
  final double still;
  final String? semanticLabel;

  @override
  State<AnimatedArt> createState() => _AnimatedArtState();
}

class _AnimatedArtState extends State<AnimatedArt> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _clock
        ..stop()
        ..value = widget.still;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _clock,
          builder: (_, _) => CustomPaint(painter: widget.painter(_clock.value), size: Size.infinite),
        ),
      ),
    );
  }
}
