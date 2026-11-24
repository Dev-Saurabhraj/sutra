import 'package:flutter/material.dart';

import '../tokens.dart';

/// A page of the bahi-khata: faint ruled lines and a double red margin rule on the left.
class LedgerCard extends StatelessWidget {
  const LedgerCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(34, 14, 16, 14), this.ruled = true});

  final Widget child;
  final EdgeInsets padding;
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SutraColors.card,
        borderRadius: const BorderRadius.all(SutraRadius.md),
        border: Border.all(color: SutraColors.rule),
        boxShadow: const [BoxShadow(color: Color(0x0F7A4B2A), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(SutraRadius.md),
        child: CustomPaint(
          painter: _LedgerPainter(ruled: ruled),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _LedgerPainter extends CustomPainter {
  const _LedgerPainter({required this.ruled});

  final bool ruled;
  static const _lineGap = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (ruled) {
      final line = Paint()
        ..color = const Color(0xFF9DB7C9).withValues(alpha: 0.18)
        ..strokeWidth = 1;
      for (var y = _lineGap; y < size.height; y += _lineGap) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      }
    }
    final margin = Paint()
      ..color = SutraColors.marginRed.withValues(alpha: 0.75)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(20, 0), Offset(20, size.height), margin);
    canvas.drawLine(const Offset(24, 0), Offset(24, size.height), margin);
  }

  @override
  bool shouldRepaint(covariant _LedgerPainter oldDelegate) => oldDelegate.ruled != ruled;
}

/// One entry line inside a ledger page: label on the left, figure on the right, dotted leader between.
class LedgerLine extends StatelessWidget {
  const LedgerLine({super.key, required this.label, required this.value, this.sub, this.onTap});

  final String label;
  final Widget value;
  final String? sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.bodyMedium),
              if (sub != null) Text(sub!, style: text.bodySmall),
            ],
          ),
          const Expanded(child: _DottedLeader()),
          value,
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class _DottedLeader extends StatelessWidget {
  const _DottedLeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: CustomPaint(size: const Size.fromHeight(2), painter: _DotsPainter()),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = SutraColors.rule;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawCircle(Offset(x, 1), 1, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
