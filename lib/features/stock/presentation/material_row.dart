import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/widgets/spool_gauge.dart';
import '../../../design/widgets/stamp.dart';
import '../domain/stock_models.dart';

/// One raw material: its spool, how long it lasts, and a stamp.
class MaterialRow extends StatelessWidget {
  const MaterialRow({super.key, required this.material, required this.strings, this.onTap, this.trailing});

  final MaterialHealth material;
  final AppStrings strings;
  final VoidCallback? onTap;
  final Widget? trailing;

  String get _stampLabel => switch (material.status) {
        StockStatus.critical => strings.statusCritical,
        StockStatus.low => strings.statusLow,
        StockStatus.ok => strings.statusOk,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final m = material;
    final lasts = m.daysLeft == null ? strings.notInUse : strings.lastsDays(m.daysLeft!.round());
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SpoolGauge(fill: m.spoolFill, tone: m.status.tone),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.pick(m.nameHi, m.name), style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text('${Fmt.qty(m.stock)} ${m.unit} · $lasts', style: text.bodySmall),
                    if (m.reorderBy != null && m.status != StockStatus.ok)
                      Text(
                        strings.reorderBy(Fmt.shortDate(m.reorderBy!, hindi: strings.isHindi)),
                        style: text.bodySmall?.copyWith(color: m.status.tone.ink, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Stamp(_stampLabel, tone: m.status.tone),
            ],
          ),
        ),
      ),
    );
  }
}
