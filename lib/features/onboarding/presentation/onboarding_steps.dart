import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/gst/gstin.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/art/flow_pipeline.dart';
import '../../../design/art/industry_scenes.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/form_bits.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_models.dart';
import 'catalog_steps.dart';
import 'onboarding_controller.dart';
import 'onboarding_text.dart';

Widget stepView(OnbStep step) => switch (step) {
      OnbStep.welcome => const WelcomeStep(),
      OnbStep.you => const YouStep(),
      OnbStep.trade => const TradeStep(),
      OnbStep.place => const PlaceStep(),
      OnbStep.gst => const GstStep(),
      OnbStep.materials => const MaterialsStep(),
      OnbStep.products => const ProductsStep(),
      OnbStep.team => const TeamStep(),
      OnbStep.done => const DoneStep(),
    };

/// Common frame for a step: an optional illustration, a question as the title, then the content.
class StepFrame extends StatelessWidget {
  const StepFrame({super.key, required this.title, this.body, this.art, required this.children});

  final String title;
  final String? body;
  final Widget? art;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        if (art != null) SizedBox(height: 150, child: art),
        Text(title, style: SutraType.display(26)),
        if (body != null) ...[
          const SizedBox(height: 6),
          Text(body!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
        ],
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

List<FlowStation> flowStations(AppStrings s, {bool trader = false}) => [
      FlowStation(icon: Icons.local_shipping_outlined, label: s.tr(OnbText.flowSupplier), value: '1'),
      FlowStation(icon: Icons.inventory_2_outlined, label: s.tr(OnbText.flowRaw), value: '2', enabled: !trader),
      FlowStation(icon: Icons.handyman_outlined, label: s.tr(OnbText.flowMaking), value: '3', enabled: !trader),
      FlowStation(icon: Icons.checkroom_outlined, label: s.tr(OnbText.flowReady), value: '4'),
      FlowStation(icon: Icons.storefront_outlined, label: s.tr(OnbText.flowClient), value: '5'),
    ];

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return StepFrame(
      art: const IndustryArt('handloom'),
      title: s.tr(OnbText.welcomeTitle),
      body: s.tr(OnbText.welcomeBody),
      children: [
        Text(s.tr(OnbText.howItWorks), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        FlowPipeline(stations: flowStations(s)),
      ],
    );
  }
}

class YouStep extends ConsumerWidget {
  const YouStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final d = ref.watch(onboardingControllerProvider.select((st) => st.draft));
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    return StepFrame(
      title: s.tr(OnbText.youTitle),
      children: [
        TextFormField(
          initialValue: d.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: s.tr(OnbText.yourName)),
          onChanged: (v) => ctrl.update((d) => d.copyWith(name: v)),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: d.businessName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: s.tr(OnbText.businessName)),
          onChanged: (v) => ctrl.update((d) => d.copyWith(businessName: v)),
        ),
        const SizedBox(height: 24),
        Text(s.tr(OnbText.languageQ), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        ChoiceCards<AppLang>(
          columns: 2,
          options: [for (final l in AppLang.values) ChoiceOption(value: l, title: l.label, icon: Icons.translate_rounded)],
          selected: s.lang,
          onSelect: (l) => ref.read(langProvider.notifier).set(l),
        ),
      ],
    );
  }
}

class TradeStep extends ConsumerWidget {
  const TradeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final d = ref.watch(onboardingControllerProvider.select((st) => st.draft));
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    return StepFrame(
      title: s.tr(OnbText.tradeTitle),
      children: [
        AsyncView<List<IndustryTemplate>>(
          value: ref.watch(industriesProvider),
          strings: s,
          onRetry: () => ref.invalidate(industriesProvider),
          data: (list) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [for (final t in list) _IndustryTile(template: t, strings: s, selected: d.industryKey == t.key, onTap: () => ctrl.chooseIndustry(t))],
          ),
        ),
        const SizedBox(height: 22),
        Text(s.tr(OnbText.howYouWork), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        ChoiceCards<bool>(
          options: [
            ChoiceOption(value: false, title: s.tr(OnbText.maker), subtitle: s.tr(OnbText.makerSub), icon: Icons.handyman_outlined),
            ChoiceOption(value: true, title: s.tr(OnbText.trader), subtitle: s.tr(OnbText.traderSub), icon: Icons.storefront_outlined),
          ],
          selected: d.isTrader,
          onSelect: (v) => ctrl.update((d) => d.copyWith(isTrader: v)),
        ),
      ],
    );
  }
}

/// An industry as a little animated scene: the loom weaves, the diya flickers…
class _IndustryTile extends StatelessWidget {
  const _IndustryTile({required this.template, required this.strings, required this.selected, required this.onTap});

  final IndustryTemplate template;
  final AppStrings strings;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SutraColors.sindoorWash : SutraColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(SutraRadius.lg),
        side: BorderSide(color: selected ? SutraColors.sindoor : SutraColors.rule, width: selected ? 2.2 : 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(child: IndustryArt(template.key, semanticLabel: strings.pick(template.nameHi, template.name))),
              const SizedBox(height: 6),
              Text(strings.pick(template.nameHi, template.name), textAlign: TextAlign.center, maxLines: 2, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceStep extends ConsumerWidget {
  const PlaceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final d = ref.watch(onboardingControllerProvider.select((st) => st.draft));
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final industry = ref.watch(industriesProvider).valueOrNull?.where((t) => t.key == d.industryKey).firstOrNull;
    final machine = industry == null ? '' : s.pick(industry.machineHi, industry.machine);
    return StepFrame(
      art: d.industryKey == null ? null : IndustryArt(d.industryKey!),
      title: s.tr(OnbText.placeTitle),
      children: [
        TextFormField(
          initialValue: d.city,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: s.tr(OnbText.city)),
          onChanged: (v) => ctrl.update((d) => d.copyWith(city: v)),
        ),
        const SizedBox(height: 14),
        StatePickerField(label: s.tr(OnbText.state), value: d.state, onChanged: (v) => ctrl.update((d) => d.copyWith(state: v))),
        const SizedBox(height: 24),
        Text(s.isHindi ? 'कितने $machine हैं?' : 'How many ${machine}s?', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        QtyStepper(value: d.machines.toDouble(), min: 1, onChanged: (v) => ctrl.update((d) => d.copyWith(machines: v.round()))),
        const SizedBox(height: 6),
        Text(s.tr(OnbText.capacityHint), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// 36 states are too many for a dropdown on a small phone: tap, type a few letters, pick.
class StatePickerField extends StatelessWidget {
  const StatePickerField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showSutraSheet<String>(context, const _StateSearch());
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.search_rounded)),
        isEmpty: value == null,
        child: value == null ? null : Text(value!, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

class _StateSearch extends StatefulWidget {
  const _StateSearch();

  @override
  State<_StateSearch> createState() => _StateSearchState();
}

class _StateSearchState extends State<_StateSearch> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final matches = gstStates.keys.where((st) => st.toLowerCase().contains(_q.toLowerCase())).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(autofocus: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded)), onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 8),
        for (final st in matches.take(8))
          ListTile(contentPadding: EdgeInsets.zero, title: Text(st), onTap: () => Navigator.of(context).pop(st)),
      ],
    );
  }
}

class GstStep extends ConsumerWidget {
  const GstStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final d = ref.watch(onboardingControllerProvider.select((st) => st.draft));
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final problem = d.gstin.isEmpty ? null : checkGstin(d.gstin, state: d.state);
    final problemText = switch (problem) {
      GstinProblem.length => s.tr(OnbText.gstinLength),
      GstinProblem.format || GstinProblem.state => s.tr(OnbText.gstinFormat),
      GstinProblem.checkDigit => s.tr(OnbText.gstinCheck),
      GstinProblem.wrongState => s.tr(OnbText.gstinState),
      null => null,
    };
    return StepFrame(
      title: s.tr(OnbText.gstTitle),
      body: s.tr(OnbText.gstBody),
      children: [
        ChoiceCards<GstChoice>(
          options: [
            ChoiceOption(value: GstChoice.regular, title: s.tr(OnbText.gstRegular), subtitle: s.tr(OnbText.gstRegularSub), icon: Icons.receipt_long_outlined),
            ChoiceOption(value: GstChoice.composition, title: s.tr(OnbText.gstComposition), subtitle: s.tr(OnbText.gstCompositionSub), icon: Icons.receipt_outlined),
            ChoiceOption(value: GstChoice.unregistered, title: s.tr(OnbText.gstNone), subtitle: s.tr(OnbText.gstNoneSub), icon: Icons.do_not_disturb_on_outlined),
          ],
          selected: d.gst,
          onSelect: (g) => ctrl.update((d) => d.copyWith(gst: g)),
        ),
        if (d.gst != GstChoice.unregistered) ...[
          const SizedBox(height: 4),
          TextFormField(
            initialValue: d.gstin,
            textCapitalization: TextCapitalization.characters,
            maxLength: 15,
            style: SutraType.figure(18).copyWith(letterSpacing: 1.5),
            decoration: InputDecoration(
              labelText: s.tr(OnbText.gstin),
              errorText: problemText,
              helperText: d.gstin.length == 15 && problem == null ? s.tr(OnbText.gstinOk) : null,
              helperStyle: const TextStyle(color: SutraColors.neel, fontWeight: FontWeight.w600),
            ),
            onChanged: (v) => ctrl.update((d) => d.copyWith(gstin: v)),
          ),
        ],
        const SizedBox(height: 14),
        TextFormField(
          initialValue: d.udyam,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: s.tr(OnbText.udyam), helperText: s.tr(OnbText.udyamHint), helperMaxLines: 2),
          onChanged: (v) => ctrl.update((d) => d.copyWith(udyam: v)),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: d.upi,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: s.tr(OnbText.upi), helperText: s.tr(OnbText.upiHint), helperMaxLines: 2),
          onChanged: (v) => ctrl.update((d) => d.copyWith(upi: v)),
        ),
      ],
    );
  }
}

class DoneStep extends ConsumerWidget {
  const DoneStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final d = ref.watch(onboardingControllerProvider.select((st) => st.draft));
    final text = Theme.of(context).textTheme;
    Widget count(int n, T label) => Expanded(
          child: Column(children: [Text('$n', style: SutraType.figure(30, color: SutraColors.sindoor)), Text(s.tr(label), style: text.bodySmall)]),
        );
    return StepFrame(
      art: IndustryArt(d.industryKey ?? 'other'),
      title: s.tr(OnbText.doneTitle),
      body: s.tr(OnbText.doneBody),
      children: [
        FlowPipeline(stations: flowStations(s, trader: d.isTrader)),
        const SizedBox(height: 16),
        Row(
          children: [
            if (!d.isTrader) count(d.materials.where((m) => m.include).length, OnbText.materials),
            count(d.products.where((p) => p.include).length, OnbText.products),
            count(d.workers.length, OnbText.workers),
          ],
        ),
      ],
    );
  }
}
