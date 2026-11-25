import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// One point on the production line: days from today, pieces ready by then.
typedef CurveSample = ({double day, double units});

/// "Can I deliver?" drawn as a thread being spun upward: the thread is pieces ready each day,
/// the dashed line on top is what the buyer asked for, the red post is the date they want it.
/// Where the thread crosses the post a knot is tied: that is what you can honestly promise.
class ProductionCurve extends StatefulWidget {
  const ProductionCurve({
    super.key,
    required this.samples,
    required this.target,
    required this.wantedDay,
    required this.promised,
    required this.wantedLabel,
    required this.targetLabel,
    this.height = 170,
  });

  final List<CurveSample> samples;
  final double target;
  final double wantedDay;
  final double promised;
  final String wantedLabel;
  final String targetLabel;
  final double height;

  @override
  State<ProductionCurve> createState() => _ProductionCurveState();
}

class _ProductionCurveState extends State<ProductionCurve> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _spin.value = 1;
    } else if (_spin.value == 0) {
      _spin.forward();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${widget.promised.round()} / ${widget.target.round()} · ${widget.wantedLabel}',
      child: SizedBox(
        height: widget.height,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _spin,
            builder: (_, _) => CustomPaint(
              size: Size.infinite,
              painter: ProductionCurvePainter(
                samples: widget.samples,
                target: widget.target,
                wantedDay: widget.wantedDay,
                promised: widget.promised,
                wantedLabel: widget.wantedLabel,
                targetLabel: widget.targetLabel,
                progress: Curves.easeOutCubic.transform(_spin.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductionCurvePainter extends CustomPainter {
  ProductionCurvePainter({
    required this.samples,
    required this.target,
    required this.wantedDay,
    required this.promised,
    required this.wantedLabel,
    required this.targetLabel,
    this.progress = 1,
  });

  final List<CurveSample> samples;
  final double target;
  final double wantedDay;
  final double promised;
  final String wantedLabel;
  final String targetLabel;
  final double progress;

  static const _pad = EdgeInsets.fromLTRB(6, 20, 8, 20);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2 || target <= 0) return;
    final plot = _pad.deflateRect(Offset.zero & size);
    final maxDay = math.max(samples.last.day, wantedDay * 1.15);
    final maxUnits = math.max(target * 1.12, samples.map((s) => s.units).reduce(math.max));
    Offset at(double day, double units) => Offset(plot.left + plot.width * (day / maxDay), plot.bottom - plot.height * (units / maxUnits));

    // warp threads: one faint vertical per week
    final warp = Paint()
      ..color = SutraColors.rule
      ..strokeWidth = 1;
    for (var d = 0.0; d <= maxDay; d += 7) {
      canvas.drawLine(at(d, 0), at(d, maxUnits), warp);
    }
    canvas.drawLine(at(0, 0), at(maxDay, 0), Paint()..color = SutraColors.inkSoft.withValues(alpha: 0.5)..strokeWidth = 1.2);

    // what the buyer asked for
    _dashed(canvas, at(0, target), at(maxDay, target), Paint()..color = SutraColors.haldiDeep..strokeWidth = 1.4);
    _label(canvas, targetLabel, at(0, target) + const Offset(2, -16), SutraColors.haldiDeep);

    // the date they want it: a red post
    final post = at(wantedDay, 0);
    _dashed(canvas, post, at(wantedDay, maxUnits), Paint()..color = SutraColors.sindoor..strokeWidth = 1.6, vertical: true);
    _label(canvas, wantedLabel, Offset(post.dx, plot.bottom + 3), SutraColors.sindoor, centre: true);

    // the thread, spun up to `progress`
    final path = Path()..moveTo(at(samples.first.day, samples.first.units).dx, at(samples.first.day, samples.first.units).dy);
    for (final s in samples.skip(1)) {
      final p = at(s.day, s.units);
      path.lineTo(p.dx, p.dy);
    }
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    final under = at(0, 0);
    final fill = Path.from(drawn)
      ..lineTo(metric.getTangentForOffset(metric.length * progress)!.position.dx, under.dy)
      ..lineTo(under.dx, under.dy)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, plot.top), Offset(0, plot.bottom), [SutraColors.neel.withValues(alpha: 0.16), SutraColors.neel.withValues(alpha: 0.02)]),
    );
    canvas.drawPath(drawn, Paint()..color = SutraColors.neelDeep..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    // twist highlights so it reads as yarn, not a chart line
    final twist = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var d = 4.0; d < metric.length * progress; d += 9) {
      final t = metric.getTangentForOffset(d)!;
      final n = Offset(-t.vector.dy, t.vector.dx) * 1.6;
      canvas.drawLine(t.position - n - t.vector * 1.5, t.position + n + t.vector * 1.5, twist);
    }

    if (progress < 0.98) return;
    // the knot: what can be ready on the wanted date
    final met = promised >= target;
    final knot = at(wantedDay, promised);
    canvas.drawCircle(knot, 8, Paint()..color = SutraColors.card);
    canvas.drawCircle(knot, 6.5, Paint()..color = met ? SutraColors.neel : SutraColors.sindoor);
    canvas.drawCircle(knot, 2.4, Paint()..color = SutraColors.card);
    _tag(canvas, '${promised.round()}', knot + const Offset(0, -14), met ? SutraColors.neelDeep : SutraColors.sindoorDeep);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint, {bool vertical = false}) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += 9) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
    }
  }

  /// A small paper tag centred above [bottomCentre], so the number never sits on the thread.
  void _tag(Canvas canvas, String text, Offset bottomCentre, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, height: 1.1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = Rect.fromCenter(center: bottomCentre - Offset(0, tp.height / 2 + 3), width: tp.width + 12, height: tp.height + 6);
    final r = RRect.fromRectAndRadius(box, const Radius.circular(5));
    canvas.drawRRect(r, Paint()..color = SutraColors.card);
    canvas.drawRRect(r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2);
    tp.paint(canvas, box.topLeft + const Offset(6, 3));
  }

  void _label(Canvas canvas, String text, Offset where, Color color, {bool centre = false, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, height: 1.2)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 160);
    tp.paint(canvas, centre ? where - Offset(tp.width / 2, 0) : where);
  }

  @override
  bool shouldRepaint(covariant ProductionCurvePainter old) =>
      old.progress != progress || old.samples != samples || old.target != target || old.promised != promised || old.wantedDay != wantedDay;
}
