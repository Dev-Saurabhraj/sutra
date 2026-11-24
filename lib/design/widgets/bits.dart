import 'package:flutter/material.dart';

import '../../core/format/formatters.dart';
import '../tokens.dart';
import '../typography.dart';

/// "#B4441F" → Color. Falls back to sindoor for anything unreadable.
Color hexColor(String hex) {
  final v = int.tryParse(hex.trim().replaceFirst('#', ''), radix: 16);
  return v == null ? SutraColors.sindoor : Color(0xFF000000 | v);
}

/// ₹ amount in ledger ink. Money coming in is neel, money going out is sindoor.
class AmountText extends StatelessWidget {
  const AmountText(this.amount, {super.key, this.size = 18, this.incoming});

  final num amount;
  final double size;
  final bool? incoming;

  @override
  Widget build(BuildContext context) {
    final color = switch (incoming) {
      true => SutraColors.neel,
      false => SutraColors.sindoor,
      null => SutraColors.ink,
    };
    return Text(Fmt.inr(amount), style: SutraType.figure(size, color: color));
  }
}

/// Section heading written like a question the user would ask, with an optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: SutraType.display(18))),
          ?action,
        ],
      ),
    );
  }
}

/// A round initials badge in the producer's own colour.
class InitialsBadge extends StatelessWidget {
  const InitialsBadge({super.key, required this.name, required this.color, this.size = 48});

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: SutraColors.haldi, width: 2.5),
      ),
      child: Text(Fmt.initials(name), style: SutraType.display(size * 0.36, color: Colors.white)),
    );
  }
}

/// A small "🔊 सुनें" chip that reads text aloud.
class ListenChip extends StatelessWidget {
  const ListenChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SutraColors.neelWash,
      borderRadius: const BorderRadius.all(SutraRadius.sm),
      child: InkWell(
        borderRadius: const BorderRadius.all(SutraRadius.sm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SutraSpace.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded, size: 18, color: SutraColors.neel),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: SutraColors.neel, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A woven swatch generated from a product's two dye colours (used until a photo is uploaded).
class WovenSwatch extends StatelessWidget {
  const WovenSwatch({super.key, required this.palette, this.size = 52});

  final String palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = palette.split(',').map(hexColor).toList();
    final a = colors.isNotEmpty ? colors.first : SutraColors.sindoor;
    final b = colors.length > 1 ? colors[1] : SutraColors.haldi;
    return ClipRRect(
      borderRadius: const BorderRadius.all(SutraRadius.sm),
      child: CustomPaint(size: Size.square(size), painter: _SwatchPainter(a, b)),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  const _SwatchPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final thin = Paint()..color = b.withValues(alpha: 0.18);
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), thin);
    }
    final border = Paint()..color = b.withValues(alpha: 0.9);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.74, size.width, size.height * 0.12), border);
    final dot = Paint()..color = b;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawCircle(Offset(size.width * (0.2 + c * 0.3 + (r.isOdd ? 0.15 : 0)), size.height * (0.15 + r * 0.2)), size.width * 0.04, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter old) => old.a != a || old.b != b;
}
