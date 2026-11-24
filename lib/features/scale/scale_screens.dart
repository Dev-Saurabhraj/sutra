import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/async_view.dart';
import '../../design/widgets/bits.dart';
import '../../design/widgets/form_bits.dart';
import '../../design/widgets/ledger_card.dart';
import '../../design/widgets/sheet_form.dart';
import '../../design/widgets/stamp.dart';
import '../../design/widgets/wax_seal.dart';
import '../auth/presentation/session_controller.dart';
import '../profile/presentation/reach_settings.dart';

abstract final class ScaleText {
  static const ondc = T('ONDC पर बेचें', 'Sell on ONDC');
  static const ondcSub = T('ONDC सरकारी खुला नेटवर्क है: एक बार कैटलॉग डालें, कई ऐप पर दिखे। सेलर ऐप इसी फ़ाइल से आपका सामान ले लेगा।',
      'ONDC is the government\'s open network: list once, show on many apps. A seller app takes your products from this file.');
  static const ready = T('तैयार', 'ready');
  static const domain = T('श्रेणी', 'Domain');
  static const shareCatalog = T('कैटलॉग फ़ाइल भेजें', 'Share the catalog file');
  static const allGood = T('सब ठीक', 'All set');
  static const earlyPay = T('जल्दी पैसा (TReDS)', 'Get paid early (TReDS)');
  static const earlySub = T('RBI से मान्य TReDS पर आपका बिल बैंक ख़रीदते हैं: पैसा अभी, ख़रीदार बाद में चुकाता है। ख़रीदार भी TReDS पर होना चाहिए।',
      'On RBI-licensed TReDS platforms, financiers buy your invoice: you are paid now, the buyer pays later. The buyer must be on TReDS too.');
  static const possible = T('जल्दी मिल सकता है', 'could come early');
  static const cost = T('अनुमानित ख़र्च', 'est. cost');
  static const youGet = T('आपको मिलेगा', 'you get');
  static const daysEarly = T('दिन पहले', 'days early');
  static const estimate = T('ख़र्च अनुमान है (सालाना 11%); असली दर फ़ाइनेंसर की बोली से तय होती है।', 'The cost is an estimate (11% a year); the real rate comes from financiers\' bids.');
  static const cluster = T('क्लस्टर से जुड़ें', 'Join a cluster');
  static const clusterSub = T('क्लस्टर में बड़े ऑर्डर मिलकर लेते हैं और कच्चा माल साथ में सस्ता ख़रीदते हैं।', 'In a cluster, makers take big orders together and buy material together for less.');
  static const ask = T('जुड़ने को कहें', 'Ask to join');
  static const pending = T('जवाब का इंतज़ार', 'Waiting for approval');
  static const member = T('आप इसमें हैं', 'You\'re a member');
  static const sameTrade = T('आपका काम', 'your trade');
  static const makers = T('कारीगर', 'makers');
  static const ca = T('आपके CA', 'Your CA');
  static const caSub = T('CA को सिर्फ़ GST देखने की अनुमति दें (बदल नहीं सकते)। कभी भी हटा सकते हैं।', 'Let your CA see your GST only (read-only). Take it back any time.');
  static const addCa = T('CA जोड़ें', 'Add a CA');
  static const caName = T('CA का नाम', 'CA\'s name');
  static const caPhone = T('CA का मोबाइल', 'CA\'s mobile');
  static const remove = T('हटाएँ', 'Remove');
  static const caPortal = T('मेरे क्लाइंट', 'My clients');
  static const payable = T('देना', 'payable');
  static const issues = T('ठीक करना', 'to fix');
  static const atRisk = T('क्रेडिट अटका', 'credit at risk');
  static const csv = T('CSV', 'CSV');
  static const gstr1 = T('GSTR-1', 'GSTR-1');
  static const joins = T('जुड़ना चाहते हैं', 'Want to join');
  static const approve = T('हाँ', 'Approve');
  static const decline = T('नहीं', 'Decline');
}

void _toast(BuildContext context, AppStrings s, Object e) {
  final err = ApiException.from(e);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
}

Future<void> _shareJson(String name, Object json) => SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(utf8.encode(const JsonEncoder.withIndent('  ').convert(json)), name: name, mimeType: 'application/json')],
      fileNameOverrides: [name],
    ));

Scaffold _page(String title, Widget body) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth), child: body))),
    );

// ---------------------------------------------------------------- X8 ONDC

final ondcProvider = FutureProvider.autoDispose((ref) => ref.watch(apiClientProvider).get('/ondc/catalog'));

class OndcScreen extends ConsumerWidget {
  const OndcScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    return _page(
      s.tr(ScaleText.ondc),
      AsyncView<Map<String, dynamic>>(
        value: ref.watch(ondcProvider),
        strings: s,
        onRetry: () => ref.invalidate(ondcProvider),
        data: (j) {
          final items = (j['items'] as List).cast<Map<String, dynamic>>();
          final domain = j['domain'] as Map<String, dynamic>?;
          return ListView(
            padding: SutraSpace.page,
            children: [
              Text(s.tr(ScaleText.ondcSub), style: text.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
              const SizedBox(height: 12),
              Row(children: [
                Text('${j['ready']}/${j['total']}', style: SutraType.figure(28, color: SutraColors.neel)),
                const SizedBox(width: 8),
                Text(s.tr(ScaleText.ready), style: text.titleSmall),
                const Spacer(),
                if (domain != null) Stamp('${domain['code']} · ${domain['name']}', tone: Tone.neutral, size: 9, angle: 0),
              ]),
              const SizedBox(height: 12),
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LedgerCard(
                    padding: const EdgeInsets.fromLTRB(32, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          WaxSeal(checked: !(it['issues'] as List).any((x) => (x as Map)['blocking'] == true), size: 24, color: SutraColors.neel),
                          const SizedBox(width: 10),
                          Expanded(child: Text(it['name'] as String, style: text.titleSmall)),
                        ]),
                        for (final iss in (it['issues'] as List).cast<Map<String, dynamic>>())
                          Text('• ${s.pick(iss['hi'] as String, iss['en'] as String)}',
                              style: text.bodySmall?.copyWith(color: iss['blocking'] == true ? SutraColors.kumkum : SutraColors.inkSoft)),
                        if ((it['issues'] as List).isEmpty) Text(s.tr(ScaleText.allGood), style: text.bodySmall?.copyWith(color: SutraColors.neel)),
                      ],
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: (j['ready'] as num) == 0 ? null : () => _shareJson('ondc-catalog.json', j['catalog'] as Object),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(s.tr(ScaleText.shareCatalog)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- X8 TReDS

final earlyPayProvider = FutureProvider.autoDispose((ref) => ref.watch(apiClientProvider).get('/finance/early-pay'));

class EarlyPayScreen extends ConsumerWidget {
  const EarlyPayScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    return _page(
      s.tr(ScaleText.earlyPay),
      AsyncView<Map<String, dynamic>>(
        value: ref.watch(earlyPayProvider),
        strings: s,
        onRetry: () => ref.invalidate(earlyPayProvider),
        data: (j) {
          final rows = (j['rows'] as List).cast<Map<String, dynamic>>();
          return ListView(
            padding: SutraSpace.page,
            children: [
              Text(s.tr(ScaleText.earlySub), style: text.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
              const SizedBox(height: 12),
              Text(Fmt.inr(j['possible'] as num), style: SutraType.figure(30, color: SutraColors.neel)),
              Text(s.tr(ScaleText.possible), style: text.titleSmall),
              const SizedBox(height: 12),
              LedgerCard(
                child: Column(children: [
                  for (final (i, r) in rows.indexed)
                    LedgerLine(
                      label: r['party'] as String,
                      sub: r['fit'] == 'NO'
                          ? s.pick(r['reasonHi'] as String, r['reasonEn'] as String)
                          : '${r['daysEarly']} ${s.tr(ScaleText.daysEarly)} · ${s.tr(ScaleText.cost)} ${Fmt.inr(r['estCost'] as num)} · ${s.tr(ScaleText.youGet)} ${Fmt.inr(r['youGet'] as num)}',
                      value: AmountText(r['amount'] as num, size: 16, incoming: r['fit'] != 'NO'),
                      last: i == rows.length - 1,
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Text(s.tr(ScaleText.estimate), style: text.labelSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final p in (j['platforms'] as List).cast<Map<String, dynamic>>())
                  OutlinedButton(onPressed: () => ref.read(linkLauncherProvider).open(p['link'] as String), child: Text(p['name'] as String)),
              ]),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- multi-cluster

final clustersProvider = FutureProvider.autoDispose((ref) => ref.watch(apiClientProvider).get('/clusters'));

class JoinClusterScreen extends ConsumerWidget {
  const JoinClusterScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    return _page(
      s.tr(ScaleText.cluster),
      AsyncView<Map<String, dynamic>>(
        value: ref.watch(clustersProvider),
        strings: s,
        onRetry: () => ref.invalidate(clustersProvider),
        data: (j) {
          final pending = (j['pending'] as Map<String, dynamic>?)?['clusterId'];
          return ListView(
            padding: SutraSpace.page,
            children: [
              Text(s.tr(ScaleText.clusterSub), style: text.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
              const SizedBox(height: 12),
              for (final c in (j['clusters'] as List).cast<Map<String, dynamic>>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LedgerCard(
                    padding: const EdgeInsets.fromLTRB(32, 10, 12, 10),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c['name'] as String, style: text.titleSmall),
                          Text('${(c['industry'] as Map)['emoji']} ${c['city']}, ${c['state']} · ${c['makers']} ${s.tr(ScaleText.makers)}${c['sameTrade'] == true ? ' · ${s.tr(ScaleText.sameTrade)}' : ''}',
                              style: text.bodySmall),
                        ]),
                      ),
                      if (j['mine'] == c['id'])
                        Stamp(s.tr(ScaleText.member), tone: Tone.ok, size: 9, angle: 0)
                      else if (pending == c['id'])
                        Stamp(s.tr(ScaleText.pending), tone: Tone.low, size: 9, angle: 0)
                      else
                        TextButton(
                          onPressed: () async {
                            try {
                              await ref.read(apiClientProvider).post('/clusters/${c['id']}/join', idempotent: true);
                              ref.invalidate(clustersProvider);
                            } catch (e) {
                              if (context.mounted) _toast(context, s, e);
                            }
                          },
                          child: Text(s.tr(ScaleText.ask)),
                        ),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Cluster admin: makers asking to join.
final clusterJoinsProvider = FutureProvider.autoDispose((ref) async => ((await ref.watch(apiClientProvider).get('/cluster/joins'))['joins'] as List).cast<Map<String, dynamic>>());

class JoinRequestsCard extends ConsumerWidget {
  const JoinRequestsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final joins = ref.watch(clusterJoinsProvider).valueOrNull ?? const [];
    if (joins.isEmpty) return const SizedBox.shrink();
    Future<void> decide(String id, bool approve) async {
      try {
        await ref.read(apiClientProvider).post('/cluster/joins/$id', body: {'approve': approve}, idempotent: true);
        ref.invalidate(clusterJoinsProvider);
      } catch (e) {
        if (context.mounted) _toast(context, s, e);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: SutraColors.haldiWash, borderRadius: const BorderRadius.all(SutraRadius.md), border: Border.all(color: SutraColors.haldi)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.tr(ScaleText.joins), style: SutraType.display(16)),
            for (final j in joins)
              Row(children: [
                Expanded(child: Text('${(j['maker'] as Map)['businessName']} · ${(j['maker'] as Map)['city']} · ${(j['maker'] as Map)['machines']}')),
                TextButton(onPressed: () => decide(j['id'] as String, false), child: Text(s.tr(ScaleText.decline))),
                FilledButton(onPressed: () => decide(j['id'] as String, true), child: Text(s.tr(ScaleText.approve))),
              ]),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- CA access (maker) and the CA portal

final caAccessProvider = FutureProvider.autoDispose((ref) async => ((await ref.watch(apiClientProvider).get('/me/ca'))['access'] as List).cast<Map<String, dynamic>>());

class CaAccessCard extends ConsumerWidget {
  const CaAccessCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final list = ref.watch(caAccessProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr(ScaleText.caSub), style: Theme.of(context).textTheme.bodySmall),
        for (final a in list)
          LedgerLine(
            label: a['name'] as String,
            sub: a['phone'] as String,
            value: TextButton(
              onPressed: () async {
                await ref.read(apiClientProvider).delete('/me/ca/${a['id']}');
                ref.invalidate(caAccessProvider);
              },
              child: Text(s.tr(ScaleText.remove)),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(onPressed: () => showSutraSheet<void>(context, const _AddCaSheet()), icon: const Icon(Icons.person_add_alt_outlined), label: Text(s.tr(ScaleText.addCa))),
      ],
    );
  }
}

class _AddCaSheet extends ConsumerStatefulWidget {
  const _AddCaSheet();
  @override
  ConsumerState<_AddCaSheet> createState() => _AddCaSheetState();
}

class _AddCaSheetState extends ConsumerState<_AddCaSheet> {
  String _name = '';
  String _phone = '';
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SheetForm(
      title: s.tr(ScaleText.addCa),
      subtitle: s.tr(ScaleText.caSub),
      saveLabel: s.tr(ScaleText.addCa),
      canSave: _name.trim().length >= 2 && _phone.replaceAll(RegExp(r'\D'), '').length >= 10,
      onSave: () async {
        await ref.read(apiClientProvider).post('/me/ca', body: {'name': _name, 'phone': _phone}, idempotent: true);
        ref.invalidate(caAccessProvider);
        return null;
      },
      children: [
        TextField(decoration: InputDecoration(labelText: s.tr(ScaleText.caName)), onChanged: (v) => setState(() => _name = v)),
        const SizedBox(height: 12),
        TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.tr(ScaleText.caPhone)), onChanged: (v) => setState(() => _phone = v)),
      ],
    );
  }
}

final caClientsProvider = FutureProvider.autoDispose((ref) async => ((await ref.watch(apiClientProvider).get('/ca/clients'))['clients'] as List).cast<Map<String, dynamic>>());

/// The CA's whole app: every client who granted access, this month at a glance, files one tap away.
class CaPortalScreen extends ConsumerWidget {
  const CaPortalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final me = ref.watch(meProvider);
    final text = Theme.of(context).textTheme;
    final api = ref.read(apiClientProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('${s.tr(ScaleText.caPortal)} · ${me?.caName ?? 'CA'}', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: () => showSutraSheet<void>(
              context,
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const PrivacyActions(),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(sessionControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(s.logout),
                ),
              ]),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<List<Map<String, dynamic>>>(
              value: ref.watch(caClientsProvider),
              strings: s,
              onRetry: () => ref.invalidate(caClientsProvider),
              data: (clients) => ListView(
                padding: SutraSpace.page,
                children: [
                  for (final c in clients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LedgerCard(
                        padding: const EdgeInsets.fromLTRB(32, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              InitialsBadge(name: c['name'] as String, color: hexColor(c['avatarColor'] as String), size: 36),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['businessName'] as String, style: text.titleSmall),
                                  Text('${c['gstin'] ?? '—'} · ${c['gstScheme']} · ${c['period']}', style: text.bodySmall),
                                ]),
                              ),
                              Stamp(
                                (c['issues'] as num) == 0 ? 'OK' : '${c['issues']} ${s.tr(ScaleText.issues)}',
                                tone: (c['issues'] as num) == 0 ? Tone.ok : Tone.critical,
                                size: 9,
                                angle: 0,
                              ),
                            ]),
                            LedgerLine(label: s.tr(ScaleText.payable), value: AmountText(c['payable'] as num, size: 16, incoming: false)),
                            LedgerLine(label: s.tr(ScaleText.atRisk), value: AmountText(c['itcAtRisk'] as num, size: 16), last: true),
                            Row(children: [
                              TextButton.icon(
                                onPressed: () async {
                                  try {
                                    final b = await api.getBytes('/ca/clients/${c['id']}/export.csv');
                                    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(b, name: 'gst-${c['businessName']}.csv', mimeType: 'text/csv')]));
                                  } catch (e) {
                                    if (context.mounted) _toast(context, s, e);
                                  }
                                },
                                icon: const Icon(Icons.table_view_outlined, size: 18),
                                label: Text(s.tr(ScaleText.csv)),
                              ),
                              if (c['gstScheme'] == 'REGULAR')
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      await _shareJson('gstr1-${c['businessName']}.json', await api.get('/ca/clients/${c['id']}/gstr1.json'));
                                    } catch (e) {
                                      if (context.mounted) _toast(context, s, e);
                                    }
                                  },
                                  icon: const Icon(Icons.data_object_rounded, size: 18),
                                  label: Text(s.tr(ScaleText.gstr1)),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
