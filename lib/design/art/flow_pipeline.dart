import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

class FlowStation {
  const FlowStation({required this.icon, required this.label, required this.value, this.alert = false, this.enabled = true});

  final IconData icon;
  final String label;

  /// A short figure shown on the station, e.g. "3" or "82".
  final String value;

  /// Draw attention (e.g. raw material running low).
  final bool alert;

  /// Traders have no "making" station: it shows as a faded knot the thread passes through.
  final bool enabled;
}

/// The journey of goods as one thread: supplier → raw material → making → ready → client.
/// Beads travel along the thread so the direction is obvious without reading. Stations are tappable.
class FlowPipeline extends StatefulWidget {
  const FlowPipeline({super.key, required this.stations, this.selected, this.onTap, this.compact = false});

  final List<FlowStation> stations;
  final int? selected;
  final ValueChanged<int>? onTap;
  final bool compact;

  @override
  State<FlowPipeline> createState() => _FlowPipelineState();
}

class _FlowPipelineState extends State<FlowPipeline> with SingleTickerProviderStateMixin {
  late final AnimationController _beads = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _beads.stop();
    } else if (!_beads.isAnimating) {
      _beads.repeat();
    }
  }

  @override
  void dispose() {
    _beads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.compact ? 42.0 : 54.0;
    return SizedBox(
      height: widget.compact ? 86 : 104,
      child: LayoutBuilder(
        builder: (context, box) {
          final n = widget.stations.length;
          final step = box.maxWidth / n;
          final centers = [for (var i = 0; i < n; i++) Offset(step * (i + 0.5), node / 2 + 4)];
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _beads,
                  builder: (_, _) => CustomPaint(painter: _ThreadPainter(centers: centers, t: _beads.value, nodeRadius: node / 2)),
                ),
              ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: step * i,
                  width: step,
                  top: 4,
                  child: _StationView(
                    station: widget.stations[i],
                    size: node,
                    selected: widget.selected == i,
                    compact: widget.compact,
                    onTap: widget.onTap == null ? null : () => widget.onTap!(i),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StationView extends StatelessWidget {
  const _StationView({required this.station, required this.size, required this.selected, required this.compact, this.onTap});

  final FlowStation station;
  final double size;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = !station.enabled ? SutraColors.rule : (selected ? Colors.white : (station.alert ? SutraColors.kumkum : SutraColors.neel));
    final bg = !station.enabled ? SutraColors.paper : (selected ? SutraColors.sindoor : SutraColors.card);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${station.label} ${station.value}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: station.enabled ? onTap : null,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: SutraMotion.normal,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: station.alert && !selected ? SutraColors.kumkum : (selected ? SutraColors.sindoor : SutraColors.rule), width: 2),
                    boxShadow: selected ? [BoxShadow(color: SutraColors.sindoor.withValues(alpha: 0.3), blurRadius: 10)] : null,
                  ),
                  child: Icon(station.icon, color: ink, size: size * 0.46),
                ),
                if (station.enabled)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: station.alert ? SutraColors.kumkum : SutraColors.ink,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SutraColors.card, width: 1.5),
                      ),
                      child: Text(station.value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, height: 1.3)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              station.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 11.5 : 12.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? SutraColors.sindoor : SutraColors.ink, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// The connecting thread: a gentle wave between stations with beads flowing left to right.
class _ThreadPainter extends CustomPainter {
  const _ThreadPainter({required this.centers, required this.t, required this.nodeRadius});

  final List<Offset> centers;
  final double t;
  final double nodeRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final a = centers[i - 1];
      final b = centers[i];
      final mid = Offset((a.dx + b.dx) / 2, a.dy + (i.isEven ? -10 : 10));
      path.quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    }
    canvas.drawPath(path, Paint()
      ..color = SutraColors.haldi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);

    final metric = path.computeMetrics().first;
    const beads = 7;
    for (var i = 0; i < beads; i++) {
      final d = ((t + i / beads) % 1) * metric.length;
      final pos = metric.getTangentForOffset(d)!.position;
      final nearNode = centers.any((c) => (c - pos).distance < nodeRadius);
      if (nearNode) continue;
      final color = i.isEven ? SutraColors.sindoor : SutraColors.neel;
      canvas.drawCircle(pos, 3.6 + math.sin((t * 4 + i) * math.pi) * 0.6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter old) => old.t != t || old.centers != centers;
}
