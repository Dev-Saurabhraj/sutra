import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/async_view.dart';
import '../../design/widgets/bits.dart';
import '../../design/widgets/ledger_card.dart';
import '../../design/widgets/stamp.dart';
import '../../design/widgets/wax_seal.dart';
import 'money_text.dart';

// ---------------------------------------------------------------- C6 schemes

final schemesProvider = FutureProvider.autoDispose((ref) async => (await ref.watch(apiClientProvider).get('/schemes'))['schemes'] as List);

class SchemesScreen extends ConsumerWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(MoneyText.schemes))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<List<dynamic>>(
              value: ref.watch(schemesProvider),
              strings: s,
              onRetry: () => ref.invalidate(schemesProvider),
              data: (list) {
                final rows = list.cast<Map<String, dynamic>>();
                Widget group(String fit, T title) {
                  final items = rows.where((r) => r['fit'] == fit).toList();
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(s.tr(title)),
                      for (final r in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: _SchemeCard(r: r, strings: s)),
                    ],
                  );
                }

                return ListView(
                  padding: SutraSpace.page,
                  children: [
                    Text(s.tr(MoneyText.schemesSub), style: text.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                    group('LIKELY', MoneyText.likely),
                    group('CHECK', MoneyText.check),
                    group('NO', MoneyText.notNow),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SchemeCard extends ConsumerWidget {
  const _SchemeCard({required this.r, required this.strings});
  final Map<String, dynamic> r;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    final fit = r['fit'] as String;
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(32, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              WaxSeal(checked: fit == 'LIKELY', size: 26, color: SutraColors.neel, icon: Icons.star_rounded),
              const SizedBox(width: 10),
              Expanded(child: Text(s.pick(r['nameHi'] as String, r['name'] as String), style: SutraType.display(16))),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.pick(r['whatHi'] as String, r['what'] as String), style: text.bodySmall),
          const SizedBox(height: 4),
          Text('→ ${s.pick(r['whyHi'] as String, r['whyEn'] as String)}', style: text.bodySmall?.copyWith(color: fit == 'NO' ? SutraColors.inkSoft : SutraColors.neelDeep, fontWeight: FontWeight.w700)),
          if (fit != 'NO')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ref.read(linkLauncherProvider).open(r['link'] as String),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(s.tr(MoneyText.officialSite)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- X7 GSTR-2B

class ReconcileScreen extends ConsumerStatefulWidget {
  const ReconcileScreen({super.key});
  @override
  ConsumerState<ReconcileScreen> createState() => _ReconcileScreenState();
}

class _ReconcileScreenState extends ConsumerState<ReconcileScreen> {
  Map<String, dynamic>? _result;
  bool _sample = false;
  bool _busy = false;

  Future<void> _run(Future<Object?> Function() loadData, {required bool sample}) async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final data = await loadData();
      if (data == null) return;
      final r = await ref.read(apiClientProvider).post('/gst/2b/reconcile', body: {'data': data});
      setState(() {
        _result = r;
        _sample = sample;
      });
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(e is FormatException ? s.tr(MoneyText.badFile) : (s.isHindi ? (err.messageHi ?? err.message) : err.message))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Object?> _pick() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (files.isEmpty) return null;
    return jsonDecode(utf8.decode(await files.first.readAsBytes()));
  }

  Future<Object?> _loadSample() async => (await ref.read(apiClientProvider).get('/gst/2b/sample'))['data'];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(MoneyText.twoB))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: ListView(
              padding: SutraSpace.page,
              children: [
                Text(s.tr(MoneyText.twoBSub), style: text.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: SutraColors.neel),
                        onPressed: _busy ? null : () => _run(_pick, sample: false),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(s.tr(MoneyText.pickFile)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _run(_loadSample, sample: true), child: Text(s.tr(MoneyText.trySample)))),
                  ],
                ),
                if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                if (r != null) ...[
                  if (_sample) Padding(padding: const EdgeInsets.only(top: 10), child: Stamp(s.tr(MoneyText.sampleNote), tone: Tone.low, size: 9, angle: 0)),
                  const SizedBox(height: 12),
                  _Totals(totals: (r['totals'] as Map).cast<String, dynamic>(), strings: s),
                  if ((r['rows'] as List).any((x) => (x as Map)['status'] == 'NOT_IN_2B'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${s.tr(MoneyText.notFiled)}: ${s.tr(MoneyText.askSupplier)}', style: text.bodySmall?.copyWith(color: SutraColors.kumkum, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 12),
                  LedgerCard(
                    padding: const EdgeInsets.fromLTRB(32, 8, 12, 8),
                    child: Column(
                      children: [
                        for (final (i, row) in (r['rows'] as List).cast<Map<String, dynamic>>().indexed) _Row(row: row, strings: s, last: i == (r['rows'] as List).length - 1),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals, required this.strings});
  final Map<String, dynamic> totals;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    Widget fig(String label, num v, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: const BorderRadius.all(SutraRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(Fmt.inr(v), style: SutraType.figure(20, color: c)), Text(label, style: Theme.of(context).textTheme.labelMedium)],
            ),
          ),
        );
    return Row(
      children: [
        fig(s.tr(MoneyText.safe), totals['itcConfirmed'] as num, SutraColors.neel),
        const SizedBox(width: 10),
        fig(s.tr(MoneyText.atRisk), totals['itcAtRisk'] as num, SutraColors.kumkum),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.strings, required this.last});
  final Map<String, dynamic> row;
  final AppStrings strings;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final (label, tone) = switch (row['status'] as String) {
      'MATCHED' => (s.tr(MoneyText.matched), Tone.ok),
      'AMOUNT_DIFF' => (s.tr(MoneyText.amountDiff), Tone.low),
      'NOT_IN_2B' => (s.tr(MoneyText.notFiled), Tone.critical),
      _ => (s.tr(MoneyText.notInBooks), Tone.neutral),
    };
    final books = row['booksTax'] as num?;
    final filed = row['filedTax'] as num?;
    return LedgerLine(
      label: '${row['supplier']} · ${row['invoiceNo']}',
      sub: [
        if (books != null) 'GST ${Fmt.inr(books)}',
        if (filed != null && filed != books) '2B ${Fmt.inr(filed)}',
      ].join(' · '),
      value: Stamp(label, tone: tone, size: 9, angle: 0),
      last: last,
    );
  }
}
