import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/art/production_curve.dart';
import '../../../design/art/stage_thread.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/product_thumb.dart';
import '../../../design/widgets/stamp.dart';
import '../../gst/presentation/gst_text.dart';
import '../../home/data/home_repository.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';
import 'dispatch_sheet.dart';
import 'order_letters.dart';
import 'order_text.dart';
import 'orders_screen.dart';

/// One order, top to bottom in the order a maker decides: what is asked, can I make it in time,
/// is the price worth it, then talk to the buyer. The next step is always the button at the bottom.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final detail = ref.watch(orderControllerProvider(code));
    return Scaffold(
      appBar: AppBar(title: Text(code)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<OrderDetail>(
              value: detail,
              strings: s,
              onRetry: () => ref.invalidate(orderControllerProvider(code)),
              data: (d) => Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: SutraColors.sindoor,
                      onRefresh: () => ref.refresh(orderControllerProvider(code).future),
                      child: ListView(
                        padding: SutraSpace.page,
                        children: [
                          _Header(order: d.order, strings: s),
                          if (d.plan != null) ...[const SizedBox(height: 14), _PlanCard(plan: d.plan!, strings: s)],
                          if (d.price != null && d.order.stage.index <= OrderStage.making.index) ...[
                            const SizedBox(height: 14),
                            PriceFloorCard(price: d.price!, strings: s),
                          ],
                          if (d.order.dispatchedAt != null) ...[const SizedBox(height: 14), _DispatchCard(order: d.order, strings: s)],
                          if (d.invoices.isNotEmpty) ...[const SizedBox(height: 14), _Invoices(invoices: d.invoices, strings: s)],
                          SectionHeader(s.tr(OrderText.letters)),
                          OrderLetters(messages: d.messages, strings: s),
                          if (d.order.stage != OrderStage.declined) ...[const SizedBox(height: 10), LetterComposer(code: code, strings: s)],
                        ],
                      ),
                    ),
                  ),
                  if (d.actions.isNotEmpty) _ActionBar(detail: d, strings: s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order, required this.strings});
  final Order order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final o = order;
    final text = Theme.of(context).textTheme;
    final (stamp, tone) = stageStamp(s, o.stage);
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumb(palette: o.product.palette, imageUrl: o.product.imageUrl, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.party, style: SutraType.display(18), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(s.pick(o.product.nameHi, o.product.name), style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Stamp(stamp, tone: tone, size: 10),
            ],
          ),
          const SizedBox(height: 10),
          LedgerLine(label: '${o.qty} ${s.tr(OrderText.pieces)} × ${Fmt.inr(o.rate)}', value: AmountText(o.value, size: 20, incoming: true)),
          if (o.wantedBy != null)
            LedgerLine(
              label: s.tr(OrderText.wanted),
              value: Text(Fmt.shortDate(o.wantedBy!, hindi: s.isHindi), style: SutraType.figure(16, color: SutraColors.sindoorDeep)),
              last: true,
            ),
          const SizedBox(height: 12),
          StageThread(
            labels: [s.tr(OrderText.stageAsked), s.tr(OrderText.stageMaking), s.tr(OrderText.stageSent), s.tr(OrderText.stageReached)],
            current: o.stage.step,
            stopped: o.stage == OrderStage.declined,
          ),
        ],
      ),
    );
  }
}

/// "Can I deliver?" answered with a picture first, then three numbers, then what to order.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.strings});
  final DeliveryPlan plan;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final p = plan;
    final text = Theme.of(context).textTheme;
    final hindi = s.isHindi;
    final (verdict, tone) = p.canMeet
        ? (s.tr(OrderText.yesInTime), Tone.ok)
        : p.qtyByWanted > 0
            ? (s.tr(OrderText.partly), Tone.low)
            : (s.tr(OrderText.notInTime), Tone.critical);
    final start = p.curve.isEmpty ? DateTime.now() : p.curve.first.date;
    double dayOf(DateTime d) => d.difference(start).inHours / 24;
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.tr(OrderText.canDeliver), style: SutraType.display(17))),
              Stamp(verdict, tone: tone, thunk: true, size: 11),
            ],
          ),
          const SizedBox(height: 8),
          if (p.curve.length > 1)
            ProductionCurve(
              samples: [for (final c in p.curve) (day: dayOf(c.date), units: c.units)],
              target: p.qty.toDouble(),
              wantedDay: dayOf(p.wantedBy),
              promised: p.qtyByWanted.toDouble(),
              wantedLabel: Fmt.shortDate(p.wantedBy, hindi: hindi),
              targetLabel: '${p.qty} ${s.tr(OrderText.pieces)}',
            ),
          Text(s.tr(OrderText.curveNote), style: text.labelSmall?.copyWith(color: SutraColors.inkSoft)),
          const SizedBox(height: 6),
          LedgerLine(label: s.tr(OrderText.readyNow), value: Text('${p.ready}', style: SutraType.figure(16))),
          LedgerLine(label: s.tr(OrderText.perDay), value: Text(Fmt.qty(p.perDay), style: SutraType.figure(16))),
          LedgerLine(
            label: s.tr(OrderText.byWanted),
            sub: Fmt.shortDate(p.wantedBy, hindi: hindi),
            value: Text('${p.qtyByWanted} / ${p.qty}', style: SutraType.figure(16, color: p.canMeet ? SutraColors.neel : SutraColors.sindoorDeep)),
          ),
          LedgerLine(
            label: s.tr(OrderText.allBy),
            value: Text(Fmt.shortDate(p.fullDate, hindi: hindi), style: SutraType.figure(16)),
            last: p.shortfalls.isEmpty,
          ),
          if (p.shortfalls.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(s.tr(OrderText.orderMaterial), style: text.titleSmall),
            const SizedBox(height: 4),
            for (final f in p.shortfalls)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(f.late ? Icons.error_outline_rounded : Icons.local_shipping_outlined, size: 18, color: f.late ? SutraColors.kumkum : SutraColors.haldiDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('${Fmt.qty(f.needQty)} ${f.unit} ${s.pick(f.nameHi, f.name)}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                              if (f.orderBy != null)
                                Text(
                                  f.late ? s.tr(OrderText.late) : '${Fmt.shortDate(f.orderBy!, hindi: hindi)} ${s.tr(OrderText.orderBy)}',
                                  style: text.labelMedium?.copyWith(color: f.late ? SutraColors.kumkum : SutraColors.haldiDeep, fontWeight: FontWeight.w700),
                                ),
                            ],
                          ),
                          if (f.supplierName != null) Text(f.supplierName!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The price floor: what the buyer pays, split into materials, wages and what is left for you.
class PriceFloorCard extends StatelessWidget {
  const PriceFloorCard({super.key, required this.price, required this.strings, this.title});
  final PriceCheck price;
  final AppStrings strings;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final p = price;
    final (verdict, tone) = p.belowCost
        ? (s.tr(OrderText.loss), Tone.critical)
        : p.thin
            ? (s.tr(OrderText.thin), Tone.low)
            : (s.tr(OrderText.fair), Tone.ok);
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title ?? s.tr(OrderText.priceCheck), style: SutraType.display(17))),
              Stamp('$verdict ${Fmt.qty(p.pct)}%', tone: tone, size: 10),
            ],
          ),
          const SizedBox(height: 12),
          CostBar(materials: p.materials, labour: p.labour, rate: p.rate),
          const SizedBox(height: 8),
          LedgerLine(label: s.tr(OrderText.theyPay), sub: s.tr(OrderText.perPiece), value: AmountText(p.rate, size: 16)),
          LedgerLine(label: s.tr(OrderText.materials), value: AmountText(p.materials, size: 16, incoming: false)),
          LedgerLine(
            label: s.tr(OrderText.labour),
            sub: p.labourKnown ? null : s.tr(OrderText.noLabour),
            value: AmountText(p.labour, size: 16, incoming: false),
          ),
          LedgerLine(
            label: p.belowCost ? s.tr(OrderText.loss) : s.tr(OrderText.keep),
            value: Text(Fmt.inr(p.perUnit), style: SutraType.figure(18, color: p.belowCost ? SutraColors.kumkum : SutraColors.neel)),
            last: true,
          ),
        ],
      ),
    );
  }
}

/// A woven strip the width of the price: haldi for materials, neel for wages, sindoor for what you keep.
/// If cost is above the price, the strip overflows into a red stub.
class CostBar extends StatelessWidget {
  const CostBar({super.key, required this.materials, required this.labour, required this.rate});
  final double materials;
  final double labour;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 22, child: CustomPaint(size: Size.infinite, painter: _CostBarPainter(materials, labour, rate)));
  }
}

class _CostBarPainter extends CustomPainter {
  const _CostBarPainter(this.materials, this.labour, this.rate);
  final double materials;
  final double labour;
  final double rate;

  @override
  void paint(Canvas canvas, Size size) {
    final cost = materials + labour;
    final full = cost > rate ? cost : rate;
    if (full <= 0) return;
    final scale = size.width / full;
    final h = size.height;
    var x = 0.0;
    void seg(double w, Color c) {
      if (w <= 0) return;
      final r = Rect.fromLTWH(x, 0, w * scale, h);
      canvas.drawRect(r, Paint()..color = c);
      // weft lines so it reads as cloth
      final weft = Paint()..color = Colors.white.withValues(alpha: 0.22)..strokeWidth = 1;
      for (var px = r.left + 3; px < r.right; px += 5) {
        canvas.drawLine(Offset(px, 2), Offset(px, h - 2), weft);
      }
      x += w * scale;
    }

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)));
    seg(materials, SutraColors.haldi);
    seg(labour, SutraColors.neel);
    if (rate > cost) seg(rate - cost, SutraColors.sindoor);
    canvas.restore();
    if (cost > rate) {
      // where the price ends: a cut mark, the rest is loss
      final cut = rate * scale;
      canvas.drawLine(Offset(cut, -3), Offset(cut, h + 3), Paint()..color = SutraColors.kumkum..strokeWidth = 2.4);
    }
  }

  @override
  bool shouldRepaint(covariant _CostBarPainter old) => old.materials != materials || old.labour != labour || old.rate != rate;
}

class _DispatchCard extends ConsumerWidget {
  const _DispatchCard({required this.order, required this.strings});
  final Order order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final o = order;
    final via = [o.transporter, if (o.lrNumber != null) 'LR ${o.lrNumber}'].whereType<String>().join(' · ');
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.tr(OrderText.sentVia)} · ${Fmt.shortDate(o.dispatchedAt!, hindi: s.isHindi)}', style: Theme.of(context).textTheme.titleSmall),
                if (via.isNotEmpty) Text(via, style: Theme.of(context).textTheme.bodySmall),
                if (o.deliveredAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Stamp('${s.tr(OrderText.stageReached)} ${Fmt.shortDate(o.deliveredAt!, hindi: s.isHindi)}', tone: Tone.ok, size: 10),
                  ),
              ],
            ),
          ),
          if (o.hasDispatchPhoto)
            ref.watch(dispatchPhotoProvider(o.code)).maybeWhen(
                  data: (bytes) => GestureDetector(
                    onTap: () => showDialog<void>(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(bytes)))),
                    child: ClipRRect(borderRadius: const BorderRadius.all(SutraRadius.sm), child: Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover)),
                  ),
                  orElse: () => const SizedBox.square(dimension: 64),
                ),
        ],
      ),
    );
  }
}

class _Invoices extends StatelessWidget {
  const _Invoices({required this.invoices, required this.strings});
  final List<OrderInvoice> invoices;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return LedgerCard(
      child: Column(
        children: [
          for (final (i, inv) in invoices.indexed)
            LedgerLine(
              label: inv.number,
              sub: strings.tr(switch (inv.kind) { 'PROFORMA' => GstText.kindProforma, 'TAX' => GstText.kindTax, _ => GstText.kindBos }),
              value: AmountText(inv.total, size: 16),
              onTap: () => context.push('/invoice/${inv.id}'),
              last: i == invoices.length - 1,
            ),
        ],
      ),
    );
  }
}

/// The next step for this order, always in the same place.
class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.detail, required this.strings});
  final OrderDetail detail;
  final AppStrings strings;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  String get _code => widget.detail.order.code;

  /// Goods can leave only once they exist (the server checks too).
  bool get _madeEnough => widget.detail.order.product.stock >= widget.detail.order.qty;

  Future<void> _run(Future<void> Function(OrderController c) action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = widget.strings;
    setState(() => _busy = true);
    try {
      await action(ref.read(orderControllerProvider(_code).notifier));
      ref.invalidate(homeProvider);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final s = widget.strings;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.tr(OrderText.declineSure)),
        content: Text(s.tr(OrderText.declineNote)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: SutraColors.kumkum), onPressed: () => Navigator.pop(ctx, true), child: Text(s.tr(OrderText.decline))),
        ],
      ),
    );
    if (sure == true) await _run((c) => c.respond(accept: false), s.tr(OrderText.declined));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final a = widget.detail.actions;
    final meets = widget.detail.plan?.canMeet ?? true;
    final busy = _busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : null;
    return DecoratedBox(
      decoration: const BoxDecoration(color: SutraColors.card, border: Border(top: BorderSide(color: SutraColors.rule))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            if (a.contains(OrderAction.decline)) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: SutraColors.kumkum, minimumSize: const Size(0, 52)),
                onPressed: _busy ? null : _decline,
                child: Text(s.tr(OrderText.decline)),
              ),
              const SizedBox(width: 10),
            ],
            if (a.contains(OrderAction.accept))
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size(0, 52)),
                  onPressed: _busy ? null : () => _run((c) => c.respond(accept: true), s.tr(OrderText.accepted)),
                  child: busy ?? Text(s.tr(meets ? OrderText.accept : OrderText.acceptPartial)),
                ),
              ),
            if (a.contains(OrderAction.dispatch) && !_madeEnough) ...[
              Expanded(
                child: Text(
                  '${widget.detail.order.product.stock}/${widget.detail.order.qty} ${s.tr(OrderText.madeSoFar)}',
                  style: SutraType.figure(16, color: SutraColors.haldiDeep),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: () => context.go('/inventory'),
                icon: const Icon(Icons.add_task_rounded),
                label: Text(s.tr(OrderText.recordMade)),
              ),
            ],
            if (a.contains(OrderAction.dispatch) && _madeEnough)
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: SutraColors.sindoor, minimumSize: const Size(0, 52)),
                  icon: const Icon(Icons.local_shipping_outlined),
                  onPressed: _busy
                      ? null
                      : () async {
                          await showSutraSheet<void>(context, DispatchSheet(code: _code, order: widget.detail.order));
                          ref.invalidate(homeProvider);
                        },
                  label: Text(s.tr(OrderText.dispatch)),
                ),
              ),
            if (a.contains(OrderAction.deliver))
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size(0, 52)),
                  icon: const Icon(Icons.task_alt_rounded),
                  onPressed: _busy ? null : () => _run((c) => c.deliver(), s.tr(OrderText.delivered)),
                  label: busy ?? Text(s.tr(OrderText.deliver)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
