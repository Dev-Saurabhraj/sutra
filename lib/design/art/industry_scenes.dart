import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'animated_art.dart';

/// The animated scene for an industry: a loom weaving, a diya flickering, a potter's wheel turning…
/// Used on the home hero, onboarding and empty states. Unknown industries get the workbench.
class IndustryArt extends StatelessWidget {
  const IndustryArt(this.industryKey, {super.key, this.semanticLabel});

  final String industryKey;
  final String? semanticLabel;

  static const keys = ['handloom', 'brass', 'pottery', 'toys', 'food', 'machining', 'other'];

  @override
  Widget build(BuildContext context) {
    final (ArtPainter painter, Duration period) = switch (industryKey) {
      'handloom' => ((t) => LoomPainter(t), const Duration(milliseconds: 2400)),
      'brass' => ((t) => DiyaPainter(t), const Duration(milliseconds: 1800)),
      'pottery' => ((t) => PotteryWheelPainter(t), const Duration(milliseconds: 1600)),
      'toys' => ((t) => SpinningTopPainter(t), const Duration(milliseconds: 900)),
      'food' => ((t) => PickleJarPainter(t), const Duration(milliseconds: 3200)),
      'machining' => ((t) => GearsPainter(t), const Duration(milliseconds: 4000)),
      _ => ((t) => WorkbenchPainter(t), const Duration(milliseconds: 1400)),
    };
    return AnimatedArt(painter: painter, period: period, semanticLabel: semanticLabel);
  }
}

/// Shared helpers: every scene is drawn in a 100×100 box scaled to fit.
abstract class _Scene extends CustomPainter {
  const _Scene(this.t);
  final double t;

  void draw(Canvas c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas
      ..save()
      ..translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2)
      ..scale(s);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Scene old) => old.t != t;

  Paint fill(Color c) => Paint()..color = c;
  Paint stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;
  double wave([double phase = 0]) => math.sin((t + phase) * 2 * math.pi);
}

// ---------------------------------------------------------------- handloom

/// A pit loom: warp threads run down, the shuttle flies across, woven rows of cloth grow below.
class LoomPainter extends _Scene {
  const LoomPainter(super.t);

  @override
  void draw(Canvas c) {
    final wood = fill(const Color(0xFF9C6B3F));
    c.drawRRect(RRect.fromLTRBR(10, 14, 90, 19, const Radius.circular(2)), wood); // top beam
    c.drawRect(const Rect.fromLTRB(10, 14, 14, 92), wood);
    c.drawRect(const Rect.fromLTRB(86, 14, 90, 92), wood);

    // warp: alternating threads lift a little to open the shed
    for (var i = 0; i < 17; i++) {
      final x = 18 + i * 4.0;
      final lift = (i.isEven ? 1 : -1) * wave() * 1.5;
      c.drawLine(Offset(x, 19), Offset(x, 52 + lift), stroke(i % 4 == 0 ? SutraColors.haldi : const Color(0xFFE8DCC8), 1.1));
      c.drawLine(Offset(x, 52 + lift), Offset(x, 60), stroke(const Color(0xFFE8DCC8), 1.1));
    }

    // woven cloth: weft rows scroll down slowly so it looks like cloth is being made
    final scroll = (t * 4) % 4;
    c.save();
    c.clipRect(const Rect.fromLTRB(16, 60, 84, 90));
    for (var r = -1; r < 9; r++) {
      final y = 60 + r * 4 + scroll;
      final color = r % 3 == 0 ? SutraColors.neel : SutraColors.sindoor;
      c.drawRect(Rect.fromLTRB(16, y, 84, y + 3.2), fill(color));
      if (r % 3 == 1) {
        for (var k = 0; k < 6; k++) {
          c.drawCircle(Offset(22 + k * 11 + (r.isOdd ? 5 : 0), y + 1.6), 1.2, fill(SutraColors.haldi));
        }
      }
    }
    c.restore();
    c.drawRect(const Rect.fromLTRB(16, 88, 84, 92), fill(const Color(0xFF7A512D))); // cloth beam

    // beater (reed) swings a little; the shuttle flies across the shed
    final beat = 58 + wave(0.25) * 1.2;
    c.drawRRect(RRect.fromLTRBR(15, beat - 1.5, 85, beat + 1.5, const Radius.circular(1.5)), fill(const Color(0xFF6B4423)));
    final x = 50 + 30 * math.sin(t * 2 * math.pi);
    final dir = math.cos(t * 2 * math.pi) >= 0 ? 1.0 : -1.0;
    final shuttle = Path()
      ..moveTo(x - 9 * dir, 54)
      ..quadraticBezierTo(x, 50.5, x + 9 * dir, 54)
      ..quadraticBezierTo(x, 57.5, x - 9 * dir, 54)
      ..close();
    c.drawPath(shuttle, fill(SutraColors.sindoorDeep));
    c.drawLine(Offset(x - 3, 54), Offset(x + 3, 54), stroke(SutraColors.haldi, 1.6));
    // the weft thread trailing behind the shuttle
    c.drawLine(Offset(dir > 0 ? 16 : 84, 56), Offset(x, 54.5), stroke(SutraColors.haldi.withValues(alpha: 0.8), 0.8));
  }
}

// ---------------------------------------------------------------- brass

/// A brass diya: the flame flickers, the glow breathes, sparks drift up.
class DiyaPainter extends _Scene {
  const DiyaPainter(super.t);

  @override
  void draw(Canvas c) {
    final glow = 0.55 + 0.15 * wave();
    c.drawCircle(const Offset(50, 46), 34, Paint()
      ..shader = RadialGradient(colors: [SutraColors.haldi.withValues(alpha: glow * 0.55), Colors.transparent])
          .createShader(Rect.fromCircle(center: const Offset(50, 46), radius: 34)));

    // flame: a teardrop that sways and stretches
    final sway = wave() * 2.2 + math.sin(t * 6 * math.pi) * 0.8;
    final h = 24 + math.sin(t * 4 * math.pi) * 2.5;
    final flame = Path()
      ..moveTo(50, 62)
      ..cubicTo(40, 56, 44 + sway, 50, 50 + sway * 1.3, 62 - h)
      ..cubicTo(56 + sway, 50, 60, 56, 50, 62)
      ..close();
    c.drawPath(flame, Paint()
      ..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFF7A1A), Color(0xFFFFD25A), Color(0xFFFFF4C2)])
          .createShader(const Rect.fromLTRB(38, 34, 62, 64)));
    c.drawOval(Rect.fromCenter(center: Offset(50 + sway * 0.4, 57), width: 4, height: 7), fill(const Color(0xFFFFFFFF).withValues(alpha: 0.7)));

    // the diya bowl, polished brass
    final bowl = Path()
      ..moveTo(26, 64)
      ..quadraticBezierTo(50, 58, 74, 64)
      ..quadraticBezierTo(70, 80, 50, 82)
      ..quadraticBezierTo(30, 80, 26, 64)
      ..close();
    c.drawPath(bowl, Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF9A6B12), Color(0xFFE9C46A), Color(0xFFB8862B)])
          .createShader(const Rect.fromLTRB(26, 58, 74, 82)));
    c.drawPath(Path()
      ..moveTo(74, 64)
      ..quadraticBezierTo(84, 60, 86, 56), stroke(const Color(0xFFB8862B), 3)); // spout
    c.drawOval(const Rect.fromLTRB(40, 82, 60, 88), fill(const Color(0xFF9A6B12)));
    for (var i = 0; i < 5; i++) {
      c.drawCircle(Offset(34 + i * 8, 71), 1.2, fill(const Color(0xFF7A5210))); // engraved dots
    }

    // sparks drifting up
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      c.drawCircle(Offset(50 + math.sin((p + i) * 9) * 6, 36 - p * 22), 1.1 * (1 - p), fill(SutraColors.haldi.withValues(alpha: 1 - p)));
    }
  }
}

// ---------------------------------------------------------------- pottery

/// A potter's wheel: the disc spins (moving stripes), the pot's walls rise and settle.
class PotteryWheelPainter extends _Scene {
  const PotteryWheelPainter(super.t);

  @override
  void draw(Canvas c) {
    c.drawOval(const Rect.fromLTRB(14, 74, 86, 90), fill(const Color(0xFF6B4423)));
    c.drawOval(const Rect.fromLTRB(16, 72, 84, 86), fill(const Color(0xFF8B5E34)));
    // spinning marks on the wheel top
    for (var i = 0; i < 6; i++) {
      final a = (t + i / 6) * 2 * math.pi;
      final x = 50 + math.cos(a) * 30;
      if (math.sin(a) > 0) c.drawLine(Offset(x, 79 - 3), Offset(x, 79 + 3), stroke(const Color(0xFF5A3A1E), 1.4));
    }

    final rise = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 0.5).abs();
    final top = 40 - rise * 6;
    final pot = Path()
      ..moveTo(36, 78)
      ..cubicTo(26, 66, 30, 54, 40, top + 6)
      ..lineTo(42, top)
      ..lineTo(58, top)
      ..lineTo(60, top + 6)
      ..cubicTo(70, 54, 74, 66, 64, 78)
      ..close();
    c.drawPath(pot, Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF9C4A1E), Color(0xFFC96A36), Color(0xFF9C4A1E)])
          .createShader(const Rect.fromLTRB(28, 30, 72, 78)));
    c.drawOval(Rect.fromLTRB(41, top - 2, 59, top + 2), fill(const Color(0xFF6E2F10)));
    // throwing lines travel round the pot
    for (var i = 0; i < 4; i++) {
      final y = 50 + i * 7.0;
      final phase = (t * 3 + i * 0.3) % 1;
      final x = 36 + phase * 28;
      c.drawLine(Offset(x, y), Offset(x + 5, y), stroke(const Color(0xFFE79A6B).withValues(alpha: 0.7), 1.2));
    }
  }
}

// ---------------------------------------------------------------- toys

/// A lacquered lattu (spinning top) whirring with a gentle wobble.
class SpinningTopPainter extends _Scene {
  const SpinningTopPainter(super.t);

  @override
  void draw(Canvas c) {
    c.drawOval(const Rect.fromLTRB(36, 84, 64, 89), fill(const Color(0x22000000)));
    c.save();
    c.translate(50, 86);
    c.rotate(math.sin(t * 2 * math.pi) * 0.07);
    c.translate(-50, -86);
    final body = Path()
      ..moveTo(50, 86)
      ..lineTo(26, 52)
      ..quadraticBezierTo(50, 34, 74, 52)
      ..close();
    c.save();
    c.clipPath(body);
    const bands = [SutraColors.sindoor, SutraColors.haldi, SutraColors.neel, Color(0xFF6D28D9)];
    for (var i = -1; i < 9; i++) {
      final x = 20 + i * 8.0 + (t * 32) % 32;
      c.drawRect(Rect.fromLTWH(x, 30, 4, 60), fill(bands[(i + 4) % 4]));
    }
    c.restore();
    c.drawPath(body, stroke(const Color(0x33000000), 0.8));
    c.drawRRect(RRect.fromLTRBR(47, 32, 53, 46, const Radius.circular(2)), fill(const Color(0xFF7A512D))); // handle
    c.restore();
    for (var i = 0; i < 3; i++) {
      final a = (t + i / 3) * 2 * math.pi;
      c.drawArc(const Rect.fromLTRB(20, 44, 80, 70), a, 0.5, false, stroke(SutraColors.inkSoft.withValues(alpha: 0.35), 1));
    }
  }
}

// ---------------------------------------------------------------- food

/// A glass jar filling with pickle; mango pieces bob in the oil.
class PickleJarPainter extends _Scene {
  const PickleJarPainter(super.t);

  @override
  void draw(Canvas c) {
    const jar = Rect.fromLTRB(28, 26, 72, 88);
    final fillLevel = 0.35 + 0.45 * (0.5 - 0.5 * math.cos(t * 2 * math.pi));
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(jar, const Radius.circular(10)));
    final y = jar.bottom - jar.height * fillLevel;
    final surface = Path()..moveTo(jar.left, y);
    for (var x = jar.left; x <= jar.right; x += 2) {
      surface.lineTo(x, y + math.sin(x / 5 + t * 2 * math.pi) * 1.2);
    }
    surface
      ..lineTo(jar.right, jar.bottom)
      ..lineTo(jar.left, jar.bottom)
      ..close();
    c.drawPath(surface, fill(const Color(0xFFD9822B)));
    for (var i = 0; i < 6; i++) {
      final bob = math.sin((t + i / 6) * 2 * math.pi) * 1.5;
      final pos = Offset(34 + (i * 7) % 32, jar.bottom - 6 - (i * 9) % (jar.height * fillLevel - 6).clamp(6, 60) + bob);
      c.drawOval(Rect.fromCenter(center: pos, width: 7, height: 4.5), fill(const Color(0xFFF2C14E)));
    }
    c.restore();
    c.drawRRect(RRect.fromRectAndRadius(jar, const Radius.circular(10)), stroke(const Color(0x88FFFFFF), 2));
    c.drawRRect(RRect.fromRectAndRadius(jar, const Radius.circular(10)), stroke(const Color(0x339DB7C9), 1));
    c.drawRRect(RRect.fromLTRBR(30, 18, 70, 27, const Radius.circular(3)), fill(SutraColors.sindoor)); // lid
    c.drawLine(const Offset(36, 34), const Offset(36, 70), stroke(const Color(0x66FFFFFF), 2.5)); // shine
  }
}

// ---------------------------------------------------------------- machining

/// Two gears turning against each other.
class GearsPainter extends _Scene {
  const GearsPainter(super.t);

  void _gear(Canvas c, Offset center, double r, int teeth, double angle, Color color) {
    final path = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final a = angle + i * math.pi / teeth;
      final rr = i.isEven ? r : r * 0.82;
      final a2 = a + math.pi / teeth;
      final p1 = Offset(center.dx + math.cos(a) * rr, center.dy + math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy); // start on the rim, not at the canvas origin
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(center.dx + math.cos(a2) * rr, center.dy + math.sin(a2) * rr);
    }
    path.close();
    c.drawPath(path, fill(color));
    c.drawCircle(center, r * 0.32, fill(SutraColors.card));
    c.drawCircle(center, r * 0.14, fill(color));
  }

  @override
  void draw(Canvas c) {
    final a = t * 2 * math.pi;
    _gear(c, const Offset(40, 48), 24, 10, a, const Color(0xFF4B5563));
    _gear(c, const Offset(71, 66), 16, 7, -a * 10 / 7 + 0.2, SutraColors.neel);
    // a spark where the cutting tool touches
    final p = (t * 3) % 1;
    c.drawCircle(Offset(18 - p * 6, 78 + p * 6), 1.4 * (1 - p), fill(SutraColors.haldi));
  }
}

// ---------------------------------------------------------------- other

/// A hammer tapping on an anvil — for every other kind of workshop.
class WorkbenchPainter extends _Scene {
  const WorkbenchPainter(super.t);

  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromLTRBR(20, 70, 80, 78, const Radius.circular(2)), fill(const Color(0xFF4B5563)));
    c.drawRect(const Rect.fromLTRB(38, 78, 62, 90), fill(const Color(0xFF374151)));
    final swing = math.pow(math.sin(t * math.pi), 2).toDouble();
    c.save();
    c.translate(76, 40);
    c.rotate(-0.9 * swing);
    c.drawRRect(RRect.fromLTRBR(-40, -3, 0, 3, const Radius.circular(2)), fill(const Color(0xFF9C6B3F)));
    c.drawRRect(RRect.fromLTRBR(-48, -12, -36, 12, const Radius.circular(2)), fill(const Color(0xFF6B7280)));
    c.restore();
    if (swing < 0.15) {
      for (var i = 0; i < 4; i++) {
        final a = -math.pi / 2 + (i - 1.5) * 0.5;
        c.drawLine(Offset(34 + math.cos(a) * 6, 66 + math.sin(a) * 6), Offset(34 + math.cos(a) * 12, 66 + math.sin(a) * 12), stroke(SutraColors.haldi, 1.5));
      }
    }
  }
}
