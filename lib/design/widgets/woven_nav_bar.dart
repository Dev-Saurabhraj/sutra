import 'package:flutter/material.dart';

import '../tokens.dart';
import 'charkha_mic.dart';
import 'thread_stripe.dart';

class WovenNavItem {
  const WovenNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Bottom navigation as a woven strip. A loom shuttle slides to the active tab; the charkha sits in the middle.
/// [items] must have an even count: half go left of the charkha, half right.
class WovenNavBar extends StatelessWidget {
  const WovenNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onCharkha,
    required this.charkhaLabel,
    this.charkhaActive = false,
  });

  final List<WovenNavItem> items;
  final int? currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCharkha;
  final String charkhaLabel;
  final bool charkhaActive;

  @override
  Widget build(BuildContext context) {
    final half = items.length ~/ 2;
    final slots = items.length + 1; // + the charkha slot
    final activeSlot = currentIndex == null ? null : (currentIndex! < half ? currentIndex! : currentIndex! + 1);

    return Material(
      color: SutraColors.card,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThreadStripe(height: 3),
            SizedBox(
              height: 68,
              child: CustomPaint(
                painter: const _WeavePainter(),
                child: Stack(
                  children: [
                    if (activeSlot != null)
                      AnimatedAlign(
                        duration: SutraMotion.normal,
                        curve: SutraMotion.curve,
                        alignment: Alignment(-1 + 2 * activeSlot / (slots - 1), 1),
                        child: FractionallySizedBox(widthFactor: 1 / slots, child: const _Shuttle()),
                      ),
                    Row(
                      children: [
                        for (var i = 0; i < half; i++) _tab(context, i),
                        Expanded(
                          child: Center(
                            child: CharkhaMic(listening: false, selected: charkhaActive, onTap: onCharkha, size: 54, semanticLabel: charkhaLabel),
                          ),
                        ),
                        for (var i = half; i < items.length; i++) _tab(context, i),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i) {
    final active = i == currentIndex;
    final color = active ? SutraColors.sindoor : SutraColors.inkSoft;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(i),
        child: Semantics(
          selected: active,
          button: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[i].icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(items[i].label, style: TextStyle(color: color, fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// A loom shuttle: a pointed boat shape carrying a little haldi bobbin.
class _Shuttle extends StatelessWidget {
  const _Shuttle();

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 3), child: CustomPaint(size: const Size(40, 7), painter: _ShuttlePainter()));
}

class _ShuttlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const w = 34.0;
    final h = size.height;
    final body = Path()
      ..moveTo(cx - w / 2, h / 2)
      ..quadraticBezierTo(cx, -h * 0.4, cx + w / 2, h / 2)
      ..quadraticBezierTo(cx, h * 1.4, cx - w / 2, h / 2)
      ..close();
    canvas.drawPath(body, Paint()..color = SutraColors.sindoor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, h / 2), width: 10, height: 3), const Radius.circular(2)),
      Paint()..color = SutraColors.haldi,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Very faint warp-and-weft texture behind the nav.
class _WeavePainter extends CustomPainter {
  const _WeavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = SutraColors.rule.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    p.color = SutraColors.haldi.withValues(alpha: 0.08);
    for (var y = 0.0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
