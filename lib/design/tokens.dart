import 'package:flutter/material.dart';

/// Colours from the website (thread/src/app/globals.css), named after what they are dyed with. See docs/DESIGN.md.
abstract final class SutraColors {
  static const sindoor = Color(0xFFB4441F);
  static const sindoorDeep = Color(0xFF8F3416);
  static const sindoorWash = Color(0xFFFBEDE7);
  static const neel = Color(0xFF0F766E);
  static const neelDeep = Color(0xFF0B5A54);
  static const neelWash = Color(0xFFE6F4F2);
  static const haldi = Color(0xFFE9C46A);
  static const haldiDeep = Color(0xFF9A6B12);
  static const haldiWash = Color(0xFFFBF3DE);
  static const ink = Color(0xFF1F2937);
  static const inkSoft = Color(0xFF6B7280);
  static const rule = Color(0xFFE7E2DC);
  static const paper = Color(0xFFFAF7F2);
  static const card = Color(0xFFFFFDF9);
  static const kumkum = Color(0xFFB91C1C);
  static const marginRed = Color(0xFFD9786A);
}

abstract final class SutraSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = EdgeInsets.fromLTRB(16, 12, 16, 24);
  static const maxWidth = 480.0;
  static const minTouch = 48.0;
}

abstract final class SutraRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(14);
  static const lg = Radius.circular(20);
}

abstract final class SutraMotion {
  static const quick = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;
}

/// Meaning → ink colour for stamps and amounts.
enum Tone {
  ok(SutraColors.neel),
  low(SutraColors.haldiDeep),
  critical(SutraColors.kumkum),
  due(SutraColors.sindoor),
  neutral(SutraColors.inkSoft);

  const Tone(this.ink);
  final Color ink;
}
