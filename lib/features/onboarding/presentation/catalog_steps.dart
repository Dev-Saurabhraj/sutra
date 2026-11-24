import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/spool_gauge.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_controller.dart';
import 'onboarding_steps.dart';
import 'onboarding_text.dart';

/// A tickable card: tap the header to include or leave out an item, edit its numbers below.
class _PickCard extends StatelessWidget {
  const _PickCard({required this.title, required this.include, required this.onToggle, required this.leading, required this.children});

  final String title;
  final bool include;
  final VoidCallback onToggle;
  final Widget leading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SutraMotion.normal,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: include ? SutraColors.card : SutraColors.paper,
        borderRadius: const BorderRadius.all(SutraRadius.md),
        border: Border.all(color: include ? SutraColors.neel : SutraColors.rule, width: include ? 1.8 : 1.2),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: SutraRadius.md),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
                  Checkbox(value: include, onChanged: (_) => onToggle(), activeColor: SutraColors.neel),
                ],
              ),
            ),
          ),
          if (include) Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: Column(children: children)),
        ],
      ),
    );
  }
}

class MaterialsStep extends ConsumerWidget {
  const MaterialsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final mats = ref.watch(onboardingControllerProvider.select((st) => st.draft.materials));
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    void set(int i, DraftMaterial m) => ctrl.update((d) => d.copyWith(materials: [...d.materials]..[i] = m));

    return StepFrame(
      title: s.tr(OnbText.materialsTitle),
      body: s.tr(OnbText.materialsBody),
      children: [
        for (final (i, m) in mats.indexed)
          _PickCard(
            title: s.pick(m.nameHi, m.name),
            include: m.include,
            onToggle: () => set(i, m.copyWith(include: !m.include)),
            leading: SpoolGauge(fill: m.stock > 0 ? 0.8 : 0.1, tone: m.include ? Tone.ok : Tone.neutral, size: const Size(26, 32)),
            children: [
              Row(
                children: [
                  Expanded(child: NumberField(label: s.tr(OnbText.inHand), suffix: m.unit, initial: m.stock == 0 ? null : m.stock, onChanged: (v) => set(i, m.copyWith(stock: v ?? 0)))),
                  const SizedBox(width: 12),
                  Expanded(child: NumberField(label: '${s.tr(OnbText.costPer)} / ${m.unit}', prefix: '₹ ', initial: m.cost, onChanged: (v) => set(i, m.copyWith(cost: v ?? 0)))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: m.supplierName,
                      decoration: InputDecoration(labelText: s.tr(OnbText.supplier)),
                      onChanged: (v) => set(i, m.copyWith(supplierName: v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: m.supplierPhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: s.tr(OnbText.supplierPhone)),
                      onChanged: (v) => set(i, m.copyWith(supplierPhone: v)),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class ProductsStep extends ConsumerWidget {
  const ProductsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final d = ref.watch(onboardingControllerProvider.select((st) => st.draft));
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    void set(int i, DraftProduct p) => ctrl.update((d) => d.copyWith(products: [...d.products]..[i] = p));
    final matByKey = {for (final m in d.materials) m.key: m};

    return StepFrame(
      title: s.tr(OnbText.productsTitle),
      body: s.tr(OnbText.productsBody),
      children: [
        for (final (i, p) in d.products.indexed)
          _PickCard(
            title: s.pick(p.nameHi, p.name),
            include: p.include,
            onToggle: () => set(i, p.copyWith(include: !p.include)),
            leading: const Icon(Icons.checkroom_outlined, color: SutraColors.sindoor),
            children: [
              Row(
                children: [
                  Expanded(child: NumberField(label: s.tr(OnbText.price), prefix: '₹ ', initial: p.price, onChanged: (v) => set(i, p.copyWith(price: v ?? 0)))),
                  const SizedBox(width: 12),
                  Expanded(child: NumberField(label: s.tr(OnbText.readyNow), decimals: false, initial: p.stock == 0 ? null : p.stock, onChanged: (v) => set(i, p.copyWith(stock: (v ?? 0).round())))),
                ],
              ),
              if (!d.isTrader && p.recipe.isNotEmpty) ...[
                const SizedBox(height: 10),
                _RecipeLine(recipe: p.recipe, materials: matByKey, strings: s),
              ],
            ],
          ),
      ],
    );
  }
}

/// "Each piece uses: 0.25 kg silk · 0.3 kg cotton" — the recipe, so stock goes down by itself later.
class _RecipeLine extends StatelessWidget {
  const _RecipeLine({required this.recipe, required this.materials, required this.strings});

  final Map<String, double> recipe;
  final Map<String, DraftMaterial> materials;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final parts = [
      for (final e in recipe.entries)
        if (materials[e.key]?.include ?? false) '${Fmt.qty(e.value)} ${materials[e.key]!.unit} ${strings.pick(materials[e.key]!.nameHi, materials[e.key]!.name)}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: SutraColors.neelWash, borderRadius: BorderRadius.all(SutraRadius.sm)),
      child: Text('${strings.tr(OnbText.usesPerPiece)}: ${parts.join(' · ')}', style: const TextStyle(color: SutraColors.neelDeep, fontSize: 13, height: 1.4)),
    );
  }
}

class TeamStep extends ConsumerStatefulWidget {
  const TeamStep({super.key});

  @override
  ConsumerState<TeamStep> createState() => _TeamStepState();
}

class _TeamStepState extends ConsumerState<TeamStep> {
  final _name = TextEditingController();
  String _wage = 'DAILY';
  double _rate = 400;

  /// Start from how this trade usually pays (weavers by the piece, potters by the day…).
  @override
  void initState() {
    super.initState();
    final key = ref.read(onboardingControllerProvider).draft.industryKey;
    final template = ref.read(industriesProvider).valueOrNull?.where((t) => t.key == key).firstOrNull;
    if (template != null) _wage = template.wageType;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _add() {
    if (_name.text.trim().isEmpty || _rate <= 0) return;
    final w = DraftWorker(name: _name.text.trim(), wageType: _wage, rate: _rate);
    ref.read(onboardingControllerProvider.notifier).update((d) => d.copyWith(workers: [...d.workers, w]));
    setState(_name.clear);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final workers = ref.watch(onboardingControllerProvider.select((st) => st.draft.workers));
    final text = Theme.of(context).textTheme;
    String per(String w) => s.tr(switch (w) { 'PIECE' => OnbText.perPiece, 'MONTHLY' => OnbText.perMonth, _ => OnbText.perDay });

    return StepFrame(
      title: s.tr(OnbText.teamTitle),
      body: s.tr(OnbText.teamBody),
      children: [
        if (workers.isEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(s.tr(OnbText.noTeam), style: text.bodySmall))
        else
          for (final (i, w) in workers.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: SutraColors.neelWash, child: Text(Fmt.initials(w.name), style: const TextStyle(color: SutraColors.neel, fontWeight: FontWeight.w700))),
              title: Text(w.name, style: text.titleSmall),
              subtitle: Text('${Fmt.inr(w.rate)} ${per(w.wageType)}'),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => ref.read(onboardingControllerProvider.notifier).update((d) => d.copyWith(workers: [...d.workers]..removeAt(i))),
              ),
            ),
        const Divider(height: 24),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(OnbText.workerName))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final (k, label) in [('DAILY', OnbText.wageDaily), ('PIECE', OnbText.wagePiece), ('MONTHLY', OnbText.wageMonthly)])
              ChoiceChip(label: Text(s.tr(label)), selected: _wage == k, onSelected: (_) => setState(() => _wage = k)),
          ],
        ),
        const SizedBox(height: 8),
        NumberField(key: ValueKey(_wage), label: per(_wage), prefix: '₹ ', initial: _rate, onChanged: (v) => _rate = v ?? 0),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.person_add_alt_1_outlined), label: Text(s.tr(OnbText.addWorker))),
      ],
    );
  }
}
