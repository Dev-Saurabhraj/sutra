import 'package:flutter/material.dart';

import '../tokens.dart';

/// An order's journey as one thread with knots: woven where it has been, bare where it is going,
/// and a shuttle resting at the current knot. Labels sit in equal columns right under their knots.
class StageThread extends StatelessWidget {
  const StageThread({super.key, required this.labels, required this.current, this.stopped = false});

  final List<String> labels;
  final int current;

  /// Declined: the thread is cut after the first knot.
  final bool stopped;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelMedium;
    return Semantics(
      label: labels[current.clamp(0, labels.length - 1)],
      child: Column(
        children: [
          SizedBox(height: 34, child: CustomPaint(size: Size.infinite, painter: _ThreadPainter(count: labels.length, current: current, stopped: stopped))),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text?.copyWith(
                      color: i <= current && !stopped ? SutraColors.ink : SutraColors.inkSoft,
                      fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThreadPainter extends CustomPainter {
  const _ThreadPainter({required this.count, required this.current, required this.stopped});
  final int count;
  final int current;
  final bool stopped;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height - 11; // room above for the shuttle
    final col = size.width / count;
    double x(int i) => col * (i + 0.5);

    // bare warp across the whole way
    canvas.drawLine(Offset(x(0), cy), Offset(x(count - 1), cy), Paint()..color = SutraColors.rule..strokeWidth = 3..strokeCap = StrokeCap.round);

    if (!stopped && current > 0) {
      // woven part: sindoor with haldi crossings
      final done = Paint()..color = SutraColors.sindoor..strokeWidth = 5..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x(0), cy), Offset(x(current), cy), done);
      final cross = Paint()..color = SutraColors.haldi..strokeWidth = 1.6;
      for (var px = x(0) + 5; px < x(current) - 4; px += 7) {
        canvas.drawLine(Offset(px - 2, cy - 2.5), Offset(px + 2, cy + 2.5), cross);
      }
    }

    for (var i = 0; i < count; i++) {
      final reached = !stopped && i <= current;
      final c = Offset(x(i), cy);
      if (stopped && i == 1) {
        // the cut
        final cut = Paint()..color = SutraColors.kumkum..strokeWidth = 2;
        canvas.drawLine(c + const Offset(-5, -7), c + const Offset(5, 7), cut);
        canvas.drawLine(c + const Offset(5, -7), c + const Offset(-5, 7), cut);
        continue;
      }
      canvas.drawCircle(c, i == current && !stopped ? 8 : 6, Paint()..color = reached ? SutraColors.sindoor : SutraColors.card);
      canvas.drawCircle(c, i == current && !stopped ? 8 : 6, Paint()..color = reached ? SutraColors.sindoorDeep : SutraColors.inkSoft.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.6);
      if (i == current && !stopped) {
        // shuttle resting on the current knot
        final shuttle = Path()
          ..moveTo(c.dx - 11, c.dy - 11)
          ..quadraticBezierTo(c.dx, c.dy - 17, c.dx + 11, c.dy - 11)
          ..quadraticBezierTo(c.dx, c.dy - 8, c.dx - 11, c.dy - 11)
          ..close();
        canvas.drawPath(shuttle, Paint()..color = SutraColors.haldiDeep);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter old) => old.current != current || old.stopped != stopped || old.count != count;
}
