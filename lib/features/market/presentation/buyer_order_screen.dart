import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/art/stage_thread.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/product_thumb.dart';
import '../../../design/widgets/stamp.dart';
import '../../gst/presentation/gst_text.dart';
import '../../orders/domain/order_models.dart';
import '../data/market_repository.dart';
import '../domain/market_models.dart';
import 'buyer_orders_screen.dart';
import 'market_text.dart';

/// B6: one order from the buyer's side: where it is, what was promised, the rest of a shared request,
/// proof of dispatch, documents, and letters with the maker.
class BuyerOrderScreen extends ConsumerWidget {
  const BuyerOrderScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(code)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<BuyerOrderDetail>(
              value: ref.watch(buyerOrderProvider(code)),
              strings: s,
              onRetry: () => ref.invalidate(buyerOrderProvider(code)),
              data: (d) => RefreshIndicator(
                color: SutraColors.sindoor,
                onRefresh: () => ref.refresh(buyerOrderProvider(code).future),
                child: ListView(
                  padding: SutraSpace.page,
                  children: [
                    _Header(order: d.order, strings: s),
                    if (d.group.isNotEmpty) ...[const SizedBox(height: 14), _Group(order: d.order, group: d.group, strings: s)],
                    if (d.order.dispatchedAt != null) ...[const SizedBox(height: 14), _Shipped(order: d.order, strings: s)],
                    if (d.invoices.isNotEmpty) ...[SectionHeader(s.tr(MarketText.documents)), _Documents(invoices: d.invoices, strings: s)],
                    SectionHeader(s.tr(MarketText.letters)),
                    for (final l in d.letters) Padding(padding: const EdgeInsets.only(bottom: 10), child: _Letter(letter: l, strings: s)),
                    if (d.order.stage != OrderStage.declined) _Composer(code: code, strings: s),
                  ],
                ),
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
  final BuyerOrder order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final o = order;
    final (label, tone) = buyerStage(s, o.stage);
    final hindi = s.isHindi;
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumb(palette: o.palette, imageUrl: o.imageUrl, size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.productName, style: SutraType.display(17), maxLines: 2),
                    Text(o.maker, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Stamp(label, tone: tone, size: 10),
            ],
          ),
          const SizedBox(height: 8),
          LedgerLine(label: '${o.qty} ${s.tr(MarketText.pieces)} × ${Fmt.inr(o.rate)}', value: AmountText(o.value, size: 18)),
          if (o.wantedBy != null)
            LedgerLine(
              label: s.tr(MarketText.wantedBy),
              value: Text(Fmt.shortDate(o.wantedBy!, hindi: hindi), style: SutraType.figure(16, color: SutraColors.sindoorDeep)),
            ),
          if (o.promisedQtyByWanted != null)
            LedgerLine(
              label: s.tr(MarketText.promise),
              sub: o.fullDate == null ? null : '${s.tr(MarketText.allBy)} ${Fmt.shortDate(o.fullDate!, hindi: hindi)}',
              value: Text('${o.promisedQtyByWanted} / ${o.qty}', style: SutraType.figure(16, color: SutraColors.neel)),
              last: true,
            ),
          const SizedBox(height: 12),
          StageThread(
            labels: [s.tr(MarketText.stageAsked), s.tr(MarketText.stageMaking), s.tr(MarketText.stageSent), s.tr(MarketText.stageReached)],
            current: o.stage.step,
            stopped: o.stage == OrderStage.declined,
          ),
        ],
      ),
    );
  }
}

/// The other makers' parts of the same request, so the buyer sees the whole order.
class _Group extends StatelessWidget {
  const _Group({required this.order, required this.group, required this.strings});
  final BuyerOrder order;
  final List<GroupPart> group;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final total = order.qty + group.fold(0, (a, g) => a + g.qty);
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${order.group} · ${s.tr(MarketText.partOf)} · $total ${s.tr(MarketText.pieces)}', style: Theme.of(context).textTheme.titleSmall),
          for (final (i, g) in group.indexed)
            LedgerLine(
              label: g.maker,
              sub: g.code,
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${g.qty}', style: SutraType.figure(15)),
                  const SizedBox(width: 8),
                  Stamp(buyerStage(s, g.stage).$1, tone: buyerStage(s, g.stage).$2, size: 9, angle: 0),
                ],
              ),
              last: i == group.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Shipped extends ConsumerWidget {
  const _Shipped({required this.order, required this.strings});
  final BuyerOrder order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final o = order;
    final text = Theme.of(context).textTheme;
    final via = [o.transporter, if (o.lrNumber != null) 'LR ${o.lrNumber}'].whereType<String>().join(' · ');
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.tr(MarketText.shipped)} · ${Fmt.shortDate(o.dispatchedAt!, hindi: s.isHindi)}', style: text.titleSmall),
                if (via.isNotEmpty) Text(via, style: text.bodySmall),
                if (o.hasDispatchPhoto) Text(s.tr(MarketText.proof), style: text.labelSmall),
              ],
            ),
          ),
          if (o.hasDispatchPhoto)
            ref.watch(buyerDispatchPhotoProvider(o.code)).maybeWhen(
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

class _Documents extends ConsumerWidget {
  const _Documents({required this.invoices, required this.strings});
  final List<OrderInvoice> invoices;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LedgerCard(
      child: Column(
        children: [
          for (final (i, inv) in invoices.indexed)
            LedgerLine(
              label: inv.number,
              sub: strings.tr(switch (inv.kind) { 'PROFORMA' => GstText.kindProforma, 'TAX' => GstText.kindTax, _ => GstText.kindBos }),
              value: Row(mainAxisSize: MainAxisSize.min, children: [AmountText(inv.total, size: 16), const SizedBox(width: 6), const Icon(Icons.picture_as_pdf_outlined, size: 18, color: SutraColors.sindoor)]),
              last: i == invoices.length - 1,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final bytes = await ref.read(marketRepositoryProvider).invoicePdf(inv.id);
                  await Printing.sharePdf(bytes: bytes, filename: '${inv.number.replaceAll('/', '-')}.pdf');
                } catch (e) {
                  final err = ApiException.from(e);
                  messenger.showSnackBar(SnackBar(content: Text(strings.isHindi ? (err.messageHi ?? err.message) : err.message)));
                }
              },
            ),
        ],
      ),
    );
  }
}

/// Letters, mirrored from the maker's side: the buyer's own on the right, the maker's on the left.
final _devanagari = RegExp(r'[ऀ-ॿ]');

class _Letter extends StatefulWidget {
  const _Letter({required this.letter, required this.strings});
  final BuyerLetter letter;
  final AppStrings strings;

  @override
  State<_Letter> createState() => _LetterState();
}

class _LetterState extends State<_Letter> {
  bool _original = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.letter;
    final s = widget.strings;
    final text = Theme.of(context).textTheme;
    final mine = l.mine;
    // the maker's Hindi reaches the buyer in English when translation is on; otherwise it says so
    final note = mine ? null : (l.translated ? s.tr(MarketText.translatedFromHindi) : (_devanagari.hasMatch(l.text) ? s.tr(MarketText.notTranslated) : null));
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: mine ? SutraColors.neelWash : SutraColors.haldiWash,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 3),
              bottomRight: Radius.circular(mine ? 3 : 14),
            ),
            border: Border(left: BorderSide(color: mine ? SutraColors.neel : SutraColors.haldiDeep, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_original ? l.original : l.text, style: text.bodyMedium?.copyWith(height: 1.45)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text([if (mine) s.tr(MarketText.you), Fmt.ago(l.at, hindi: s.isHindi), ?note].join(' · '), style: text.labelSmall?.copyWith(color: SutraColors.inkSoft)),
                  ),
                  if (l.translated)
                    InkWell(
                      onTap: () => setState(() => _original = !_original),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(s.tr(MarketText.original), style: text.labelSmall?.copyWith(color: SutraColors.neel, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends ConsumerStatefulWidget {
  const _Composer({required this.code, required this.strings});
  final String code;
  final AppStrings strings;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(buyerOrderProvider(widget.code).notifier).send(t);
      _text.clear();
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(widget.strings.isHindi ? (err.messageHi ?? err.message) : err.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            minLines: 1,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(hintText: widget.strings.tr(MarketText.write), counterText: ''),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size(52, 52)),
          onPressed: _busy ? null : _send,
          icon: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}
