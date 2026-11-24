import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/stamp.dart';
import '../data/labour_repository.dart';
import '../domain/labour_models.dart';
import 'labour_sheets.dart';
import 'labour_text.dart';

/// Labour: who came today, who has earned what, who has been paid, whose pay is due and by when.
class LabourScreen extends ConsumerWidget {
  const LabourScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => ref.refresh(teamProvider.future),
          child: AsyncView<TeamSummary>(
            value: ref.watch(teamProvider),
            strings: s,
            onRetry: () => ref.invalidate(teamProvider),
            data: (team) => ListView(
              padding: SutraSpace.page,
              children: [
                Text(s.tr(LabText.title), style: SutraType.display(28)),
                const SizedBox(height: 14),
                if (team.workers.isEmpty)
                  _Empty(strings: s)
                else ...[
                  _Purse(team: team, strings: s),
                  const SizedBox(height: 14),
                  _RollCall(team: team, strings: s),
                  const SizedBox(height: 18),
                  for (final w in team.workers) _WorkerCard(worker: w, strings: s),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () => showAddWorkerSheet(context), icon: const Icon(Icons.person_add_alt_1_outlined), label: Text(s.tr(LabText.addWorker))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(strings.tr(LabText.noTeam), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      );
}

/// The money picture for the team: what's due (and what's late), advances out, who came today.
class _Purse extends StatelessWidget {
  const _Purse({required this.team, required this.strings});
  final TeamSummary team;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.tr(LabText.wagesDue), style: text.labelMedium),
                    AmountText(team.wageDue, size: 30, incoming: false),
                  ],
                ),
              ),
              if (team.overdue > 0) Stamp('${strings.tr(LabText.overdue)} ${Fmt.inr(team.overdue)}', tone: Tone.critical, size: 12),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Mini(label: strings.tr(LabText.advanceOut), value: Fmt.inr(team.advancePending), color: SutraColors.haldiDeep),
              const SizedBox(width: 20),
              _Mini(label: strings.tr(LabText.cameToday), value: '${team.presentToday}/${team.workers.length}', color: SutraColors.neel),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: SutraType.figure(18, color: color)),
        ],
      );
}

/// Tap each face to cycle present → half day → absent, then save once.
class _RollCall extends ConsumerStatefulWidget {
  const _RollCall({required this.team, required this.strings});
  final TeamSummary team;
  final AppStrings strings;

  @override
  ConsumerState<_RollCall> createState() => _RollCallState();
}

class _RollCallState extends ConsumerState<_RollCall> {
  final Map<String, double> _changed = {};
  bool _saving = false;

  double? _units(Worker w) => _changed[w.id] ?? w.todayUnits;

  void _cycle(Worker w) {
    final next = switch (_units(w)) { null || 0.0 => 1.0, 1.0 => 0.5, _ => 0.0 };
    setState(() => _changed[w.id] = next);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(labourRepositoryProvider).markAttendance(_changed);
      _changed.clear();
      refreshTeam(ref);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SutraColors.card, borderRadius: const BorderRadius.all(SutraRadius.md), border: Border.all(color: SutraColors.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.tr(LabText.rollCall), style: Theme.of(context).textTheme.titleSmall),
          Text(s.tr(LabText.rollCallHint), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final w in widget.team.workers) _Face(worker: w, units: _units(w), strings: s, onTap: () => _cycle(w))],
          ),
          if (_changed.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: SutraColors.neel),
              onPressed: _saving ? null : _save,
              child: Text(s.tr(LabText.saveRollCall)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.worker, required this.units, required this.strings, required this.onTap});
  final Worker worker;
  final double? units;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color ring, T? label) = switch (units) {
      1.0 => (SutraColors.neel, LabText.present),
      0.5 => (SutraColors.haldiDeep, LabText.half),
      0.0 => (SutraColors.kumkum, LabText.absent),
      _ => (SutraColors.rule, null),
    };
    return Semantics(
      button: true,
      label: '${worker.name} ${label == null ? '' : strings.tr(label)}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: SutraMotion.quick,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 3)),
                child: Opacity(opacity: units == 0 ? 0.4 : 1, child: InitialsBadge(name: worker.name, color: _wageColor(worker.wageType), size: 44)),
              ),
              const SizedBox(height: 4),
              Text(worker.name.split(' ').first, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(label == null ? '—' : strings.tr(label), style: TextStyle(fontSize: 11, color: ring, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

Color _wageColor(WageType t) => switch (t) {
      WageType.piece => SutraColors.sindoor,
      WageType.daily => SutraColors.neel,
      WageType.monthly => const Color(0xFF6D28D9),
    };

class _WorkerCard extends ConsumerWidget {
  const _WorkerCard({required this.worker, required this.strings});
  final Worker worker;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = worker;
    final s = strings;
    final text = Theme.of(context).textTheme;
    final per = s.tr(switch (w.wageType) { WageType.piece => LabText.perPiece, WageType.monthly => LabText.perMonth, WageType.daily => LabText.perDay });
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SutraColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(SutraRadius.md),
          side: BorderSide(color: w.overdue > 0 ? SutraColors.kumkum.withValues(alpha: 0.4) : SutraColors.rule),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(SutraRadius.md),
          onTap: () => showWorkerHistory(context, w),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InitialsBadge(name: w.name, color: _wageColor(w.wageType), size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name, style: text.titleSmall),
                          Text([if (w.skill != null) w.skill!, '${Fmt.inr(w.rate)} $per'].join(' · '), style: text.bodySmall),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (w.overdue > 0) Stamp('${s.tr(LabText.overdue)} ${Fmt.inr(w.overdue)}', tone: Tone.critical, size: 10),
                              if (w.advancePending > 0) Stamp('${s.tr(LabText.advance)} ${Fmt.inr(w.advancePending)}', tone: Tone.low, size: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (w.wageDue > 0) ...[
                          AmountText(w.wageDue, size: 20, incoming: false),
                          Text('${Fmt.shortDate(w.payBy, hindi: s.isHindi)} ${s.tr(LabText.payBy)}', style: text.bodySmall),
                        ] else
                          Stamp(s.tr(LabText.paidUp), tone: Tone.ok, size: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (w.wageType == WageType.piece) TextButton(onPressed: () => showPieceSheet(context, w), child: Text(s.tr(LabText.addWork))),
                    TextButton(onPressed: () => showAdvanceSheet(context, w), child: Text(s.tr(LabText.advance))),
                    const SizedBox(width: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 18)),
                      onPressed: w.wageDue > 0 ? () => showPaySheet(context, w) : null,
                      child: Text(s.tr(LabText.pay)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
