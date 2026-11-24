import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/common_text.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/stamp.dart';

class MaterialPrices {
  const MaterialPrices({required this.name, required this.nameHi, required this.unit, required this.cost, required this.trendPct, required this.history, required this.suppliers});
  final String name;
  final String nameHi;
  final String unit;
  final double cost;
  final double? trendPct;
  final List<(DateTime, double)> history;
  final List<(String, double)> suppliers;

  factory MaterialPrices.fromJson(Map<String, dynamic> j) => MaterialPrices(
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        unit: j['unit'] as String,
        cost: (j['cost'] as num).toDouble(),
        trendPct: ((j['trend'] as Map<String, dynamic>?)?['pct'] as num?)?.toDouble(),
        history: [for (final h in (j['history'] as List).cast<Map<String, dynamic>>()) (DateTime.parse(h['date'] as String), (h['rate'] as num).toDouble())],
        suppliers: [for (final x in (j['suppliers'] as List).cast<Map<String, dynamic>>()) (x['supplier'] as String, (x['last'] as num).toDouble())],
      );
}

final pricesProvider = FutureProvider.autoDispose<List<MaterialPrices>>((ref) async {
  final j = await ref.watch(apiClientProvider).get('/prices');
  return [for (final m in (j['materials'] as List).cast<Map<String, dynamic>>()) MaterialPrices.fromJson(m)];
});

/// P25: what each material cost on every bill, the trend, and the cheapest supplier lately.
class PricesScreen extends ConsumerWidget {
  const PricesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(CommonText.prices))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<List<MaterialPrices>>(
              value: ref.watch(pricesProvider),
              strings: s,
              onRetry: () => ref.invalidate(pricesProvider),
              data: (list) => ListView(
                padding: SutraSpace.page,
                children: [
                  Text(s.tr(CommonText.pricesSub), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                  const SizedBox(height: 12),
                  for (final m in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: _MaterialCard(m: m, strings: s)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.m, required this.strings});
  final MaterialPrices m;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    final pct = m.trendPct;
    final (label, tone) = pct == null
        ? (s.tr(CommonText.noBills), Tone.neutral)
        : pct >= 5
            ? ('▲ ${Fmt.qty(pct)}%', Tone.critical)
            : pct > 0
                ? ('▲ ${Fmt.qty(pct)}%', Tone.low)
                : ('▼ ${Fmt.qty(pct.abs())}%', Tone.ok);
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.pick(m.nameHi, m.name), style: SutraType.display(17))),
              Stamp(label, tone: tone, size: 10, angle: 0),
            ],
          ),
          const SizedBox(height: 4),
          Text('${s.tr(CommonText.now)} ${Fmt.inr(m.cost)} ${s.tr(CommonText.per)} ${m.unit}', style: SutraType.figure(16)),
          if (m.history.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(height: 44, child: CustomPaint(size: Size.infinite, painter: _RatePainter([for (final h in m.history) h.$2]))),
          ],
          if (m.suppliers.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final (i, sup) in m.suppliers.indexed)
              LedgerLine(
                label: sup.$1,
                sub: i == 0 && m.suppliers.length > 1 ? s.tr(CommonText.cheapest) : null,
                value: Text(Fmt.inr(sup.$2), style: SutraType.figure(15, color: i == 0 ? SutraColors.neel : SutraColors.ink)),
                last: i == m.suppliers.length - 1,
              ),
          ],
          if (m.history.isEmpty) Text(s.tr(CommonText.noBills), style: text.bodySmall),
        ],
      ),
    );
  }
}

/// The rate over the last bills as a taut thread with a knot per bill; the last knot is red if it went up.
class _RatePainter extends CustomPainter {
  const _RatePainter(this.rates);
  final List<double> rates;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = rates.reduce((a, b) => a < b ? a : b);
    final hi = rates.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).abs() < 0.01 ? 1 : hi - lo;
    Offset at(int i) => Offset(6 + (size.width - 12) * i / (rates.length - 1), size.height - 6 - (size.height - 12) * (rates[i] - lo) / span);
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < rates.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, Paint()..color = SutraColors.neel..strokeWidth = 2.4..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < rates.length; i++) {
      final last = i == rates.length - 1;
      final up = last && rates[i] > rates[i - 1];
      canvas.drawCircle(at(i), last ? 4.5 : 3, Paint()..color = up ? SutraColors.kumkum : SutraColors.neelDeep);
    }
  }

  @override
  bool shouldRepaint(covariant _RatePainter old) => old.rates != rates;
}
