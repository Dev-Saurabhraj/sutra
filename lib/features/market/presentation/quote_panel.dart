import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/art/production_curve.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/stamp.dart';
import '../../../design/widgets/wax_seal.dart';
import '../../capacity/presentation/capacity_text.dart';
import '../data/market_repository.dart';
import '../domain/market_models.dart';
import 'market_text.dart';

const _defaultQty = 100;
const _defaultDays = 21;

/// B3 + B4 + B5 in one place: ask qty and date → the same answer the maker sees → request it,
/// from this maker or shared across the cluster, with a proforma from each.
class QuotePanel extends ConsumerStatefulWidget {
  const QuotePanel({super.key, required this.productId, required this.strings});
  final String productId;
  final AppStrings strings;

  @override
  ConsumerState<QuotePanel> createState() => _QuotePanelState();
}

class _QuotePanelState extends ConsumerState<QuotePanel> {
  int _qty = _defaultQty;
  DateTime _wanted = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: _defaultDays));
  final _note = TextEditingController();
  QuoteResult? _quote;
  bool _busy = false;

  AppStrings get s => widget.strings;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final q = await ref.read(marketRepositoryProvider).quote(productId: widget.productId, qty: _qty, wantedBy: _wanted);
      setState(() => _quote = q);
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request({required bool split}) async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(marketRepositoryProvider).request(productId: widget.productId, qty: _qty, wantedBy: _wanted, note: _note.text, split: split);
      ref.invalidate(buyerOrdersProvider);
      if (!mounted) return;
      await showSutraSheet<void>(context, _Requested(result: r, strings: s));
      if (mounted) context.go('/my-orders');
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final d = await showDatePicker(context: context, initialDate: _wanted, firstDate: now.add(const Duration(days: 1)), lastDate: now.add(const Duration(days: 365)));
    if (d == null) return;
    setState(() {
      _wanted = d;
      _quote = null;
    });
  }

  void _toast(Object e) {
    final err = ApiException.from(e);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NumberField(
                label: s.tr(MarketText.qty),
                initial: _qty,
                decimals: false,
                onChanged: (v) => setState(() {
                  _qty = (v ?? 0).round();
                  _quote = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: s.tr(MarketText.wantedBy), suffixIcon: const Icon(Icons.event_outlined)),
                  child: Text('${Fmt.shortDate(_wanted, hindi: s.isHindi)} ${_wanted.year}', style: Theme.of(context).textTheme.bodyLarge),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size.fromHeight(50)),
          onPressed: _busy || _qty < 1 ? null : _check,
          icon: _busy && q == null
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : const Icon(Icons.query_stats_rounded),
          label: Text(s.tr(_busy && q == null ? MarketText.checking : MarketText.check)),
        ),
        if (q != null) ...[
          const SizedBox(height: 14),
          _Answer(quote: q, strings: s),
          if (q.split != null) ...[const SizedBox(height: 12), _SplitCard(split: q.split!, strings: s)],
          if (q.sale.allowed) ...[
            const SizedBox(height: 12),
            TextField(controller: _note, minLines: 2, maxLines: 4, maxLength: 1000, decoration: InputDecoration(labelText: s.tr(MarketText.note), counterText: '')),
            const SizedBox(height: 12),
            if (q.split != null)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SutraColors.sindoor, minimumSize: const Size.fromHeight(52)),
                onPressed: _busy ? null : () => _request(split: true),
                child: Text('${s.tr(MarketText.requestSplit)} · ${q.split!.covered}/${q.qty}'),
              ),
            const SizedBox(height: 8),
            // with a cluster option the single-maker request becomes the secondary choice
            if (q.split != null)
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _busy ? null : () => _request(split: false),
                child: Text(s.tr(MarketText.requestOne)),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: SutraColors.sindoor, minimumSize: const Size.fromHeight(52)),
                onPressed: _busy ? null : () => _request(split: false),
                child: Text(s.tr(MarketText.requestOne)),
              ),
          ],
        ],
      ],
    );
  }
}

/// The honest answer: verdict, the production thread, two numbers, days off counted, and the money.
class _Answer extends StatelessWidget {
  const _Answer({required this.quote, required this.strings});
  final QuoteResult quote;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final p = quote.plan;
    final sale = quote.sale;
    final text = Theme.of(context).textTheme;
    final hindi = s.isHindi;
    final (verdict, tone) = p.canMeet
        ? (s.tr(MarketText.allInTime), Tone.ok)
        : p.qtyByWanted > 0
            ? (s.tr(MarketText.partInTime), Tone.low)
            : (s.tr(MarketText.notInTime), Tone.critical);
    final start = p.curve.isEmpty ? DateTime.now() : p.curve.first.date;
    double dayOf(DateTime d) => d.difference(start).inHours / 24;
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.tr(MarketText.answer), style: SutraType.display(17))),
              Stamp(verdict, tone: tone, thunk: true),
            ],
          ),
          if (p.curve.length > 1) ...[
            const SizedBox(height: 8),
            ProductionCurve(
              samples: [for (final c in p.curve) (day: dayOf(c.date), units: c.units)],
              target: p.qty.toDouble(),
              wantedDay: dayOf(p.wantedBy),
              promised: p.qtyByWanted.toDouble(),
              wantedLabel: Fmt.shortDate(p.wantedBy, hindi: hindi),
              targetLabel: '${p.qty} ${s.tr(MarketText.pieces)}',
              height: 150,
            ),
          ],
          LedgerLine(
            label: s.tr(MarketText.byYourDate),
            sub: Fmt.shortDate(p.wantedBy, hindi: hindi),
            value: Text('${p.qtyByWanted} / ${p.qty}', style: SutraType.figure(18, color: p.canMeet ? SutraColors.neel : SutraColors.sindoorDeep)),
          ),
          LedgerLine(label: s.tr(MarketText.allBy), value: Text(Fmt.shortDate(p.fullDate, hindi: hindi), style: SutraType.figure(16))),
          if (p.counted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.tr(MarketText.countedDaysOff), style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final e in p.counted) DaysOffChip(event: e, strings: s)]),
                ],
              ),
            ),
          Text(s.tr(MarketText.sameEngine), style: text.labelSmall?.copyWith(color: SutraColors.inkSoft)),
          const SizedBox(height: 6),
          if (!sale.allowed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${s.tr(MarketText.cannotSell)}. ${sale.reason ?? ''}', style: text.bodyMedium?.copyWith(color: SutraColors.kumkum)),
            )
          else ...[
            LedgerLine(label: '${quote.qty} × ${Fmt.inr(quote.product.price)}', value: AmountText(sale.taxable, size: 16)),
            LedgerLine(
              label: sale.document == 'BILL_OF_SUPPLY' ? s.tr(MarketText.noGst) : (sale.interState ? s.tr(MarketText.igst) : s.tr(MarketText.cgstSgst)),
              value: AmountText(sale.tax, size: 16),
            ),
            LedgerLine(label: s.tr(MarketText.total), value: AmountText(sale.total, size: 20, incoming: true), last: sale.warning == null),
            if (sale.warning != null)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(sale.warning!, style: text.bodySmall?.copyWith(color: SutraColors.haldiDeep))),
          ],
        ],
      ),
    );
  }
}

/// B4: who makes how many, so the whole order arrives by the date.
class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.split, required this.strings});
  final SplitOption split;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SutraColors.haldiWash,
        borderRadius: const BorderRadius.all(SutraRadius.md),
        border: Border.all(color: SutraColors.haldi),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.tr(MarketText.clusterTitle), style: SutraType.display(17))),
              Stamp('${split.covered}/${split.qty}', tone: split.canMeet ? Tone.ok : Tone.low, angle: 0),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.tr(MarketText.clusterSub), style: text.bodySmall),
          const SizedBox(height: 10),
          _SplitBar(rows: split.rows, qty: split.qty),
          const SizedBox(height: 8),
          for (final (i, r) in split.rows.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _splitColor(i), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  InitialsBadge(name: r.maker.name, color: hexColor(r.maker.avatarColor), size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.maker.businessName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${(r.maker.onTimeRate * 100).round()}% ${s.tr(MarketText.onTime)} · ${Fmt.inr(r.product.price)}', style: text.bodySmall),
                      ],
                    ),
                  ),
                  if (r.maker.gstinFormatOk) const Padding(padding: EdgeInsets.only(right: 8), child: WaxSeal(size: 20)),
                  Text('${r.assigned} ${s.tr(MarketText.pieces)}', style: SutraType.figure(16)),
                ],
              ),
            ),
          const Divider(color: SutraColors.haldi),
          Row(
            children: [
              Expanded(child: Text('${split.covered} ${s.tr(MarketText.pieces)} ${s.tr(MarketText.covered)}', style: text.titleSmall)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [AmountText(split.value, size: 18), Text(s.tr(MarketText.beforeGst), style: text.labelSmall)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _splitColor(int i) => const [SutraColors.sindoor, SutraColors.neel, SutraColors.haldiDeep, Color(0xFF9D174D)][i % 4];

/// The order as one woven strip, each maker's share in their own dye; the bare part is what no one can make in time.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.rows, required this.qty});
  final List<SplitRow> rows;
  final int qty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            for (final (i, r) in rows.indexed) Expanded(flex: r.assigned, child: Container(color: _splitColor(i))),
            if (rows.fold(0, (a, r) => a + r.assigned) < qty)
              Expanded(flex: qty - rows.fold(0, (a, r) => a + r.assigned), child: Container(color: SutraColors.rule)),
          ],
        ),
      ),
    );
  }
}

class _Requested extends ConsumerWidget {
  const _Requested({required this.result, required this.strings});
  final RequestResult result;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(kicker: result.group, title: s.tr(MarketText.requested), subtitle: s.tr(MarketText.requestedSub)),
        for (final (i, o) in result.orders.indexed)
          LedgerLine(
            label: '${o.maker} · ${o.qty} ${s.tr(MarketText.pieces)}',
            sub: '${o.code} · ${s.tr(MarketText.proforma)} ${o.proformaNumber}',
            value: AmountText(o.total, size: 16),
            last: i == result.orders.length - 1,
            onTap: () async {
              final bytes = await ref.read(marketRepositoryProvider).invoicePdf(o.proformaId);
              await Printing.sharePdf(bytes: bytes, filename: '${o.proformaNumber.replaceAll('/', '-')}.pdf');
            },
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text(s.tr(MarketText.total), style: Theme.of(context).textTheme.titleSmall)),
            AmountText(result.total, size: 20, incoming: true),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.tr(MarketText.seeOrders))),
      ],
    );
  }
}
