import 'package:flutter/material.dart';

import '../tokens.dart';

/// The woven stripe from the website header: sindoor · haldi · neel · haldi, repeated.
class ThreadStripe extends StatelessWidget {
  const ThreadStripe({super.key, this.height = 4, this.radius = 0});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(size: Size.fromHeight(height), painter: const _StripePainter()),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  static const _pattern = [(SutraColors.sindoor, 14.0), (SutraColors.haldi, 4.0), (SutraColors.neel, 12.0), (SutraColors.haldi, 4.0)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      final (color, width) = _pattern[i % _pattern.length];
      paint.color = color;
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      x += width;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
