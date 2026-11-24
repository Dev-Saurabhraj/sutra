import 'package:flutter/material.dart';

import '../tokens.dart';

/// A page of the bahi-khata: paper, a double red margin rule on the left.
/// Ruled lines are drawn by each [LedgerLine] under its own row, so text always sits on its line
/// (a fixed background grid cut through rows of different heights).
class LedgerCard extends StatelessWidget {
  const LedgerCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(36, 6, 16, 6)});

  final Widget child;
  final EdgeInsets padding;

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
          painter: const _MarginPainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _MarginPainter extends CustomPainter {
  const _MarginPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final margin = Paint()
      ..color = SutraColors.marginRed.withValues(alpha: 0.75)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(20, 0), Offset(20, size.height), margin);
    canvas.drawLine(const Offset(24, 0), Offset(24, size.height), margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One entry in a ledger page: label (and optional sub-line) on the left, figure on the right,
/// a dotted leader between them, and the page's ruled line underneath.
class LedgerLine extends StatelessWidget {
  const LedgerLine({super.key, required this.label, required this.value, this.sub, this.onTap, this.last = false});

  final String label;
  final Widget value;
  final String? sub;
  final VoidCallback? onTap;

  /// The last row on a page has no rule under it.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x339DB7C9)))),
      child: Row(
        children: [
          Flexible(
            flex: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodyMedium),
                if (sub != null) Text(sub!, style: text.bodySmall),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
