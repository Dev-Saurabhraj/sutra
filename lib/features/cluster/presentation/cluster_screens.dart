import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/art/thread_meter.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/stamp.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../../../design/widgets/wax_seal.dart';
import '../../auth/presentation/session_controller.dart';
import '../../profile/presentation/reach_settings.dart';
import '../data/cluster_repository.dart';

abstract final class ClText {
  static const navMakers = T('कारीगर', 'Makers');
  static const navBulk = T('बड़ा ऑर्डर', 'Bulk order');
  static const navBuy = T('साथ ख़रीद', 'Buy together');
  static const navReport = T('रिपोर्ट', 'Report');
  static const makers = T('कारीगर', 'makers');
  static const machines = T('करघे/मशीनें', 'machines');
  static const made30 = T('30 दिन में बने', 'made in 30 days');
  static const sales30 = T('30 दिन की बिक्री', 'sales in 30 days');
  static const newReq = T('नई माँग', 'new requests');
  static const open = T('चल रहे', 'open');
  static const stockAlert = T('माल ख़त्म होने वाला', 'running out');
  static const low = T('कम', 'low');
  static const gstBad = T('GSTIN ग़लत', 'GSTIN wrong');
  static const unreg = T('GST नहीं', 'no GST');
  static const bulkTitle = T('बड़ा ऑर्डर बाँटें', 'Split a bulk order');
  static const bulkSub = T('हर कारीगर की असली क्षमता (स्टॉक, करघे, बाकी ऑर्डर, छुट्टियाँ) देखकर बराबरी से बाँटा जाता है।',
      'Shared fairly by each maker\'s real capacity (stock, looms, other orders, days off).');
  static const category = T('क्या', 'What');
  static const qty = T('कितने', 'How many');
  static const by = T('कब तक', 'By');
  static const buyer = T('किसके लिए (ख़रीदार)', 'For (buyer)');
  static const plan = T('बाँट कर देखें', 'Plan the split');
  static const canMake = T('बना सकते', 'can make');
  static const gets = T('को मिलेगा', 'gets');
  static const covered = T('तारीख़ तक बनेंगे', 'ready by the date');
  static const send = T('कारीगरों को भेजें', 'Send to the makers');
  static const sentTo = T('भेजा', 'Sent to');
  static const buyTitle = T('साथ में ख़रीदें, सस्ता पड़ेगा', 'Buy together, pay less');
  static const buySub = T('अगले 4 हफ़्ते में हर कारीगर को जितना कच्चा माल चाहिए, एक साथ जोड़ा गया। सप्लायर से थोक रेट माँगें।',
      'What every maker needs in the next 4 weeks, added up. Ask the supplier for one bulk rate.');
  static const ifFive = T('5% थोक छूट मिले तो बचत', 'If the supplier gives 5%, saving');
  static const askRate = T('सप्लायर से रेट पूछें', 'Ask the supplier');
  static const nothingToBuy = T('अभी किसी को कच्चा माल नहीं चाहिए।', 'Nobody needs material right now.');
  static const impact = T('असर', 'Impact');
  static const kept = T('बिचौलिये का हिस्सा बचा', 'agent\'s cut kept');
  static const direct = T('सीधे ऑर्डर', 'direct orders');
  static const onTime = T('औसत समय पर', 'average on time');
  static const income = T('महीने की कमाई (औसत)', 'monthly income (avg)');
  static const monthlyAll = T('क्लस्टर की महीने की बिक्री', 'cluster sales a month');
  static const compliance = T('GST की सेहत', 'GST health');
  static const issues = T('ठीक करना है', 'to fix');
  static const allOk = T('सब ठीक', 'All good');
  static const itcRisk = T('क्रेडिट अटका', 'credit at risk');
  static const noUdyam = T('उद्यम नहीं', 'no Udyam');
  static const account = T('खाता', 'Account');
}

/// The cooperative secretary's app: four tabs over the cluster's shared ledger.
class ClusterShell extends ConsumerStatefulWidget {
  const ClusterShell({super.key});

  @override
  ConsumerState<ClusterShell> createState() => _ClusterShellState();
}

class _ClusterShellState extends ConsumerState<ClusterShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final me = ref.watch(meProvider);
    final tabs = [
      (Icons.groups_2_outlined, s.tr(ClText.navMakers), const _Makers()),
      (Icons.call_split_rounded, s.tr(ClText.navBulk), const _Bulk()),
      (Icons.shopping_basket_outlined, s.tr(ClText.navBuy), const _BuyTogether()),
      (Icons.insights_outlined, s.tr(ClText.navReport), const _Report()),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(me?.cluster?.name ?? 'Cluster', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [IconButton(tooltip: s.tr(ClText.account), onPressed: () => showSutraSheet<void>(context, const _AccountSheet()), icon: const Icon(Icons.account_circle_outlined))],
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth), child: tabs[_tab].$3)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: SutraColors.card,
        indicatorColor: SutraColors.sindoorWash,
        destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.$1), label: t.$2)],
      ),
    );
  }
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: s.tr(ClText.account)),
        ChoiceCards<AppLang>(
          columns: 2,
          options: [for (final l in AppLang.values) ChoiceOption(value: l, title: l.label, icon: Icons.translate_rounded)],
          selected: s.lang,
          onSelect: (l) => ref.read(langProvider.notifier).set(l),
        ),
        const SizedBox(height: 12),
        const PrivacyActions(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ref.read(sessionControllerProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout_rounded),
          label: Text(s.logout),
          style: OutlinedButton.styleFrom(foregroundColor: SutraColors.kumkum),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- C1 makers

class _Makers extends ConsumerWidget {
  const _Makers();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return RefreshIndicator(
      color: SutraColors.sindoor,
      onRefresh: () => ref.refresh(clusterOverviewProvider.future),
      child: AsyncView<ClusterOverview>(
        value: ref.watch(clusterOverviewProvider),
        strings: s,
        onRetry: () => ref.invalidate(clusterOverviewProvider),
        data: (o) => ListView(
          padding: SutraSpace.page,
          children: [
            Row(
              children: [
                _Figure('${o.t('makers')}', s.tr(ClText.makers)),
                _Figure('${o.t('machines')}', s.tr(ClText.machines)),
                _Figure(Fmt.qty(o.t('made30')), s.tr(ClText.made30), color: SutraColors.neel),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Figure(Fmt.inr(o.t('sales30')), s.tr(ClText.sales30), color: SutraColors.neel),
                _Figure('${o.t('newRequests')}', s.tr(ClText.newReq), color: SutraColors.sindoor),
                _Figure('${o.t('stockAlerts')}', s.tr(ClText.stockAlert), color: o.t('stockAlerts') > 0 ? SutraColors.kumkum : SutraColors.ink),
              ],
            ),
            const SizedBox(height: 12),
            const ThreadStripe(radius: 2),
            const SizedBox(height: 12),
            for (final m in o.makers) Padding(padding: const EdgeInsets.only(bottom: 10), child: _MakerRow(m: m, strings: s, topMade: o.makers.map((x) => x.made30).fold(1.0, (a, b) => a > b ? a : b))),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.value, this.label, {this.color = SutraColors.ink});
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            FittedBox(child: Text(value, style: SutraType.figure(22, color: color))),
            Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      );
}

class _MakerRow extends StatelessWidget {
  const _MakerRow({required this.m, required this.strings, required this.topMade});
  final ClusterMaker m;
  final AppStrings strings;
  final double topMade;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(32, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsBadge(name: m.name, color: hexColor(m.avatarColor), size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.businessName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${m.machines} ${s.tr(ClText.machines)} · ${(m.onTimeRate * 100).round()}%', style: text.bodySmall),
                  ],
                ),
              ),
              Text(Fmt.qty(m.made30), style: SutraType.figure(18, color: SutraColors.neel)),
            ],
          ),
          const SizedBox(height: 8),
          WovenBar(value: m.made30 / topMade, color: SutraColors.neel, height: 10),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (m.newRequests > 0) Stamp('${m.newRequests} ${s.tr(ClText.newReq)}', tone: Tone.due, size: 9, angle: 0),
              if (m.openOrders > 0) Stamp('${m.openOrders} ${s.tr(ClText.open)}', tone: Tone.neutral, size: 9, angle: 0),
              if (m.stockCritical > 0) Stamp('${m.stockCritical} ${s.tr(ClText.stockAlert)}', tone: Tone.critical, size: 9, angle: 0),
              if (m.stockLow > 0) Stamp('${m.stockLow} ${s.tr(ClText.low)}', tone: Tone.low, size: 9, angle: 0),
              if (m.gstinOk == false) Stamp(s.tr(ClText.gstBad), tone: Tone.critical, size: 9, angle: 0),
              if (m.scheme == 'UNREGISTERED') Stamp(s.tr(ClText.unreg), tone: Tone.neutral, size: 9, angle: 0),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- C2 bulk split

class _Bulk extends ConsumerStatefulWidget {
  const _Bulk();
  @override
  ConsumerState<_Bulk> createState() => _BulkState();
}

class _BulkState extends ConsumerState<_Bulk> {
  String? _category;
  int _qty = 1000;
  DateTime _by = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 30));
  final _buyer = TextEditingController();
  SplitPlan? _plan;
  bool _busy = false;

  @override
  void dispose() {
    _buyer.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    final s = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final cats = ref.watch(clusterCategoriesProvider).valueOrNull ?? const <String>[];
    final p = _plan;
    return ListView(
      padding: SutraSpace.page,
      children: [
        Text(s.tr(ClText.bulkTitle), style: SutraType.display(20)),
        const SizedBox(height: 4),
        Text(s.tr(ClText.bulkSub), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        Text(s.tr(ClText.category), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final c in cats) ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() {
                    _category = c;
                    _plan = null;
                  }))],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: NumberField(label: s.tr(ClText.qty), initial: _qty, decimals: false, onChanged: (v) => setState(() {
                  _qty = (v ?? 0).round();
                  _plan = null;
                }))),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final now = DateUtils.dateOnly(DateTime.now());
                  final d = await showDatePicker(context: context, initialDate: _by, firstDate: now.add(const Duration(days: 1)), lastDate: now.add(const Duration(days: 365)));
                  if (d == null) return;
                  setState(() {
                    _by = d;
                    _plan = null;
                  });
                },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: s.tr(ClText.by), suffixIcon: const Icon(Icons.event_outlined)),
                  child: Text('${Fmt.shortDate(_by, hindi: s.isHindi)} ${_by.year}'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _buyer, decoration: InputDecoration(labelText: s.tr(ClText.buyer))),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size.fromHeight(50)),
          onPressed: _busy || _category == null || _qty < 1
              ? null
              : () => _run(() async {
                    final plan = await ref.read(clusterRepositoryProvider).split(_category!, _qty, _by);
                    setState(() => _plan = plan);
                  }),
          icon: const Icon(Icons.call_split_rounded),
          label: Text(s.tr(ClText.plan)),
        ),
        if (p != null) ...[
          const SizedBox(height: 14),
          LedgerCard(
            padding: const EdgeInsets.fromLTRB(32, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('${p.covered} / ${p.qty} ${s.tr(ClText.covered)}', style: SutraType.display(17))),
                    Stamp(p.canMeet ? '100%' : '${(p.covered / p.qty * 100).round()}%', tone: p.canMeet ? Tone.ok : Tone.low, angle: 0),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: SizedBox(
                    height: 16,
                    child: Row(children: [
                      for (final r in p.rows) if (r.assigned > 0) Expanded(flex: r.assigned, child: Container(color: hexColor(r.avatarColor))),
                      if (p.covered < p.qty) Expanded(flex: p.qty - p.covered, child: Container(color: SutraColors.rule)),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                for (final (i, r) in p.rows.indexed)
                  LedgerLine(
                    label: r.maker,
                    sub: '${s.tr(ClText.canMake)} ${r.capacity} · ${Fmt.inr(r.rate)}',
                    value: Text('${r.assigned}', style: SutraType.figure(17, color: SutraColors.neel)),
                    last: i == p.rows.length - 1,
                  ),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: Text(Fmt.inr(p.value), style: SutraType.figure(18))), const SizedBox()]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: SutraColors.sindoor, minimumSize: const Size.fromHeight(52)),
            onPressed: _busy || p.covered == 0
                ? null
                : () => _run(() async {
                      final messenger = ScaffoldMessenger.of(context);
                      final r = await ref.read(clusterRepositoryProvider).send(_category!, _qty, _by, _buyer.text);
                      final n = (r['orders'] as List).length;
                      messenger.showSnackBar(SnackBar(content: Text('${r['group']} · ${s.tr(ClText.sentTo)} $n ${s.tr(ClText.makers)}')));
                      ref.invalidate(clusterOverviewProvider);
                      setState(() => _plan = null);
                    }),
            icon: const Icon(Icons.send_rounded),
            label: Text(s.tr(ClText.send)),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- C3 buy together

class _BuyTogether extends ConsumerWidget {
  const _BuyTogether();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    return AsyncView<(double, List<GroupBuyItem>)>(
      value: ref.watch(groupBuyProvider),
      strings: s,
      onRetry: () => ref.invalidate(groupBuyProvider),
      data: (g) => ListView(
        padding: SutraSpace.page,
        children: [
          Text(s.tr(ClText.buyTitle), style: SutraType.display(20)),
          const SizedBox(height: 4),
          Text(s.tr(ClText.buySub), style: text.bodySmall),
          const SizedBox(height: 12),
          if (g.$2.isEmpty) Text(s.tr(ClText.nothingToBuy), style: text.bodyMedium),
          for (final i in g.$2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LedgerCard(
                padding: const EdgeInsets.fromLTRB(32, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(s.pick(i.nameHi, i.name), style: SutraType.display(17))),
                        Text('${Fmt.qty(i.qty)} ${i.unit}', style: SutraType.figure(18, color: SutraColors.neel)),
                      ],
                    ),
                    Text('${i.makers.length} ${s.tr(ClText.makers)} · ${Fmt.inr(i.value)}', style: text.bodySmall),
                    const SizedBox(height: 6),
                    for (final (name, q) in i.makers.take(6)) Text('• $name: ${Fmt.qty(q)} ${i.unit}', style: text.bodySmall),
                    const SizedBox(height: 8),
                    Text('${s.tr(ClText.ifFive)}: ${Fmt.inr(i.possibleSaving)}', style: text.labelMedium?.copyWith(color: SutraColors.haldiDeep, fontWeight: FontWeight.w700)),
                    if (i.suppliers.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => ref.read(linkLauncherProvider).open('https://wa.me/${i.suppliers.first.$2.replaceAll(RegExp(r'[^0-9]'), '')}?text=${Uri.encodeComponent(i.message)}'),
                          icon: const Icon(Icons.chat_outlined),
                          label: Text('${s.tr(ClText.askRate)}: ${i.suppliers.first.$1}'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- C4 + C5 report

class _Report extends ConsumerWidget {
  const _Report();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    final impact = ref.watch(impactProvider);
    final comp = ref.watch(complianceProvider);
    return ListView(
      padding: SutraSpace.page,
      children: [
        Text(s.tr(ClText.impact), style: SutraType.display(20)),
        const SizedBox(height: 8),
        AsyncView<Map<String, dynamic>>(
          value: impact,
          strings: s,
          onRetry: () => ref.invalidate(impactProvider),
          data: (j) {
            final t = (j['totals'] as Map).cast<String, dynamic>();
            final makers = (j['makers'] as List).cast<Map<String, dynamic>>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: SutraColors.neelWash, borderRadius: BorderRadius.all(SutraRadius.md)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Fmt.inr(t['agentCutKept'] as num), style: SutraType.figure(30, color: SutraColors.neelDeep)),
                      Text(s.tr(ClText.kept), style: text.titleSmall),
                      const SizedBox(height: 6),
                      Text(s.pick(j['headlineHi'] as String, j['headline'] as String), style: text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  _Figure('${t['directOrders']}', s.tr(ClText.direct)),
                  _Figure('${t['avgOnTime']}%', s.tr(ClText.onTime), color: SutraColors.neel),
                  _Figure(Fmt.inr((t['sales90'] as num) / 3), s.tr(ClText.monthlyAll)),
                ]),
                const SizedBox(height: 10),
                LedgerCard(
                  child: Column(children: [
                    for (final (i, m) in makers.indexed)
                      LedgerLine(
                        label: m['businessName'] as String,
                        sub: '${m['directOrders']} ${s.tr(ClText.direct)} · ${s.tr(ClText.income)} ${Fmt.inr(m['monthlyIncome'] as num)}',
                        value: AmountText(m['agentCutKept'] as num, size: 15, incoming: true),
                        last: i == makers.length - 1,
                      ),
                  ]),
                ),
              ],
            );
          },
        ),
        SectionHeader(s.tr(ClText.compliance)),
        AsyncView<Map<String, dynamic>>(
          value: comp,
          strings: s,
          onRetry: () => ref.invalidate(complianceProvider),
          data: (j) {
            final makers = (j['makers'] as List).cast<Map<String, dynamic>>();
            return LedgerCard(
              padding: const EdgeInsets.fromLTRB(32, 8, 12, 8),
              child: Column(children: [
                for (final (i, m) in makers.indexed)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == makers.length - 1 ? 0 : 6),
                    child: Row(
                      children: [
                        WaxSeal(checked: m['gstinOk'] == true, size: 24, color: SutraColors.sindoor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['businessName'] as String, style: text.titleSmall),
                              Text(
                                [
                                  m['scheme'] as String,
                                  if ((m['itcAtRisk'] as num) > 0) '${s.tr(ClText.itcRisk)} ${Fmt.inr(m['itcAtRisk'] as num)}',
                                  if (m['udyam'] != true) s.tr(ClText.noUdyam),
                                ].join(' · '),
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Stamp(
                          (m['issues'] as List).isEmpty ? s.tr(ClText.allOk) : '${(m['issues'] as List).length} ${s.tr(ClText.issues)}',
                          tone: (m['issues'] as List).isEmpty ? Tone.ok : Tone.critical,
                          size: 9,
                          angle: 0,
                        ),
                      ],
                    ),
                  ),
              ]),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
