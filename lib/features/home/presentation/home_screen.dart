import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/art/balance_scale.dart';
import '../../../design/art/flow_pipeline.dart';
import '../../../design/art/industry_scenes.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/stamp.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../../alerts/data/alert_repository.dart';
import '../../alerts/domain/alert_models.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inventory/presentation/inventory_text.dart';
import '../../labour/presentation/labour_text.dart';
import '../../bills/presentation/bill_text.dart';
import '../../gst/presentation/gst_text.dart';
import '../../catalog/presentation/catalog_text.dart';
import '../../orders/presentation/order_text.dart';
import '../../voice/domain/voice_examples.dart';
import '../../../core/l10n/common_text.dart';
import '../../../design/widgets/form_bits.dart';
import '../../profile/presentation/reach_settings.dart';
import '../../shell/reach.dart';
import '../data/home_repository.dart';
import '../domain/home_models.dart';

/// "Aaj": the business at a glance — a living picture of the trade, money on a tarazu,
/// goods on a thread, the team's wages. Numbers and pictures first, sentences last.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final helper = ref.watch(helperModeProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => ref.refresh(homeProvider.future),
          child: AsyncView<HomeSummary>(
            value: ref.watch(homeProvider),
            strings: s,
            onRetry: () => ref.invalidate(homeProvider),
            data: (h) => ListView(
              padding: SutraSpace.page,
              children: [
                if (helper) ...[const _HelperBanner(), const SizedBox(height: 12)],
                _Hero(home: h, strings: s),
                if (!helper && h.alerts.isNotEmpty) ...[const SizedBox(height: 14), _AlertStrip(alerts: h.alerts, strings: s)],
                if (!helper) ...[const SizedBox(height: 14), _MoneyCard(home: h, strings: s)],
                const SizedBox(height: 14),
                _OrdersCard(kpis: h.kpis, strings: s),
                const SizedBox(height: 14),
                _FlowCard(flow: h.flow, strings: s),
                if (!helper && h.labour.workers > 0) ...[const SizedBox(height: 14), _TeamCard(labour: h.labour, strings: s)],
                const SizedBox(height: 14),
                _InputTiles(strings: s, example: VoiceExamples.forIndustry(h.producer.industry.key).first),
                if (!helper && h.gst.registered) ...[const SizedBox(height: 14), _GstCard(gst: h.gst, strings: s)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper (munim) mode is on: say so, and let the owner unlock with the PIN.
class _HelperBanner extends ConsumerWidget {
  const _HelperBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Material(
      color: SutraColors.haldiWash,
      borderRadius: const BorderRadius.all(SutraRadius.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.supervisor_account_outlined, color: SutraColors.haldiDeep),
            const SizedBox(width: 10),
            Expanded(child: Text(s.tr(CommonText.helperOn), style: const TextStyle(fontWeight: FontWeight.w800, color: SutraColors.haldiDeep))),
            TextButton.icon(
              onPressed: () => showSutraSheet<void>(context, const PinSheet(start: false)),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(s.tr(CommonText.unlock)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Routes that open on top of the tabs (back returns home); everything else switches tab.
const _fullScreen = ['/gst', '/bill', '/order', '/catalog', '/invoice', '/prices', '/capacity', '/schemes'];

/// The trade, alive: the producer's own industry scene with the greeting.
class _Hero extends ConsumerWidget {
  const _Hero({required this.home, required this.strings});
  final HomeSummary home;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = home.producer;
    return ClipRRect(
      borderRadius: const BorderRadius.all(SutraRadius.lg),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF7EA), Color(0xFFF6E7D3)]),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 168,
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 4, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => ref.read(helperModeProvider) ? null : context.go('/profile'),
                            child: InitialsBadge(name: p.name, color: hexColor(p.avatarColor), size: 40),
                          ),
                          const Spacer(),
                          Text(strings.pick(home.greeting.hi, home.greeting.en), style: SutraType.display(22), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(p.businessName, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                  Expanded(flex: 5, child: Padding(padding: const EdgeInsets.fromLTRB(0, 10, 10, 6), child: IndustryArt(p.industry.key))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  ListenChip(
                    label: strings.listen,
                    onTap: () => ref.read(speakerProvider).say(strings.pick(home.spoken.hi, home.spoken.en), hindi: strings.isHindi),
                  ),
                  const Spacer(),
                  Text('${p.industry.emoji} ${strings.machinesOf(p.machines, p.industry.machineHi, p.industry.machine)}', style: Theme.of(context).textTheme.labelMedium),
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

/// Alerts as small tappable chips, not paragraphs.
class _AlertStrip extends ConsumerWidget {
  const _AlertStrip({required this.alerts, required this.strings});
  final List<AlertItem> alerts;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: alerts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final a = alerts[i];
          final (icon, color) = switch (a.kind) {
            'LOW_STOCK' => (Icons.warning_amber_rounded, SutraColors.kumkum),
            'ORDER' => (Icons.shopping_bag_outlined, SutraColors.haldiDeep),
            'PAYMENT' => (Icons.currency_rupee_rounded, SutraColors.sindoor),
            'GST' => (Icons.receipt_long_outlined, SutraColors.kumkum),
            'PRICE' => (Icons.trending_up_rounded, SutraColors.kumkum),
            _ => (Icons.info_outline_rounded, SutraColors.neel),
          };
          return ActionChip(
            avatar: Icon(icon, color: color, size: 18),
            label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(strings.pick(a.titleHi, a.title), overflow: TextOverflow.ellipsis)),
            backgroundColor: SutraColors.card,
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            onPressed: a.route == null
                ? null
                : () {
                    ref.read(alertRepositoryProvider).markRead(a.id);
                    final route = a.route == '/stock' ? '/inventory' : a.route!;
                    // full-screen tasks open on top (back returns home); tabs switch in place
                    if (_fullScreen.any(route.startsWith)) {
                      context.push(route);
                    } else {
                      context.go(route);
                    }
                  },
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: SutraColors.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(SutraRadius.lg), side: BorderSide(color: SutraColors.rule)),
        child: InkWell(borderRadius: const BorderRadius.all(SutraRadius.lg), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: child)),
      );
}

/// Money on a tarazu: लेना on one pan, देना on the other — and last 30 days' sales underneath.
class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.home, required this.strings});
  final HomeSummary home;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final k = home.kpis;
    final text = Theme.of(context).textTheme;
    return _Card(
      onTap: () => context.go('/khata'),
      child: Row(
        children: [
          BalanceScale(receive: k.toReceive, pay: k.toPay, size: const Size(120, 84)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MoneyLine(label: strings.kpiToReceive, child: AmountText(k.toReceive, size: 20, incoming: true)),
                _MoneyLine(label: strings.kpiToPay, child: AmountText(k.toPay, size: 20, incoming: false)),
                const SizedBox(height: 4),
                Text('${strings.kpiSales30}: ${Fmt.inr(k.sales30d)}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          child,
        ],
      );
}

/// Goods on a thread: the same five stations as the inventory screen; tapping one opens it there.
class _FlowCard extends ConsumerWidget {
  const _FlowCard({required this.flow, required this.strings});
  final HomeFlow flow;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    return _Card(
      onTap: () => context.go('/inventory'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.tr(InvText.title), style: SutraType.display(18)),
          const SizedBox(height: 10),
          FlowPipeline(
            compact: true,
            stations: [
              FlowStation(icon: Icons.local_shipping_outlined, label: s.tr(InvText.supplier), value: '${flow.suppliers}'),
              FlowStation(icon: Icons.inventory_2_outlined, label: s.tr(InvText.raw), value: '${flow.rawItems}', alert: flow.rawLow > 0, enabled: !flow.isTrader),
              FlowStation(icon: Icons.handyman_outlined, label: s.tr(InvText.making), value: Fmt.qty(flow.making), enabled: !flow.isTrader),
              FlowStation(icon: Icons.checkroom_outlined, label: s.tr(InvText.ready), value: '${flow.readyUnits}'),
              FlowStation(icon: Icons.storefront_outlined, label: s.tr(InvText.client), value: '${flow.clients}'),
            ],
            onTap: (i) {
              ref.read(selectedStationProvider.notifier).state = Station.values[i];
              context.go('/inventory');
            },
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.labour, required this.strings});
  final HomeLabour labour;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return _Card(
      onTap: () => context.go('/labour'),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: labour.workers == 0 ? 0 : labour.presentToday / labour.workers,
                  strokeWidth: 5,
                  color: SutraColors.neel,
                  backgroundColor: SutraColors.rule,
                ),
                Text('${labour.presentToday}/${labour.workers}', style: SutraType.figure(14)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.tr(LabText.wagesDue), style: Theme.of(context).textTheme.bodyMedium),
                AmountText(labour.wageDue, size: 22, incoming: false),
              ],
            ),
          ),
          if (labour.overdue > 0) Stamp('${s.tr(LabText.overdue)} ${Fmt.inr(labour.overdue)}', tone: Tone.critical, size: 10),
        ],
      ),
    );
  }
}

/// The two ways in that need no typing: speak, or photograph a bill.
class _InputTiles extends StatelessWidget {
  const _InputTiles({required this.strings, required this.example});
  final AppStrings strings;

  /// Something this producer's trade would actually say.
  final String example;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _InputTile(color: SutraColors.neel, icon: Icons.mic_rounded, title: strings.speakCta, sub: '“$example”', onTap: () => context.go('/voice'))),
        const SizedBox(width: 12),
        Expanded(child: _InputTile(color: SutraColors.sindoor, icon: Icons.photo_camera_outlined, title: strings.tr(BillText.title), sub: strings.tr(BillText.subtitle), onTap: () => context.push('/bill'))),
      ],
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({required this.color, required this.icon, required this.title, required this.sub, required this.onTap});
  final Color color;
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: const BorderRadius.all(SutraRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 10),
                  Text(title, style: SutraType.display(17, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                ],
              ),
            ),
            const ThreadStripe(height: 3),
          ],
        ),
      ),
    );
  }
}

/// This month's GST in one glance: what goes to the government, and whether anything needs fixing.
class _GstCard extends StatelessWidget {
  const _GstCard({required this.gst, required this.strings});
  final HomeGst gst;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return _Card(
      onTap: () => context.push('/gst'),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: SutraColors.sindoorWash, shape: BoxShape.circle),
            child: const Text('GST', style: TextStyle(color: SutraColors.sindoorDeep, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.tr(GstText.payable)} · ${gst.period}', style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                AmountText(gst.due, size: 22, incoming: false),
              ],
            ),
          ),
          Stamp(gst.issues == 0 ? s.tr(GstText.allGood) : '${gst.issues} ${s.tr(GstText.fix)}', tone: gst.issues == 0 ? Tone.ok : Tone.critical, size: 10),
        ],
      ),
    );
  }
}

/// Orders at a glance: new requests waiting for an answer (the one thing buyers wait on), and what is being made.
class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.kpis, required this.strings});
  final HomeKpis kpis;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    return _Card(
      onTap: () => context.push('/orders'),
      child: Row(
        children: [
          _Count(n: kpis.newRequests, label: s.tr(OrderText.tabNew), color: kpis.newRequests > 0 ? SutraColors.sindoor : SutraColors.inkSoft),
          Container(width: 1, height: 44, margin: const EdgeInsets.symmetric(horizontal: 14), color: SutraColors.rule),
          _Count(n: kpis.openOrders, label: s.tr(OrderText.tabActive), color: SutraColors.neel),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(s.tr(OrderText.title), style: text.titleSmall),
              const SizedBox(height: 4),
              TextButton.icon(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 36)),
                onPressed: () => context.push('/catalog'),
                icon: const Icon(Icons.auto_stories_outlined, size: 18),
                label: Text(s.tr(CatalogText.title)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.n, required this.label, required this.color});
  final int n;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n', style: SutraType.figure(26, color: color)),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}
