import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/stamp.dart';
import '../../home/data/home_repository.dart';
import '../data/khata_repository.dart';
import '../domain/khata_models.dart';

/// "किसका बाकी है?" — two columns of the bahi: लेना (to receive) and देना (to pay).
class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  bool _settled = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final page = ref.watch(khataPageProvider(_settled));
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => ref.refresh(khataPageProvider(_settled).future),
          child: ListView(
            padding: SutraSpace.page,
            children: [
              Text(s.khataTitle, style: SutraType.display(28)),
              const SizedBox(height: 14),
              AsyncView<KhataPage>(
                value: page,
                strings: s,
                onRetry: () => ref.invalidate(khataPageProvider(_settled)),
                data: (p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Totals(page: p, strings: s),
                    const SizedBox(height: 14),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(s.openTab)),
                        ButtonSegment(value: true, label: Text(s.settledTab)),
                      ],
                      selected: {_settled},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) => setState(() => _settled = v.first),
                    ),
                    const SizedBox(height: 14),
                    if (p.entries.isEmpty)
                      Padding(padding: const EdgeInsets.all(32), child: Text(s.nothingHere, textAlign: TextAlign.center))
                    else
                      LedgerCard(
                        padding: const EdgeInsets.fromLTRB(34, 4, 14, 4),
                        child: Column(
                          children: [
                            for (final (i, e) in p.entries.indexed) ...[
                              if (i > 0) const Divider(),
                              _EntryRow(entry: e, strings: s),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.page, required this.strings});
  final KhataPage page;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    Widget column(String label, double amount, bool incoming) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              AmountText(amount, size: 26, incoming: incoming),
            ],
          ),
        );
    return LedgerCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            column(strings.toReceive, page.toReceive, true),
            const VerticalDivider(width: 24),
            column(strings.toPay, page.toPay, false),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry, required this.strings});
  final KhataEntry entry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final e = entry;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.party, style: text.titleSmall),
                    Text(e.note, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (e.dueDate != null && !e.settled) Text(strings.dueOn(Fmt.shortDate(e.dueDate!, hindi: strings.isHindi)), style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(e.amount, incoming: e.incoming),
                  const SizedBox(height: 6),
                  if (e.settled)
                    Stamp(strings.stampPaid, tone: Tone.ok)
                  else if (e.overdueDays > 0)
                    Stamp(strings.overdueDays(e.overdueDays), tone: Tone.critical)
                  else
                    Stamp(strings.stampDue, tone: e.incoming ? Tone.due : Tone.neutral),
                ],
              ),
            ],
          ),
          if (e.msmeDaysLeft != null) ...[
            const SizedBox(height: 6),
            _MsmeClock(daysLeft: e.msmeDaysLeft!, strings: strings),
          ],
          if (!e.settled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (e.incoming)
                  TextButton.icon(
                    onPressed: () => _remind(context, ref),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: Text(strings.remind),
                  ),
                TextButton.icon(
                  onPressed: () => _settle(context, ref),
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  label: Text(strings.settle),
                  style: TextButton.styleFrom(foregroundColor: SutraColors.neel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _remind(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref.read(khataRepositoryProvider).reminder(entry.id);
      await ref.read(linkLauncherProvider).open(r.whatsappUrl);
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(strings.isHindi ? (err.messageHi ?? err.message) : err.message)));
    }
  }

  /// Settling is not undoable, so it is the one place we ask first (RULES B8).
  Future<void> _settle(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(strings.settleConfirm(entry.party, Fmt.inr(entry.amount))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.settle)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(khataRepositoryProvider).settle(entry.id);
    ref
      ..invalidate(khataPageProvider)
      ..invalidate(homeProvider);
  }
}

/// The Sec. 43B(h) clock: how many of the buyer's 45 days are left.
class _MsmeClock extends StatelessWidget {
  const _MsmeClock({required this.daysLeft, required this.strings});
  final int daysLeft;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final used = ((45 - daysLeft) / 45).clamp(0.0, 1.0);
    final color = daysLeft < 0 ? SutraColors.kumkum : (daysLeft <= 7 ? SutraColors.haldiDeep : SutraColors.neel);
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(value: used, strokeWidth: 3, color: color, backgroundColor: SutraColors.rule),
        ),
        const SizedBox(width: 8),
        Text(strings.msmeDaysLeft(daysLeft), style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
