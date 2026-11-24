import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/art/scan_thread.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/parchi.dart';
import '../../../design/widgets/stamp.dart';
import '../data/bill_repository.dart';
import '../domain/bill_models.dart';
import 'bill_controller.dart';
import 'bill_text.dart';

/// Snap a supplier bill: Sutra reads it, checks the GSTIN and the arithmetic,
/// matches each line to a material, and shows the tax credit — then waits for "yes".
class BillScreen extends ConsumerWidget {
  const BillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final st = ref.watch(billControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(BillText.title))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: ListView(
              padding: SutraSpace.page,
              children: [
                if (st.phase != BillPhase.pick) _Photo(state: st),
                if (st.phase == BillPhase.reading)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(s.tr(BillText.reading), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
                  ),
                if (st.error != null) ...[const SizedBox(height: 12), _Note(text: s.isHindi ? (st.error!.messageHi ?? st.error!.message) : st.error!.message)],
                switch (st.phase) {
                  BillPhase.pick => _PickView(strings: s),
                  BillPhase.reading => const SizedBox.shrink(),
                  BillPhase.draft || BillPhase.saving => _DraftSlip(state: st, strings: s),
                  BillPhase.saved => _SavedSlip(saved: st.saved!, strings: s),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.state});
  final BillState state;

  @override
  Widget build(BuildContext context) {
    final image = state.photo != null
        ? Image.memory(state.photo!.bytes, fit: BoxFit.cover)
        : Image.asset('assets/samples/bill-${state.sampleKey}.jpg', fit: BoxFit.cover);
    final reading = state.phase == BillPhase.reading;
    return ClipRRect(
      borderRadius: const BorderRadius.all(SutraRadius.md),
      child: AnimatedContainer(
        duration: SutraMotion.normal,
        height: reading ? 380 : 140,
        child: ScanThread(active: reading, child: SizedBox.expand(child: image)),
      ),
    );
  }
}

class _PickView extends ConsumerWidget {
  const _PickView({required this.strings});
  final AppStrings strings;

  Future<void> _pick(WidgetRef ref, ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 2000, imageQuality: 82);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final type = file.mimeType ?? (file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
    await ref.read(billControllerProvider.notifier).readPhoto(BillPhoto(bytes: bytes, mediaType: type));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final info = ref.watch(billSamplesProvider).valueOrNull;
    final aiOn = info?.aiEnabled ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr(BillText.subtitle), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _BigButton(icon: Icons.photo_camera_outlined, label: s.tr(BillText.camera), color: SutraColors.sindoor, onTap: aiOn ? () => _pick(ref, ImageSource.camera) : null)),
            const SizedBox(width: 12),
            Expanded(child: _BigButton(icon: Icons.photo_library_outlined, label: s.tr(BillText.gallery), color: SutraColors.neel, onTap: aiOn ? () => _pick(ref, ImageSource.gallery) : null)),
          ],
        ),
        if (info != null && !aiOn) ...[const SizedBox(height: 12), _Note(text: s.tr(BillText.aiOff))],
        const SizedBox(height: 22),
        Text(s.tr(BillText.samples), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: info?.samples.length ?? 0,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final sample = info!.samples[i];
              return Semantics(
                button: true,
                label: s.pick(sample.labelHi, sample.label),
                child: GestureDetector(
                  onTap: () => ref.read(billControllerProvider.notifier).readSample(sample.key),
                  child: SizedBox(
                    width: 132,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(SutraRadius.sm),
                          child: Image.asset(sample.asset, height: 132, width: 132, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 6),
                        Text(s.pick(sample.labelHi, sample.label), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.icon, required this.label, required this.color, this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Material(
      color: on ? color : SutraColors.rule,
      borderRadius: const BorderRadius.all(SutraRadius.lg),
      child: InkWell(
        borderRadius: const BorderRadius.all(SutraRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            children: [
              Icon(icon, color: on ? Colors.white : SutraColors.inkSoft, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: on ? Colors.white : SutraColors.inkSoft, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftSlip extends ConsumerWidget {
  const _DraftSlip({required this.state, required this.strings});
  final BillState state;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final d = state.draft!;
    final ctrl = ref.read(billControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final saving = state.phase == BillPhase.saving;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Parchi(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.tr(d.readByAi ? BillText.readBySutra : BillText.sampleRead), style: text.labelSmall),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.supplierName, style: SutraType.display(20)),
                      Text('${s.tr(BillText.billNo)} ${d.billNo} · ${d.billDate}', style: text.bodySmall),
                      if (!d.supplierKnown) Text(s.tr(BillText.newSupplier), style: const TextStyle(color: SutraColors.neel, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Stamp(
                  s.tr(d.supplierGstin.isEmpty ? BillText.noGstin : (d.gstinValid ? BillText.gstinOk : BillText.gstinBad)),
                  tone: d.gstinValid ? Tone.ok : Tone.critical,
                  size: 10,
                ),
              ],
            ),
            if (d.supplierGstin.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(d.supplierGstin, style: SutraType.figure(13, color: d.gstinValid ? SutraColors.inkSoft : SutraColors.kumkum).copyWith(letterSpacing: 1.2)),
              ),
            const SizedBox(height: 14),
            Text(s.tr(BillText.items), style: text.titleSmall),
            for (final (i, line) in d.lines.indexed) _LineEditor(line: line, value: state.choices[i], materials: d.materials, strings: s, onChanged: (v) => ctrl.choose(i, v)),
            const SizedBox(height: 12),
            LedgerCard(
              padding: const EdgeInsets.fromLTRB(34, 2, 12, 2),
              child: Column(
                children: [
                  LedgerLine(label: s.tr(BillText.taxable), value: AmountText(d.taxable, size: 16)),
                  if (d.igst > 0)
                    LedgerLine(label: 'IGST', value: AmountText(d.igst, size: 16))
                  else ...[
                    LedgerLine(label: 'CGST', value: AmountText(d.cgst, size: 16)),
                    LedgerLine(label: 'SGST', value: AmountText(d.sgst, size: 16)),
                  ],
                  LedgerLine(label: s.tr(BillText.total), value: AmountText(d.total, size: 20), last: true),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Stamp(s.tr(d.mathOk ? BillText.mathOk : BillText.mathBad), tone: d.mathOk ? Tone.ok : Tone.low, size: 10),
                const Spacer(),
                Text(s.tr(d.gstinValid ? BillText.itc : BillText.itcAtRisk), style: text.bodySmall),
                const SizedBox(width: 6),
                AmountText(d.itc, size: 17, incoming: d.gstinValid ? true : false),
              ],
            ),
            if (!d.mathOk) _Hint(text: s.tr(BillText.mathBadHint)),
            if (!d.gstinValid) _Hint(text: s.tr(BillText.itcAtRiskHint), color: SutraColors.kumkum),
            const SizedBox(height: 14),
            Text(s.tr(BillText.shallISave), style: SutraType.display(20)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: saving ? null : ctrl.reset, child: Text(s.tr(BillText.wrong)))),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: state.canSave && !saving ? ctrl.save : null,
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text(state.canSave ? s.tr(BillText.save) : s.tr(BillText.pickMaterial)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One bill line, with a picker for which material it is (Sutra's guess preselected).
class _LineEditor extends StatelessWidget {
  const _LineEditor({required this.line, required this.value, required this.materials, required this.strings, required this.onChanged});
  final BillLine line;
  final String? value;
  final List<MaterialChoice> materials;
  final AppStrings strings;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: SutraColors.paper, borderRadius: BorderRadius.all(SutraRadius.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(line.description, style: text.titleSmall),
          Text('${Fmt.qty(line.qty)} ${line.unit} × ${Fmt.inr(line.rate)} = ${Fmt.inr(line.amount)}${line.hsn.isEmpty ? '' : ' · HSN ${line.hsn}'}', style: text.bodySmall),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: strings.tr(BillText.whichMaterial), isDense: true),
            items: [
              DropdownMenuItem(value: null, child: Text(strings.tr(BillText.skip))),
              for (final m in materials) DropdownMenuItem(value: m.id, child: Text('${strings.pick(m.nameHi, m.name)} (${m.unit})')),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SavedSlip extends StatelessWidget {
  const _SavedSlip({required this.saved, required this.strings});
  final BillSaved saved;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Parchi(
        color: const Color(0xFFF1F8F6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: Stamp(s.tr(BillText.saved), tone: Tone.ok, thunk: true, size: 15)),
            const SizedBox(height: 12),
            Text(saved.supplier, style: text.titleSmall),
            for (final u in saved.updates)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, color: SutraColors.neel, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${s.pick(u.nameHi, u.name)} +${Fmt.qty(u.qty)} ${u.unit} → ${Fmt.qty(u.stock)} ${u.unit}', style: text.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(s.tr(saved.itcAtRisk ? BillText.itcAtRisk : BillText.itc), style: text.bodySmall),
                const SizedBox(width: 6),
                AmountText(saved.itc, size: 17, incoming: !saved.itcAtRisk),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Consumer(builder: (context, ref, _) => OutlinedButton(onPressed: ref.read(billControllerProvider.notifier).reset, child: Text(s.tr(BillText.another))))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: () => context.pushReplacement('/gst'), child: Text(s.tr(BillText.seeGst)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: SutraColors.haldiWash, borderRadius: BorderRadius.all(SutraRadius.sm)),
        child: Text(text, style: const TextStyle(color: SutraColors.haldiDeep, fontSize: 13.5, height: 1.4)),
      );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.color = SutraColors.haldiDeep});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: TextStyle(color: color, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600)),
      );
}
