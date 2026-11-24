import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/art/thread_meter.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/stamp.dart';
import '../data/gst_repository.dart';
import '../domain/gst_models.dart';
import 'gst_text.dart';

/// "GST का हिसाब": one period at a time, drawn for the producer's own scheme,
/// with what to fix, files for the CA, and the recent invoices.
class GstScreen extends ConsumerWidget {
  const GstScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tr(GstText.title)),
        actions: [
          TextButton.icon(onPressed: () => context.push('/bill'), icon: const Icon(Icons.photo_camera_outlined), label: Text(s.tr(GstText.snapBill))),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: RefreshIndicator(
              color: SutraColors.sindoor,
              onRefresh: () => ref.refresh(gstSummaryProvider.future),
              child: ListView(
                padding: SutraSpace.page,
                children: [
                  _PeriodPicker(strings: s),
                  const SizedBox(height: 14),
                  AsyncView<GstSummary>(
                    value: ref.watch(gstSummaryProvider),
                    strings: s,
                    onRetry: () => ref.invalidate(gstSummaryProvider),
                    data: (g) => _SummaryView(summary: g, strings: s),
                  ),
                  const SizedBox(height: 22),
                  Text(s.tr(GstText.recentBills), style: SutraType.display(18)),
                  const SizedBox(height: 10),
                  _RecentInvoices(strings: s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodPicker extends ConsumerStatefulWidget {
  const _PeriodPicker({required this.strings});
  final AppStrings strings;

  @override
  ConsumerState<_PeriodPicker> createState() => _PeriodPickerState();
}

class _PeriodPickerState extends ConsumerState<_PeriodPicker> {
  bool _quarters = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final periods = ref.watch(gstPeriodsProvider).valueOrNull;
    final selected = ref.watch(gstPeriodProvider);
    if (periods == null) return const SizedBox(height: 48);
    final list = _quarters ? periods.quarters : periods.months;
    final current = selected ?? PeriodChoice.month(periods.months.first.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [ButtonSegment(value: false, label: Text(s.tr(GstText.month))), ButtonSegment(value: true, label: Text(s.tr(GstText.quarter)))],
          selected: {_quarters},
          showSelectedIcon: false,
          onSelectionChanged: (v) {
            setState(() => _quarters = v.first);
            final first = (v.first ? periods.quarters : periods.months).first.key;
            ref.read(gstPeriodProvider.notifier).state = v.first ? PeriodChoice.quarter(first) : PeriodChoice.month(first);
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = list[i];
              final choice = _quarters ? PeriodChoice.quarter(p.key) : PeriodChoice.month(p.key);
              return ChoiceChip(label: Text(p.label), selected: current == choice, onSelected: (_) => ref.read(gstPeriodProvider.notifier).state = choice);
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary, required this.strings});
  final GstSummary summary;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final g = summary;
    final s = strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (g.scheme) {
          GstScheme.regular => _RegularCard(g: g, strings: s),
          GstScheme.composition => _LimitCard(
              strings: s,
              headline: s.tr(GstText.compositionTax),
              amount: g.compositionTax,
              note: s.tr(GstText.compositionHow),
              limitLabel: s.tr(GstText.compositionLimit),
              used: g.fyTurnover,
              limit: g.compositionLimit,
            ),
          GstScheme.unregistered => _LimitCard(
              strings: s,
              headline: s.tr(GstText.fyTurnover),
              amount: g.fyTurnover,
              note: null,
              limitLabel: s.tr(GstText.registration),
              used: g.fyTurnover,
              limit: g.registrationThreshold,
              stamp: g.mustRegister ? s.tr(GstText.mustRegister) : null,
            ),
        },
        const SizedBox(height: 12),
        LedgerCard(
          child: Column(
            children: [
              LedgerLine(label: s.tr(GstText.sales), sub: '${g.salesCount} ${s.tr(GstText.bills)} · B2B ${g.b2b} · B2C ${g.b2c}', value: AmountText(g.salesTaxable, size: 17)),
              LedgerLine(label: s.tr(GstText.purchases), value: Text('${g.purchasesCount}', style: SutraType.figure(17)), last: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Issues(issues: g.issues, strings: s),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: SutraColors.haldiWash, borderRadius: BorderRadius.all(SutraRadius.sm)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_note_outlined, size: 18, color: SutraColors.haldiDeep),
              const SizedBox(width: 8),
              Expanded(child: Text(s.pick(g.filingHi, g.filingEn), style: const TextStyle(color: SutraColors.haldiDeep, fontSize: 13, height: 1.4))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Exports(regular: g.scheme == GstScheme.regular, strings: s),
      ],
    );
  }
}

/// Regular GST: tax collected vs credit as two woven bars, and the difference in big ink.
class _RegularCard extends StatelessWidget {
  const _RegularCard({required this.g, required this.strings});
  final GstSummary g;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    final top = math.max(1.0, math.max(g.outputTax, g.itc));
    Widget bar(String label, double v, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [Expanded(child: Text(label, style: text.bodyMedium)), Text(Fmt.inr(v), style: SutraType.figure(16, color: c))]),
              const SizedBox(height: 4),
              WovenBar(value: v / top, color: c),
            ],
          ),
        );
    final owe = g.payable > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SutraColors.card, borderRadius: const BorderRadius.all(SutraRadius.lg), border: Border.all(color: SutraColors.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(g.periodLabel, style: text.labelMedium),
          const SizedBox(height: 10),
          bar(s.tr(GstText.taxCollected), g.outputTax, SutraColors.sindoor),
          bar(s.tr(GstText.taxCredit), g.itc, SutraColors.neel),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(child: Text(s.tr(owe ? GstText.payable : GstText.carryForward), style: text.titleSmall)),
              AmountText(owe ? g.payable : g.carryForward, size: 26, incoming: !owe),
            ],
          ),
          if (g.itcAtRisk > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(alignment: Alignment.centerLeft, child: Stamp('${s.tr(GstText.atRisk)} ${Fmt.inr(g.itcAtRisk)}', tone: Tone.critical, size: 10)),
            ),
        ],
      ),
    );
  }
}

/// Composition and unregistered sellers: one figure, and a woven meter toward the limit that matters to them.
class _LimitCard extends StatelessWidget {
  const _LimitCard({required this.strings, required this.headline, required this.amount, required this.note, required this.limitLabel, required this.used, required this.limit, this.stamp});
  final AppStrings strings;
  final String headline;
  final double amount;
  final String? note;
  final String limitLabel;
  final double used;
  final double limit;
  final String? stamp;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final share = limit <= 0 ? 0.0 : used / limit;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SutraColors.card, borderRadius: const BorderRadius.all(SutraRadius.lg), border: Border.all(color: SutraColors.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(headline, style: text.titleSmall)),
              ?(stamp == null ? null : Stamp(stamp!, tone: Tone.critical, size: 10)),
            ],
          ),
          AmountText(amount, size: 28, incoming: false),
          if (note != null) Text(note!, style: text.bodySmall),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: Text(limitLabel, style: text.bodySmall)), Text('${Fmt.inr(used)} / ${Fmt.inr(limit)}', style: text.labelMedium)]),
          const SizedBox(height: 6),
          WovenBar(value: share, color: share >= 0.8 ? SutraColors.kumkum : SutraColors.neel, height: 14, marker: 0.8),
        ],
      ),
    );
  }
}

class _Issues extends StatelessWidget {
  const _Issues({required this.issues, required this.strings});
  final List<GstIssue> issues;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    if (issues.isEmpty) return Align(alignment: Alignment.centerLeft, child: Stamp(s.tr(GstText.allGood), tone: Tone.ok, size: 12));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr(GstText.fix), style: Theme.of(context).textTheme.titleSmall),
        for (final i in issues)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SutraColors.card,
              borderRadius: const BorderRadius.all(SutraRadius.sm),
              border: Border(left: BorderSide(color: i.kind == 'NEAR_LIMIT' ? SutraColors.haldiDeep : SutraColors.kumkum, width: 4)),
            ),
            child: Text(s.pick(i.textHi, i.text), style: Theme.of(context).textTheme.bodyMedium),
          ),
      ],
    );
  }
}

/// Files for the CA, shared through whatever app they use (WhatsApp, email…).
class _Exports extends ConsumerWidget {
  const _Exports({required this.regular, required this.strings});
  final bool regular;
  final AppStrings strings;

  Future<void> _share(BuildContext context, WidgetRef ref, {required bool json}) async {
    final messenger = ScaffoldMessenger.of(context);
    final period = ref.read(gstPeriodProvider);
    try {
      final repo = ref.read(gstRepositoryProvider);
      final bytes = json ? await repo.gstr1(period) : await repo.csv(period);
      final name = 'sutra-${json ? 'gstr1' : 'gst'}-${period?.key ?? 'this-month'}.${json ? 'json' : 'csv'}';
      await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: json ? 'application/json' : 'text/csv')], fileNameOverrides: [name]));
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(strings.isHindi ? (err.messageHi ?? err.message) : err.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr(GstText.forCa), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _share(context, ref, json: false), icon: const Icon(Icons.table_chart_outlined), label: Text(s.tr(GstText.csv)))),
            if (regular) ...[
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => _share(context, ref, json: true), icon: const Icon(Icons.data_object_rounded), label: Text(s.tr(GstText.gstr1)))),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(s.tr(GstText.reviewNote), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RecentInvoices extends ConsumerWidget {
  const _RecentInvoices({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    return AsyncView<List<InvoiceRow>>(
      value: ref.watch(invoicesProvider),
      strings: s,
      onRetry: () => ref.invalidate(invoicesProvider),
      data: (list) => LedgerCard(
        padding: const EdgeInsets.fromLTRB(34, 4, 12, 4),
        child: Column(
          children: [
            for (final (i, inv) in list.indexed) ...[
              if (i > 0) const Divider(),
              InkWell(
                onTap: () => context.push('/invoice/${inv.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.number, style: SutraType.figure(14)),
                            Text(inv.buyerName, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AmountText(inv.total, size: 15),
                          const SizedBox(height: 4),
                          InvoiceKindStamp(kind: inv.kind, strings: s),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InvoiceKindStamp extends StatelessWidget {
  const InvoiceKindStamp({super.key, required this.kind, required this.strings});
  final String kind;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final (T label, Tone tone) = switch (kind) {
      'TAX' => (GstText.kindTax, Tone.due),
      'PROFORMA' => (GstText.kindProforma, Tone.neutral),
      _ => (GstText.kindBos, Tone.low),
    };
    return Stamp(strings.tr(label), tone: tone, size: 9);
  }
}
