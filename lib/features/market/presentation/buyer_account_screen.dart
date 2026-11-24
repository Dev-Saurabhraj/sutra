import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../../auth/presentation/session_controller.dart';
import 'market_text.dart';

/// The buyer's business as makers will bill it: name, place (decides IGST vs CGST + SGST), GSTIN.
class BuyerAccountScreen extends ConsumerWidget {
  const BuyerAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final me = switch (ref.watch(sessionControllerProvider).valueOrNull) { SignedIn(:final me) => me, _ => null };
    final b = me?.buyer;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(MarketText.navAccount))),
      body: SafeArea(
        child: ListView(
          padding: SutraSpace.page,
          children: [
            if (b != null) ...[
              Row(
                children: [
                  InitialsBadge(name: b.name, color: SutraColors.neel, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.business, style: SutraType.display(20)),
                        Text('${b.name} · ${b.phone}', style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const ThreadStripe(radius: 2),
              SectionHeader(s.tr(MarketText.yourBusiness)),
              LedgerCard(
                child: Column(
                  children: [
                    LedgerLine(label: s.tr(MarketText.city), value: Text(b.city, style: text.titleSmall)),
                    LedgerLine(label: s.tr(MarketText.state), value: Text(b.state, style: text.titleSmall)),
                    LedgerLine(label: 'GSTIN', value: Text(b.gstin ?? '—', style: SutraType.figure(14)), last: true),
                  ],
                ),
              ),
              if (b.gstin == null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.tr(MarketText.buyerGstinMissing), style: text.bodySmall?.copyWith(color: SutraColors.haldiDeep))),
            ],
            SectionHeader(s.language),
            ChoiceCards<AppLang>(
              columns: 2,
              options: [for (final l in AppLang.values) ChoiceOption(value: l, title: l.label, icon: Icons.translate_rounded)],
              selected: s.lang,
              onSelect: (l) => ref.read(langProvider.notifier).set(l),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded),
              label: Text(s.logout),
              style: OutlinedButton.styleFrom(foregroundColor: SutraColors.kumkum),
            ),
          ],
        ),
      ),
    );
  }
}
