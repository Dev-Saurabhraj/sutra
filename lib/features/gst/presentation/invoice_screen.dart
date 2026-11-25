import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/parchi.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/gst_repository.dart';
import '../domain/gst_models.dart';
import 'gst_screen.dart';
import 'gst_text.dart';

/// One invoice, laid out like the PDF, with a button to share or print the PDF itself.
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<InvoiceRow>(
              value: ref.watch(invoiceProvider(id)),
              strings: s,
              onRetry: () => ref.invalidate(invoiceProvider(id)),
              data: (inv) => ListView(
                padding: SutraSpace.page,
                children: [
                  _InvoicePaper(inv: inv, strings: s),
                  const SizedBox(height: 16),
                  _ShareButton(inv: inv, strings: s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoicePaper extends ConsumerWidget {
  const _InvoicePaper({required this.inv, required this.strings});
  final InvoiceRow inv;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final seller = ref.watch(meProvider)?.producer;
    final text = Theme.of(context).textTheme;
    return Parchi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller?.businessName ?? '', style: SutraType.display(18, color: SutraColors.sindoor)),
                    if (seller != null) Text('${seller.city}, ${seller.state}', style: text.bodySmall),
                    if (seller?.gstin != null) Text('GSTIN ${seller!.gstin}', style: text.bodySmall),
                  ],
                ),
              ),
              InvoiceKindStamp(kind: inv.kind, strings: s),
            ],
          ),
          const SizedBox(height: 10),
          const ThreadStripe(radius: 2),
          const SizedBox(height: 10),
          Text(inv.number, style: SutraType.figure(18)),
          Text(Fmt.shortDate(inv.issuedAt, hindi: s.isHindi), style: text.bodySmall),
          const SizedBox(height: 12),
          Text(s.tr(GstText.buyer), style: text.labelSmall),
          Text(inv.buyerName, style: text.titleSmall),
          if (inv.buyerGstin != null) Text('GSTIN ${inv.buyerGstin}', style: text.bodySmall),
          Text('${s.tr(GstText.placeOfSupply)}: ${inv.buyerState}', style: text.bodySmall),
          const SizedBox(height: 12),
          LedgerCard(
            padding: const EdgeInsets.fromLTRB(34, 2, 12, 2),
            child: Column(
              children: [
                LedgerLine(label: inv.itemName, sub: 'HSN ${inv.hsn.isEmpty ? '-' : inv.hsn} · ${Fmt.qty(inv.qty)} × ${Fmt.inr(inv.rate)}', value: AmountText(inv.taxable, size: 16)),
                if (inv.igst > 0) LedgerLine(label: 'IGST ${Fmt.qty(inv.gstRate)}%', value: AmountText(inv.igst, size: 16)),
                if (inv.cgst > 0) ...[
                  LedgerLine(label: 'CGST ${Fmt.qty(inv.gstRate / 2)}%', value: AmountText(inv.cgst, size: 16)),
                  LedgerLine(label: 'SGST ${Fmt.qty(inv.gstRate / 2)}%', value: AmountText(inv.sgst, size: 16)),
                ],
                LedgerLine(label: s.isHindi ? 'कुल' : 'Total', value: AmountText(inv.total, size: 22), last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends ConsumerStatefulWidget {
  const _ShareButton({required this.inv, required this.strings});
  final InvoiceRow inv;
  final AppStrings strings;

  @override
  ConsumerState<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends ConsumerState<_ShareButton> {
  bool _busy = false;

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(gstRepositoryProvider).invoicePdf(widget.inv.id);
      await Printing.sharePdf(bytes: bytes, filename: '${widget.inv.number.replaceAll('/', '-')}.pdf');
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(widget.strings.isHindi ? (err.messageHi ?? err.message) : err.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _busy ? null : _share,
      icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)) : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(widget.strings.tr(GstText.sharePdf)),
    );
  }
}
