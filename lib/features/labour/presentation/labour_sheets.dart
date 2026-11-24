import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/sheet_form.dart';
import '../../home/data/home_repository.dart';
import '../data/labour_repository.dart';
import '../domain/labour_models.dart';
import 'labour_text.dart';

void refreshTeam(WidgetRef ref) => ref
  ..invalidate(teamProvider)
  ..invalidate(homeProvider);

const _modes = [('CASH', LabText.cash), ('UPI', LabText.upi), ('BANK', LabText.bank)];

/// Pay wages: shows how the payment splits before anything is saved.
Future<void> showPaySheet(BuildContext context, Worker w) => showSutraSheet(context, _PaySheet(worker: w));

class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({required this.worker});
  final Worker worker;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  late final Future<PayPreview> _preview = ref.read(labourRepositoryProvider).payPreview(widget.worker.id);
  String _mode = 'CASH';
  bool _sendSlip = true;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final w = widget.worker;
    return FutureBuilder<PayPreview>(
      future: _preview,
      builder: (context, snap) {
        if (snap.hasError) return ErrorNote(error: snap.error!, strings: s);
        if (!snap.hasData) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
        final p = snap.data!;
        return SheetForm(
          kicker: s.tr(LabText.pay),
          title: w.name,
          saveLabel: '${s.tr(LabText.pay)} ${Fmt.inr(p.cash)}',
          canSave: p.wageDue > 0,
          onSave: () async {
            final slip = await ref.read(labourRepositoryProvider).pay(w.id, mode: _mode);
            refreshTeam(ref);
            if (_sendSlip && (w.phone ?? '').isNotEmpty) await ref.read(linkLauncherProvider).open(slip.whatsappUrl);
            return s.tr(LabText.paid);
          },
          children: [
            LedgerCard(
              padding: const EdgeInsets.fromLTRB(36, 4, 14, 4),
              child: Column(
                children: [
                  LedgerLine(label: s.tr(LabText.earnedDue), value: AmountText(p.wageDue)),
                  if (p.recovery > 0) LedgerLine(label: s.tr(LabText.advanceCut), sub: s.tr(LabText.advanceRule), value: Text('− ${Fmt.inr(p.recovery)}', style: SutraType.figure(18, color: SutraColors.haldiDeep))),
                  LedgerLine(label: s.tr(LabText.inHand), value: AmountText(p.cash, size: 24, incoming: false), last: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(s.tr(LabText.how), style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [for (final (k, t) in _modes) ChoiceChip(label: Text(s.tr(t)), selected: _mode == k, onSelected: (_) => setState(() => _mode = k))]),
            if ((w.phone ?? '').isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _sendSlip,
                onChanged: (v) => setState(() => _sendSlip = v ?? false),
                title: Text(s.tr(LabText.sendSlip)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
          ],
        );
      },
    );
  }
}

Future<void> showAdvanceSheet(BuildContext context, Worker w) => showSutraSheet(context, _AdvanceSheet(worker: w));

class _AdvanceSheet extends ConsumerStatefulWidget {
  const _AdvanceSheet({required this.worker});
  final Worker worker;

  @override
  ConsumerState<_AdvanceSheet> createState() => _AdvanceSheetState();
}

class _AdvanceSheetState extends ConsumerState<_AdvanceSheet> {
  double _amount = 0;
  String _mode = 'CASH';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SheetForm(
      kicker: s.tr(LabText.advanceTitle),
      title: widget.worker.name,
      subtitle: s.tr(LabText.advanceHint),
      saveLabel: s.tr(LabText.advanceTitle),
      canSave: _amount > 0,
      onSave: () async {
        await ref.read(labourRepositoryProvider).giveAdvance(widget.worker.id, amount: _amount, mode: _mode);
        refreshTeam(ref);
        return s.tr(LabText.advanceGiven);
      },
      children: [
        NumberField(label: s.tr(LabText.amount), prefix: '₹ ', initial: null, onChanged: (v) => setState(() => _amount = v ?? 0)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [for (final (k, t) in _modes) ChoiceChip(label: Text(s.tr(t)), selected: _mode == k, onSelected: (_) => setState(() => _mode = k))]),
      ],
    );
  }
}

Future<void> showPieceSheet(BuildContext context, Worker w) => showSutraSheet(context, _PieceSheet(worker: w));

class _PieceSheet extends ConsumerStatefulWidget {
  const _PieceSheet({required this.worker});
  final Worker worker;

  @override
  ConsumerState<_PieceSheet> createState() => _PieceSheetState();
}

class _PieceSheetState extends ConsumerState<_PieceSheet> {
  double _qty = 1;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final w = widget.worker;
    return SheetForm(
      kicker: s.tr(LabText.pieceTitle),
      title: w.name,
      subtitle: '${Fmt.inr(w.rate)} ${s.tr(LabText.perPiece)} = ${Fmt.inr(w.rate * _qty)}',
      saveLabel: s.tr(LabText.pieceSaved),
      onSave: () async {
        await ref.read(labourRepositoryProvider).addPieceWork(w.id, qty: _qty);
        refreshTeam(ref);
        return s.tr(LabText.pieceSaved);
      },
      children: [QtyStepper(value: _qty, min: 1, onChanged: (v) => setState(() => _qty = v))],
    );
  }
}

Future<void> showAddWorkerSheet(BuildContext context) => showSutraSheet(context, const _AddWorkerSheet());

class _AddWorkerSheet extends ConsumerStatefulWidget {
  const _AddWorkerSheet();

  @override
  ConsumerState<_AddWorkerSheet> createState() => _AddWorkerSheetState();
}

class _AddWorkerSheetState extends ConsumerState<_AddWorkerSheet> {
  String _name = '';
  String _phone = '';
  WageType _type = WageType.daily;
  double _rate = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    T per(WageType t) => switch (t) { WageType.piece => LabText.perPiece, WageType.monthly => LabText.perMonth, WageType.daily => LabText.perDay };
    return SheetForm(
      title: s.tr(LabText.addWorker),
      saveLabel: s.tr(LabText.addWorker),
      canSave: _name.trim().isNotEmpty && _rate > 0,
      onSave: () async {
        await ref.read(labourRepositoryProvider).addWorker(name: _name.trim(), phone: _phone.trim().isEmpty ? null : _phone.trim(), wageType: _type, rate: _rate);
        refreshTeam(ref);
        return s.tr(LabText.workerAdded);
      },
      children: [
        TextField(textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(LabText.name)), onChanged: (v) => setState(() => _name = v)),
        const SizedBox(height: 10),
        TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.tr(LabText.phone)), onChanged: (v) => _phone = v),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final (t, label) in [(WageType.daily, LabText.wageDaily), (WageType.piece, LabText.wagePiece), (WageType.monthly, LabText.wageMonthly)])
              ChoiceChip(label: Text(s.tr(label)), selected: _type == t, onSelected: (_) => setState(() => _type = t)),
          ],
        ),
        const SizedBox(height: 10),
        NumberField(key: ValueKey(_type), label: '${s.tr(LabText.rate)} ${s.tr(per(_type))}', prefix: '₹ ', initial: null, onChanged: (v) => setState(() => _rate = v ?? 0)),
      ],
    );
  }
}

/// A worker's full ledger: work done (earnings) and money given, newest first, with the wage slip.
Future<void> showWorkerHistory(BuildContext context, Worker w) => showSutraSheet(context, _HistorySheet(worker: w));

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({required this.worker});
  final Worker worker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final repo = ref.read(labourRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(kicker: s.tr(LabText.history), title: worker.name),
        FutureBuilder<List<LedgerItem>>(
          future: repo.history(worker.id),
          builder: (context, snap) {
            if (snap.hasError) return ErrorNote(error: snap.error!, strings: s);
            if (!snap.hasData) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            return Column(children: [for (final item in snap.data!.take(30)) _HistoryRow(item: item, strings: s)]);
          },
        ),
        const SizedBox(height: 12),
        if ((worker.phone ?? '').isNotEmpty)
          OutlinedButton.icon(
            onPressed: () async {
              final slip = await repo.slip(worker.id);
              await ref.read(linkLauncherProvider).open(slip.whatsappUrl);
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(s.tr(LabText.slip)),
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.strings});
  final LedgerItem item;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final (T label, IconData icon, Color color) = switch (i.kind) {
      'ATTENDANCE' => (LabText.kindAttendance, Icons.how_to_reg_outlined, SutraColors.neel),
      'PIECE' => (LabText.kindPiece, Icons.handyman_outlined, SutraColors.neel),
      'WAGE' => (LabText.kindWage, Icons.payments_outlined, SutraColors.sindoor),
      'ADVANCE' => (LabText.kindAdvance, Icons.savings_outlined, SutraColors.haldiDeep),
      _ => (LabText.kindRecovery, Icons.swap_horiz_rounded, SutraColors.haldiDeep),
    };
    final units = i.units == null ? '' : ' · ${Fmt.qty(i.units!)} ${strings.tr(i.kind == 'PIECE' ? LabText.pieces : LabText.days)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('${strings.tr(label)}$units', style: Theme.of(context).textTheme.bodyMedium)),
          Text(Fmt.shortDate(i.at, hindi: strings.isHindi), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Text('${i.isEarning ? '+' : '−'} ${Fmt.inr(i.amount)}', textAlign: TextAlign.end, style: SutraType.figure(15, color: i.isEarning ? SutraColors.neel : color)),
          ),
        ],
      ),
    );
  }
}
