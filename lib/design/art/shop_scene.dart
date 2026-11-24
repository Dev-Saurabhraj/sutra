import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'animated_art.dart';

/// A small boutique: striped awning, folded cloth on the shelf, and a saree on a hanger that sways in the breeze.
/// The buyer's side of the thread (the maker's side has the loom).
class ShopArt extends StatelessWidget {
  const ShopArt({super.key, this.semanticLabel});
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) =>
      AnimatedArt(painter: (t) => ShopPainter(t), period: const Duration(milliseconds: 3200), still: 0.25, semanticLabel: semanticLabel);
}

class ShopPainter extends CustomPainter {
  const ShopPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    // wall and floor
    canvas.drawRRect(RRect.fromLTRBR(12, 26, 88, 92, const Radius.circular(3)), Paint()..color = const Color(0xFFF6E7D3));
    canvas.drawRect(const Rect.fromLTRB(8, 90, 92, 94), Paint()..color = const Color(0xFF8A5A33));

    // awning: alternating sindoor / haldi scallops
    for (var i = 0; i < 8; i++) {
      final x = 8 + i * 10.5;
      final c = i.isEven ? SutraColors.sindoor : SutraColors.haldi;
      canvas.drawRect(Rect.fromLTWH(x, 16, 10.5, 10), Paint()..color = c);
      canvas.drawArc(Rect.fromLTWH(x, 21, 10.5, 10), 0, math.pi, true, Paint()..color = c);
    }
    canvas.drawRect(const Rect.fromLTRB(8, 14, 92, 17), Paint()..color = SutraColors.sindoorDeep);

    // shelf with folded cloth stacks
    final shelf = Paint()..color = const Color(0xFF8A5A33);
    canvas.drawRect(const Rect.fromLTRB(52, 62, 84, 64), shelf);
    const folds = [SutraColors.neel, SutraColors.sindoor, SutraColors.haldi, Color(0xFF9D174D)];
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(RRect.fromLTRBR(54, 56.0 - i * 4.2, 70, 60.0 - i * 4.2, const Radius.circular(1.2)), Paint()..color = folds[i]);
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(RRect.fromLTRBR(71, 56.0 - i * 4.2, 83, 60.0 - i * 4.2, const Radius.circular(1.2)), Paint()..color = folds[(i + 2) % 4]);
    }
    // counter
    canvas.drawRRect(RRect.fromLTRBR(50, 74, 88, 90, const Radius.circular(2)), Paint()..color = const Color(0xFFB07A4B));
    canvas.drawRect(const Rect.fromLTRB(50, 74, 88, 77), Paint()..color = const Color(0xFF8A5A33));

    // the swaying saree on a hanger
    final sway = math.sin(t * 2 * math.pi) * 0.09;
    canvas.save();
    canvas.translate(30, 34);
    canvas.rotate(sway);
    final hook = Paint()
      ..color = SutraColors.inkSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(const Rect.fromLTWH(-3, -6, 6, 6), math.pi, math.pi * 1.4, false, hook);
    canvas.drawLine(const Offset(-11, 4), const Offset(0, 0), hook);
    canvas.drawLine(const Offset(11, 4), const Offset(0, 0), hook);
    final cloth = Path()
      ..moveTo(-11, 4)
      ..lineTo(11, 4)
      ..quadraticBezierTo(13 + sway * 30, 30, 9, 50)
      ..lineTo(-9, 50)
      ..quadraticBezierTo(-13 + sway * 30, 30, -11, 4)
      ..close();
    canvas.drawPath(cloth, Paint()..color = SutraColors.neel);
    // zari border and butis
    canvas.drawRect(const Rect.fromLTRB(-9, 44, 9, 50), Paint()..color = SutraColors.haldi);
    final buti = Paint()..color = SutraColors.haldi;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawCircle(Offset(-6 + c * 6.0 + (r.isOdd ? 3 : 0), 12 + r * 10.0), 1.1, buti);
      }
    }
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ShopPainter old) => old.t != t;
}
