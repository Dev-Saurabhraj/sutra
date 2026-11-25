import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/app_strings.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/form_bits.dart';
import '../../design/widgets/ledger_card.dart';
import '../../design/widgets/sheet_form.dart';
import '../../design/widgets/stamp.dart';
import '../../design/widgets/wax_seal.dart';
import '../market/data/market_repository.dart';
import '../orders/data/order_repository.dart';
import '../orders/domain/order_models.dart';
import 'money_text.dart';

(String, Tone) _status(AppStrings s, AdvanceStatus st) => switch (st) {
      AdvanceStatus.requested => (s.tr(MoneyText.asked), Tone.due),
      AdvanceStatus.claimed => (s.tr(MoneyText.claimed), Tone.low),
      AdvanceStatus.paid => (s.tr(MoneyText.paid), Tone.ok),
    };

/// Maker side (B8): ask for an advance, then confirm it arrived in your UPI.
class MakerAdvanceCard extends ConsumerWidget {
  const MakerAdvanceCard({super.key, required this.order, required this.strings});
  final Order order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final a = order.advance;
    final text = Theme.of(context).textTheme;
    if (a == null) {
      return OutlinedButton.icon(
        onPressed: () => showSutraSheet<void>(context, _AskSheet(code: order.code)),
        icon: const Icon(Icons.currency_rupee_rounded),
        label: Text(s.tr(MoneyText.askAdvance)),
      );
    }
    final (label, tone) = _status(s, a.status);
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(32, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (a.status == AdvanceStatus.paid) const Padding(padding: EdgeInsets.only(right: 10), child: WaxSeal(size: 28, color: SutraColors.neel)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.tr(MoneyText.advance), style: text.titleSmall),
                    Text(Fmt.inr(a.amount), style: SutraType.figure(22, color: a.status == AdvanceStatus.paid ? SutraColors.neel : SutraColors.ink)),
                  ],
                ),
              ),
              Stamp(label, tone: tone, size: 9, angle: 0),
            ],
          ),
          if (a.ref != null) Text('${s.tr(MoneyText.ref)} ${a.ref}', style: text.bodySmall),
          if (a.status == AdvanceStatus.claimed) ...[
            const SizedBox(height: 6),
            Text(s.tr(MoneyText.checkUpi), style: text.bodySmall?.copyWith(color: SutraColors.haldiDeep)),
          ],
          if (a.status != AdvanceStatus.paid) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: SutraColors.neel),
              onPressed: () => ref.read(orderControllerProvider(order.code).notifier).confirmAdvance(),
              icon: const Icon(Icons.check_rounded),
              label: Text(s.tr(MoneyText.confirm)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AskSheet extends ConsumerStatefulWidget {
  const _AskSheet({required this.code});
  final String code;
  @override
  ConsumerState<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends ConsumerState<_AskSheet> {
  int _pct = 30;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SheetForm(
      title: s.tr(MoneyText.askAdvance),
      subtitle: s.tr(MoneyText.askSub),
      saveLabel: '${s.tr(MoneyText.ask)} $_pct%',
      onSave: () async {
        await ref.read(orderControllerProvider(widget.code).notifier).requestAdvance(_pct);
        return null;
      },
      children: [
        Text(s.tr(MoneyText.percentOf), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [for (final p in const [20, 30, 50]) ChoiceChip(label: Text('$p%'), selected: _pct == p, onSelected: (_) => setState(() => _pct = p))]),
      ],
    );
  }
}

/// Buyer side (B8): pay the advance by UPI straight to the maker, then give the reference.
class BuyerAdvanceCard extends ConsumerWidget {
  const BuyerAdvanceCard({super.key, required this.code, required this.advance, required this.strings});
  final String code;
  final AdvanceInfo advance;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final a = advance;
    final text = Theme.of(context).textTheme;
    final (label, tone) = switch (a.status) {
      AdvanceStatus.requested => (s.tr(MoneyText.askAdvance), Tone.due),
      AdvanceStatus.claimed => (s.tr(MoneyText.waitingMaker), Tone.low),
      AdvanceStatus.paid => (s.tr(MoneyText.paid), Tone.ok),
    };
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(32, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.tr(MoneyText.advance), style: text.titleSmall),
                    Text(Fmt.inr(a.amount), style: SutraType.figure(22, color: SutraColors.sindoorDeep)),
                  ],
                ),
              ),
              Stamp(label, tone: tone, size: 9, angle: 0),
            ],
          ),
          Text(s.tr(MoneyText.payDirect), style: text.bodySmall),
          if (a.status == AdvanceStatus.requested) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (a.upiUrl != null)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: SutraColors.neel),
                      onPressed: () => ref.read(linkLauncherProvider).open(a.upiUrl!),
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: Text(s.tr(MoneyText.payUpi)),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: () => showSutraSheet<void>(context, _PaidSheet(code: code)), child: Text(s.tr(MoneyText.iPaid))),
                ),
              ],
            ),
          ],
          if (a.ref != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${s.tr(MoneyText.ref)} ${a.ref}', style: text.bodySmall)),
        ],
      ),
    );
  }
}

class _PaidSheet extends ConsumerStatefulWidget {
  const _PaidSheet({required this.code});
  final String code;
  @override
  ConsumerState<_PaidSheet> createState() => _PaidSheetState();
}

class _PaidSheetState extends ConsumerState<_PaidSheet> {
  String _utr = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SheetForm(
      title: s.tr(MoneyText.iPaid),
      saveLabel: s.tr(MoneyText.iPaid),
      canSave: RegExp(r'^\d{12}$').hasMatch(_utr),
      onSave: () async {
        await ref.read(buyerOrderProvider(widget.code).notifier).claimAdvance(_utr);
        return null;
      },
      children: [
        TextField(
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: s.tr(MoneyText.utrLabel), counterText: ''),
          onChanged: (v) => setState(() => _utr = v),
        ),
      ],
    );
  }
}

/// X6: does this consignment need an e-way bill, and the details ready to type into the portal.
class EwayBillCard extends ConsumerWidget {
  const EwayBillCard({super.key, required this.code, required this.strings});
  final String code;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    return ref.watch(ewayBillProvider(code)).maybeWhen(
          data: (e) {
            final required = e['required'] as bool;
            final finalDoc = e['finalDocument'] as bool? ?? false;
            final a = (e['partA'] as Map).cast<String, dynamic>();
            final b = (e['partB'] as Map).cast<String, dynamic>();
            final lines = [
              '${a['docType']} ${a['docNo']} · ${a['docDate']}',
              '${a['fromGstin']} → ${a['toGstin']} (${a['toState']})',
              'HSN ${(a['items'] as List).first['hsnCode']} · ${Fmt.inr(a['totalInvoiceValue'] as num)}',
              if ((b['transDocNo'] as String).isNotEmpty || (b['vehicleNo'] as String).isNotEmpty) 'LR ${b['transDocNo']} · ${b['vehicleNo']}',
            ];
            return LedgerCard(
              padding: const EdgeInsets.fromLTRB(32, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(s.tr(MoneyText.eway), style: SutraType.display(16))),
                      Stamp(s.tr(required ? MoneyText.ewayNeeded : MoneyText.ewayNotNeeded), tone: required ? Tone.critical : Tone.ok, size: 9, angle: 0),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(s.pick(e['reasonHi'] as String, e['reasonEn'] as String), style: text.bodySmall),
                  if (required) ...[
                    const SizedBox(height: 8),
                    if (!finalDoc) Text(s.tr(MoneyText.ewayAfter), style: text.labelSmall?.copyWith(color: SutraColors.haldiDeep)),
                    for (final l in lines) Text(l, style: text.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: [...lines, 'Part A: $a', 'Part B: $b'].join('\n')));
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.tr(MoneyText.copied))));
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(s.tr(MoneyText.copyFields)),
                        ),
                        TextButton.icon(
                          onPressed: () => ref.read(linkLauncherProvider).open(e['portal'] as String),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(s.tr(MoneyText.openPortal)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}
