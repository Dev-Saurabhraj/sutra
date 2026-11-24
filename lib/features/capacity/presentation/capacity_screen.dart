import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/sheet_form.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_models.dart';
import '../data/capacity_repository.dart';
import '../domain/capacity_models.dart';
import 'capacity_text.dart';

/// P24: six weeks as a loom calendar. Each day shows its machines as warp threads; threads that are off are cut.
class CapacityScreen extends ConsumerWidget {
  const CapacityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(CapText.title))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SutraColors.sindoor,
        foregroundColor: Colors.white,
        onPressed: () => showSutraSheet<void>(context, const _AddSheet()),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.tr(CapText.add)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: RefreshIndicator(
              color: SutraColors.sindoor,
              onRefresh: () => ref.refresh(capacityProvider.future),
              child: AsyncView<CapacityCalendar>(
                value: ref.watch(capacityProvider),
                strings: s,
                onRetry: () => ref.invalidate(capacityProvider),
                data: (c) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    Text(s.tr(CapText.sub), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                    const SizedBox(height: 14),
                    LoomCalendar(calendar: c, strings: s),
                    const SizedBox(height: 12),
                    LedgerCard(
                      child: LedgerLine(
                        label: s.tr(CapText.lost),
                        sub: '${c.machines} ${s.pick(c.machineLabelHi, c.machineLabel)}',
                        value: Text('${c.machineDaysLost} ${s.tr(CapText.machineDays)}', style: SutraType.figure(16, color: SutraColors.haldiDeep)),
                        last: true,
                      ),
                    ),
                    SectionHeader(s.tr(CapText.entries)),
                    if (c.events.isEmpty)
                      Text(s.tr(CapText.none), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft))
                    else
                      for (final e in c.events) _EventRow(event: e, strings: s, machines: c.machines),
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

/// Six rows of seven days. A day's warp threads stand for its machines: bare cream where they're off,
/// a red cut mark when every machine stops.
class LoomCalendar extends StatelessWidget {
  const LoomCalendar({super.key, required this.calendar, required this.strings});
  final CapacityCalendar calendar;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final days = calendar.days;
    if (days.isEmpty) return const SizedBox.shrink();
    final locale = strings.isHindi ? 'hi' : 'en_IN';
    final first = days.first.date;
    // start the grid on Monday so weeks line up
    final lead = (first.weekday - DateTime.monday) % 7;
    final cells = <CapacityDay?>[...List.filled(lead, null), ...days];
    final monday = first.subtract(Duration(days: lead));
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(32, 12, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(DateFormat.E(locale).format(monday.add(Duration(days: i))), textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r * 7 < cells.length; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: r * 7 + c < cells.length && cells[r * 7 + c] != null
                            ? _DayCell(day: cells[r * 7 + c]!, total: calendar.machines, today: r * 7 + c == lead, strings: strings)
                            : const SizedBox(height: 46),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.total, required this.today, required this.strings});
  final CapacityDay day;
  final int total;
  final bool today;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final closed = day.machines == 0;
    final bg = closed ? SutraColors.sindoorWash : (day.off > 0 ? SutraColors.haldiWash : SutraColors.paper);
    return Semantics(
      label: '${Fmt.shortDate(day.date, hindi: strings.isHindi)}: ${day.machines}/$total',
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: today ? Border.all(color: SutraColors.sindoor, width: 1.6) : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              // the 1st of a month carries the month's name, so the grid reads across months
              child: Text(
                day.date.day == 1 ? Fmt.shortDate(day.date, hindi: strings.isHindi) : '${day.date.day}',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(fontSize: 11, fontWeight: today || day.date.day == 1 ? FontWeight.w800 : FontWeight.w600, color: day.date.day == 1 ? SutraColors.sindoorDeep : SutraColors.ink, height: 1.1),
              ),
            ),
            Expanded(child: CustomPaint(size: Size.infinite, painter: _WarpPainter(working: day.machines, total: total))),
          ],
        ),
      ),
    );
  }
}

class _WarpPainter extends CustomPainter {
  const _WarpPainter({required this.working, required this.total});
  final int working;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    // at most 12 threads per cell; each stands for total/12 machines
    final threads = total.clamp(1, 12);
    final on = (working / total * threads).round();
    final gap = size.width / (threads + 1);
    final top = 4.0;
    final bottom = size.height - 5;
    for (var i = 0; i < threads; i++) {
      final x = gap * (i + 1);
      final working = i < on;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        Paint()
          ..color = working ? SutraColors.neel : SutraColors.rule
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
    if (on == 0) {
      final cut = Paint()..color = SutraColors.kumkum..strokeWidth = 1.8;
      canvas.drawLine(Offset(gap * 0.6, top + 2), Offset(size.width - gap * 0.6, bottom - 2), cut);
    }
  }

  @override
  bool shouldRepaint(covariant _WarpPainter old) => old.working != working || old.total != total;
}

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event, required this.strings, required this.machines});
  final CapacityEvent event;
  final AppStrings strings;
  final int machines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final e = event;
    final text = Theme.of(context).textTheme;
    final dates = e.days == 1
        ? Fmt.shortDate(e.startsOn, hindi: s.isHindi)
        : '${Fmt.shortDate(e.startsOn, hindi: s.isHindi)} – ${Fmt.shortDate(e.endsOn, hindi: s.isHindi)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: SutraColors.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(SutraRadius.md), side: BorderSide(color: SutraColors.rule)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: SutraColors.haldiWash, shape: BoxShape.circle),
                child: Icon(kindIcon(e.kind), color: SutraColors.haldiDeep, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.tr(kindLabel(e.kind))} · $dates', style: text.titleSmall),
                    Text(
                      [e.machinesOff >= machines ? s.tr(CapText.all) : '${e.machinesOff}/$machines', s.tr(CapText.off), if (e.note != null) '· ${e.note}'].join(' '),
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.cancel,
                icon: const Icon(Icons.delete_outline_rounded, color: SutraColors.inkSoft),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(capacityRepositoryProvider).remove(e.id);
                    ref.invalidate(capacityProvider);
                    messenger.showSnackBar(SnackBar(content: Text(s.tr(CapText.removed))));
                  } catch (err) {
                    final x = ApiException.from(err);
                    messenger.showSnackBar(SnackBar(content: Text(s.isHindi ? (x.messageHi ?? x.message) : x.message)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSheet extends ConsumerStatefulWidget {
  const _AddSheet();

  @override
  ConsumerState<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<_AddSheet> {
  CapacityKind _kind = CapacityKind.wedding;
  late DateTime _from = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
  late DateTime _to = _from;
  int? _off;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial, DateTime first) {
    final today = DateUtils.dateOnly(DateTime.now());
    return showDatePicker(context: context, initialDate: initial.isBefore(first) ? first : initial, firstDate: first, lastDate: today.add(const Duration(days: 365)));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final machines = ref.watch(capacityProvider).valueOrNull?.machines ?? 1;
    final off = (_off ?? (_kind == CapacityKind.holiday || _kind == CapacityKind.festival ? machines : 1)).clamp(1, machines);
    final hindi = s.isHindi;
    return SheetForm(
      title: s.tr(CapText.addTitle),
      saveLabel: s.tr(CapText.save),
      onSave: () async {
        final (_, risk) = await ref.read(capacityRepositoryProvider).add(NewDaysOff(kind: _kind, startsOn: _from, endsOn: _to, machinesOff: off, note: _note.text));
        ref.invalidate(capacityProvider);
        ref.invalidate(orderInboxProvider);
        // accepted orders this makes late: named right away (each also got an alert on the home screen)
        if (risk.isEmpty) return s.tr(CapText.saved);
        return '${s.tr(CapText.atRiskTitle)}: ${risk.map((r) => '${r.code} (${r.nowPossible}/${r.promised})').join(', ')}. ${s.tr(CapText.atRiskSub)}';
      },
      children: [
        Text(s.tr(CapText.why), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in CapacityKind.values)
              ChoiceChip(
                avatar: Icon(kindIcon(k), size: 16),
                label: Text(s.tr(kindLabel(k))),
                selected: _kind == k,
                onSelected: (_) => setState(() {
                  _kind = k;
                  _off = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: s.tr(CapText.from),
                value: '${Fmt.shortDate(_from, hindi: hindi)} ${_from.year}',
                onTap: () async {
                  final d = await _pick(_from, DateUtils.dateOnly(DateTime.now()));
                  if (d == null) return;
                  setState(() {
                    _from = d;
                    if (_to.isBefore(d)) _to = d;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: s.tr(CapText.to),
                value: '${Fmt.shortDate(_to, hindi: hindi)} ${_to.year}',
                onTap: () async {
                  final d = await _pick(_to, _from);
                  if (d != null) setState(() => _to = d);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('${s.tr(CapText.howMany)} (${s.tr(CapText.all)}: $machines)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        QtyStepper(value: off.toDouble(), min: 1, onChanged: (v) => setState(() => _off = v.round().clamp(1, machines))),
        const SizedBox(height: 12),
        TextField(controller: _note, maxLength: 120, decoration: InputDecoration(labelText: s.tr(CapText.note), counterText: '')),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.event_outlined)),
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
}
