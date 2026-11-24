import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../../alerts/data/alert_repository.dart';
import '../../alerts/domain/alert_models.dart';
import '../../stock/presentation/material_row.dart';
import '../data/home_repository.dart';
import '../domain/home_models.dart';

/// "Aaj": greeting read aloud, what needs attention, today's ledger page, and the raw-material spools.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final home = ref.watch(homeProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => ref.refresh(homeProvider.future),
          child: AsyncView(
            value: home,
            strings: s,
            onRetry: () => ref.invalidate(homeProvider),
            data: (h) => ListView(
              padding: SutraSpace.page,
              children: [
                _Greeting(home: h, strings: s),
                const SizedBox(height: 16),
                _SpeakCard(strings: s),
                if (h.alerts.isNotEmpty) ...[
                  SectionHeader(s.needsAttention),
                  for (final a in h.alerts) _AlertSlip(alert: a, strings: s),
                ],
                SectionHeader(s.todaysPage),
                _TodaysPage(kpis: h.kpis, strings: s),
                SectionHeader(
                  s.rawMaterial,
                  action: TextButton(onPressed: () => context.go('/stock'), child: Text(s.seeAll)),
                ),
                LedgerCard(
                  padding: const EdgeInsets.fromLTRB(34, 4, 12, 4),
                  ruled: false,
                  child: Column(
                    children: [
                      for (final (i, m) in h.materials.indexed) ...[
                        if (i > 0) const Divider(),
                        MaterialRow(material: m, strings: s, onTap: () => context.go('/stock')),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.home, required this.strings});
  final HomeSummary home;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = home.producer;
    return Row(
      children: [
        InitialsBadge(name: p.name, color: hexColor(p.avatarColor), size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.pick(home.greeting.hi, home.greeting.en), style: SutraType.display(22)),
              Text(
                '${p.businessName} · ${p.city} · ${strings.machinesOf(p.machines, p.industry.machineHi, p.industry.machine)}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        ListenChip(
          label: strings.listen,
          onTap: () => ref.read(speakerProvider).say(strings.pick(home.spoken.hi, home.spoken.en), hindi: strings.isHindi),
        ),
      ],
    );
  }
}

/// The main call to action: speak an entry. Neel, with a little thread stripe — not a generic FAB.
class _SpeakCard extends StatelessWidget {
  const _SpeakCard({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SutraColors.neel,
      borderRadius: const BorderRadius.all(SutraRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/voice'),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SutraColors.haldi, width: 2.5)),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.speakCta, style: SutraType.display(20, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(strings.speakCtaSub, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
            const ThreadStripe(height: 4),
          ],
        ),
      ),
    );
  }
}

class _AlertSlip extends ConsumerWidget {
  const _AlertSlip({required this.alert, required this.strings});
  final AlertItem alert;
  final AppStrings strings;

  (IconData, Color) get _look => switch (alert.kind) {
        'LOW_STOCK' => (Icons.warning_amber_rounded, SutraColors.kumkum),
        'ORDER' => (Icons.shopping_bag_outlined, SutraColors.haldiDeep),
        'PAYMENT' => (Icons.currency_rupee_rounded, SutraColors.sindoor),
        'GST' => (Icons.receipt_long_outlined, SutraColors.sindoor),
        _ => (Icons.info_outline_rounded, SutraColors.neel),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = _look;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: SutraColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(SutraRadius.md),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(SutraRadius.md),
          onTap: alert.route == null
              ? null
              : () {
                  ref.read(alertRepositoryProvider).markRead(alert.id);
                  context.go(alert.route!);
                },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(left: SutraRadius.md))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: color, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(strings.pick(alert.titleHi, alert.title), style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(strings.pick(alert.bodyHi, alert.body), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(Fmt.ago(alert.createdAt, hindi: strings.isHindi), style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Four numbers written like entries on a ledger page, not a grid of tiles.
class _TodaysPage extends StatelessWidget {
  const _TodaysPage({required this.kpis, required this.strings});
  final HomeKpis kpis;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return LedgerCard(
      child: Column(
        children: [
          LedgerLine(label: strings.kpiSales30, sub: strings.invoicesCount(kpis.invoices30d), value: AmountText(kpis.sales30d)),
          LedgerLine(
            label: strings.kpiToReceive,
            value: AmountText(kpis.toReceive, incoming: true),
            onTap: () => context.go('/khata'),
          ),
          LedgerLine(label: strings.kpiToPay, value: AmountText(kpis.toPay, incoming: false), onTap: () => context.go('/khata')),
          LedgerLine(label: strings.kpiStockValue, sub: strings.kpiStockValueSub, value: AmountText(kpis.stockValue)),
          LedgerLine(
            label: strings.kpiOpenOrders,
            sub: strings.newRequests(kpis.newRequests),
            value: Text('${kpis.openOrders}', style: SutraType.figure(18)),
          ),
        ],
      ),
    );
  }
}
