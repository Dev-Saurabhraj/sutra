import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../data/stock_repository.dart';
import '../domain/stock_models.dart';
import 'material_row.dart';
import 'reorder_sheet.dart';

/// "क्या कम है?" — raw material spools with reorder, and finished goods.
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => _finished ? ref.refresh(productsProvider.future) : ref.refresh(materialsProvider.future),
          child: ListView(
            padding: SutraSpace.page,
            children: [
              Text(s.stockTitle, style: SutraType.display(28)),
              const SizedBox(height: 14),
              _WovenTabs(
                labels: [s.rawTab, s.finishedTab],
                index: _finished ? 1 : 0,
                onChanged: (i) => setState(() => _finished = i == 1),
              ),
              const SizedBox(height: 14),
              if (_finished) _ProductsList(strings: s) else _MaterialsList(strings: s),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialsList extends ConsumerWidget {
  const _MaterialsList({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<List<MaterialHealth>>(
      value: ref.watch(materialsProvider),
      strings: strings,
      onRetry: () => ref.invalidate(materialsProvider),
      data: (materials) => LedgerCard(
        ruled: false,
        padding: const EdgeInsets.fromLTRB(34, 4, 12, 4),
        child: Column(
          children: [
            for (final (i, m) in materials.indexed) ...[
              if (i > 0) const Divider(),
              MaterialRow(
                material: m,
                strings: strings,
                onTap: m.supplierName == null ? null : () => showReorderSheet(context, m),
                trailing: m.status == StockStatus.ok || m.supplierName == null
                    ? null
                    : FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                        onPressed: () => showReorderSheet(context, m),
                        child: Text(strings.reorder),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductsList extends ConsumerWidget {
  const _ProductsList({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return AsyncView<List<ProductStock>>(
      value: ref.watch(productsProvider),
      strings: strings,
      onRetry: () => ref.invalidate(productsProvider),
      data: (products) => LedgerCard(
        ruled: false,
        padding: const EdgeInsets.fromLTRB(34, 4, 12, 4),
        child: Column(
          children: [
            for (final (i, p) in products.indexed) ...[
              if (i > 0) const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    WovenSwatch(palette: p.palette, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.pick(p.nameHi, p.name), style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text('${Fmt.inr(p.price)} · ${strings.wholesale}', style: text.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p.stock}', style: SutraType.figure(22, color: p.stock == 0 ? SutraColors.kumkum : SutraColors.ink)),
                        Text(strings.ready, style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Two tabs drawn as a woven selvedge: the active one is sindoor thread, the other a plain warp.
class _WovenTabs extends StatelessWidget {
  const _WovenTabs({required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, label) in labels.indexed)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                        color: i == index ? SutraColors.sindoor : SutraColors.inkSoft,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: SutraMotion.normal,
                      height: i == index ? 4 : 1.5,
                      decoration: BoxDecoration(
                        color: i == index ? SutraColors.sindoor : SutraColors.rule,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
