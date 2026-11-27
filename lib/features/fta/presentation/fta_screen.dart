import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/stamp.dart';
import '../data/fta_data.dart';
import '../domain/fta_models.dart';
import 'fta_text.dart';

/// "FTA लाभ" — which India FTA covers a destination, the origin rule of thumb,
/// and how much import duty a consignment saves. A guide + checker + estimator;
/// the real certificate comes from DGFT, not from inside Sutra.
class FtaScreen extends ConsumerStatefulWidget {
  const FtaScreen({super.key});

  @override
  ConsumerState<FtaScreen> createState() => _FtaScreenState();
}

class _FtaScreenState extends ConsumerState<FtaScreen> {
  String? _country;
  double? _invoice;
  double? _normal;
  double? _pref;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final engine = ref.watch(ftaEngineProvider);
    final text = Theme.of(context).textTheme;
    final savings = DutySaving.calc(invoiceValue: _invoice, normalRate: _normal, preferentialRate: _pref);

    return Scaffold(
      appBar: AppBar(title: Text(s.tr(FtaText.title))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: ListView(
              padding: SutraSpace.page,
              children: [
                Text(s.tr(FtaText.titleSub), style: text.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                const SizedBox(height: 14),

                // How the benefit actually works.
                SectionHeader(s.tr(FtaText.howItWorks)),
                LedgerCard(
                  child: Column(
                    children: [
                      _Step(1, s.tr(FtaText.step1)),
                      _Step(2, s.tr(FtaText.step2)),
                      _Step(3, s.tr(FtaText.step3), last: true),
                    ],
                  ),
                ),

                // Destination → agreement checker.
                SectionHeader(s.tr(FtaText.destinationTitle)),
                DropdownButtonFormField<String>(
                  initialValue: _country,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.tr(FtaText.destinationLabel)),
                  items: [
                    for (final d in engine.destinations)
                      DropdownMenuItem(value: d.code, child: Text(s.isHindi ? d.nameHi : d.name)),
                  ],
                  onChanged: (v) => setState(() => _country = v),
                ),
                const SizedBox(height: 12),
                if (_country == null)
                  Text(s.tr(FtaText.destinationHint), style: text.bodySmall)
                else
                  ..._agreementCards(engine.forCountry(_country!), s, text),

                // Duty-savings estimator.
                SectionHeader(s.tr(FtaText.estimatorTitle)),
                Text(s.tr(FtaText.estimatorHint), style: text.bodySmall),
                const SizedBox(height: 10),
                NumberField(
                  label: s.tr(FtaText.invoiceValue),
                  initial: _invoice,
                  prefix: '₹ ',
                  onChanged: (v) => setState(() => _invoice = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NumberField(
                        label: s.tr(FtaText.normalRate),
                        initial: _normal,
                        suffix: '%',
                        onChanged: (v) => setState(() => _normal = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NumberField(
                        label: s.tr(FtaText.prefRate),
                        initial: _pref,
                        suffix: '%',
                        onChanged: (v) => setState(() => _pref = v),
                      ),
                    ),
                  ],
                ),
                if (savings != null) ...[
                  const SizedBox(height: 12),
                  _SavingsCard(savings: savings, strings: s),
                  const SizedBox(height: 6),
                  Text(s.tr(FtaText.estimatorNote), style: text.labelSmall),
                ],

                // Rules of origin, in plain words.
                SectionHeader(s.tr(FtaText.rulesTitle)),
                Text(s.tr(FtaText.rulesNote), style: text.bodyMedium),
                const SizedBox(height: 8),
                Text(s.tr(FtaText.valueAddNote), style: text.labelSmall),

                // First-shipment checklist.
                SectionHeader(s.tr(FtaText.checklistTitle)),
                LedgerCard(
                  child: Column(
                    children: [
                      for (final (i, item) in FtaText.checklist.indexed)
                        _CheckRow(text: s.tr(item), last: i == FtaText.checklist.length - 1),
                    ],
                  ),
                ),

                // Where to apply.
                SectionHeader(s.tr(FtaText.applyTitle)),
                OutlinedButton.icon(
                  onPressed: () => ref.read(linkLauncherProvider).open('https://www.dgft.gov.in/CP/index.jsp'),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(s.tr(FtaText.eCoo)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.read(linkLauncherProvider).open('https://content.dgft.gov.in/Website/2F.pdf'),
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(s.tr(FtaText.approvedExporter)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.read(linkLauncherProvider).open('https://dgft.gov.in'),
                  icon: const Icon(Icons.public_rounded),
                  label: Text(s.tr(FtaText.dgft)),
                ),

                const SizedBox(height: 14),
                Text(s.tr(FtaText.footer), style: text.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _agreementCards(List<FtaAgreement> agreements, AppStrings s, TextTheme text) {
    if (agreements.isEmpty) {
      return [
        Text(
          s.isHindi ? 'इस देश के लिए Sutra की सूची में अभी कोई FTA नहीं मिला।' : 'No FTA for this destination in Sutra\'s list yet.',
          style: text.bodySmall,
        ),
      ];
    }
    return [
      Text(s.tr(FtaText.applies), style: text.titleSmall),
      const SizedBox(height: 8),
      for (final a in agreements)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LedgerCard(
            padding: const EdgeInsets.fromLTRB(36, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(s.isHindi ? a.nameHi : a.name, style: text.titleSmall)),
                    const SizedBox(width: 8),
                    Stamp(
                      s.tr(a.status.inForce ? FtaText.inForce : FtaText.signed),
                      tone: a.status.inForce ? Tone.ok : Tone.low,
                      size: 9,
                      angle: 0,
                    ),
                  ],
                ),
                Text('${a.year}', style: text.bodySmall),
                const SizedBox(height: 10),
                Text(s.tr(FtaText.coverageLabel), style: text.labelSmall),
                Text(s.isHindi ? a.coverageHi : a.coverage, style: text.bodySmall),
                const SizedBox(height: 8),
                Text(s.tr(FtaText.valueAddLabel), style: text.labelSmall),
                Text('≥ ${a.valueAddPct}%', style: SutraType.figure(18, color: SutraColors.sindoorDeep)),
              ],
            ),
          ),
        ),
    ];
  }
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.label, {this.last = false});
  final int n;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x339DB7C9)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: SutraColors.sindoor, shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.text, this.last = false});
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x339DB7C9)))),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: SutraColors.neel),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.savings, required this.strings});
  final DutySaving savings;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return LedgerCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(strings.tr(FtaText.youSave), style: Theme.of(context).textTheme.titleSmall)),
              Text('≈ ${Fmt.qty(savings.savedPct)}%', style: SutraType.figure(18, color: SutraColors.neel)),
            ],
          ),
          const SizedBox(height: 4),
          LedgerLine(label: strings.tr(FtaText.normalDuty), value: AmountText(savings.normalDuty, incoming: false, size: 16)),
          LedgerLine(label: strings.tr(FtaText.prefDuty), value: AmountText(savings.preferentialDuty, incoming: false, size: 16)),
          LedgerLine(label: strings.tr(FtaText.youSave), value: AmountText(savings.saved, incoming: true, size: 20), last: true),
        ],
      ),
    );
  }
}
