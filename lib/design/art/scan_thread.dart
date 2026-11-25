import 'package:flutter/material.dart';

import '../tokens.dart';

/// While a bill is being read, a haldi thread stitches its way down the photo:
/// the part already "read" gets a light sindoor wash and a row of stitches.
class ScanThread extends StatefulWidget {
  const ScanThread({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  State<ScanThread> createState() => _ScanThreadState();
}

class _ScanThreadState extends State<ScanThread> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ScanThread old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.active && !reduce) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (widget.active)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(painter: _ScanPainter(Curves.easeInOut.transform(_c.value))),
            ),
          ),
      ],
    );
  }
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, y), Paint()..color = SutraColors.sindoor.withValues(alpha: 0.10));
    // stitches along the read edge
    final stitch = Paint()
      ..color = SutraColors.sindoor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 6.0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, y - 6), Offset(x + 6, y - 6), stitch);
    }
    // the thread itself, with a soft glow
    canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()
      ..color = SutraColors.haldi.withValues(alpha: 0.35)
      ..strokeWidth = 10);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()
      ..color = SutraColors.haldi
      ..strokeWidth = 2.6);
    // the needle leading the thread
    final nx = size.width * (0.15 + 0.7 * t);
    final needle = Path()
      ..moveTo(nx - 10, y)
      ..lineTo(nx + 12, y - 2)
      ..lineTo(nx + 12, y + 2)
      ..close();
    canvas.drawPath(needle, Paint()..color = SutraColors.ink);
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => old.t != t;
}
