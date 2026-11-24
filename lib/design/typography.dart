import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Fraunces for ledger-ink headings and numbers, Inter for UI, Noto Sans Devanagari for Hindi.
abstract final class SutraType {
  static List<String> get _devanagari => [GoogleFonts.notoSansDevanagari().fontFamily!];

  static TextStyle display(double size, {Color color = SutraColors.ink, FontWeight weight = FontWeight.w700}) =>
      // 1.3 + even leading: Devanagari matras (ि ी ँ) sit above the Latin cap height and were clipped at 1.15.
      GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color, height: 1.3)
          .copyWith(fontFamilyFallback: _devanagari, leadingDistribution: TextLeadingDistribution.even);

  /// Tabular numbers so amounts line up like a ledger column.
  static TextStyle figure(double size, {Color color = SutraColors.ink}) => display(size, color: color, weight: FontWeight.w600)
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  static TextTheme textTheme() {
    final base = GoogleFonts.interTextTheme().apply(bodyColor: SutraColors.ink, displayColor: SutraColors.ink);
    TextStyle? withHindi(TextStyle? s) =>
        s?.copyWith(fontFamilyFallback: _devanagari, height: 1.4, leadingDistribution: TextLeadingDistribution.even);
    return base.copyWith(
      headlineLarge: display(30),
      headlineMedium: display(24),
      headlineSmall: display(20),
      titleLarge: withHindi(base.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
      titleMedium: withHindi(base.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
      titleSmall: withHindi(base.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      bodyLarge: withHindi(base.bodyLarge?.copyWith(fontSize: 16)),
      bodyMedium: withHindi(base.bodyMedium?.copyWith(fontSize: 14.5)),
      bodySmall: withHindi(base.bodySmall?.copyWith(fontSize: 12.5, color: SutraColors.inkSoft)),
      labelLarge: withHindi(base.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
      labelMedium: withHindi(base.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      labelSmall: withHindi(base.labelSmall?.copyWith(letterSpacing: 0.6, color: SutraColors.inkSoft)),
    );
  }
}
