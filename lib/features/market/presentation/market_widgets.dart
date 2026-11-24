import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/product_thumb.dart';
import '../../../design/widgets/wax_seal.dart';
import '../domain/market_models.dart';
import 'market_text.dart';

/// "24 ready · 13/week": the Can Deliver badge as a small spool label.
class DeliverBadgeChip extends StatelessWidget {
  const DeliverBadgeChip({super.key, required this.badge, required this.strings, this.dense = false});
  final DeliverBadge badge;
  final AppStrings strings;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final style = TextStyle(fontSize: dense ? 11 : 12.5, fontWeight: FontWeight.w700, color: SutraColors.neelDeep, height: 1.2);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 3 : 5),
      decoration: const BoxDecoration(color: SutraColors.neelWash, borderRadius: BorderRadius.all(SutraRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: dense ? 12 : 14, color: SutraColors.neel),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${badge.ready} ${s.tr(MarketText.ready)} · ${badge.perWeek}${s.tr(MarketText.perWeek)}',
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge.slowWeek) ...[
            const SizedBox(width: 4),
            Tooltip(message: s.tr(MarketText.slowWeek), child: Icon(Icons.event_busy_outlined, size: dense ? 12 : 14, color: SutraColors.haldiDeep)),
          ],
        ],
      ),
    );
  }
}

/// A product as a shop-window card: photo, name, maker, price and the badge.
class MarketCardTile extends StatelessWidget {
  const MarketCardTile({super.key, required this.card, required this.strings});
  final MarketCard card;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final c = card;
    final text = Theme.of(context).textTheme;
    return Material(
      color: SutraColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(SutraRadius.md), side: BorderSide(color: SutraColors.rule)),
      child: InkWell(
        onTap: () => context.push('/bazaar/p/${c.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(builder: (_, box) => ProductThumb(palette: c.palette, imageUrl: c.imageUrl, size: box.maxWidth, radius: Radius.zero)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${c.maker.businessName} · ${c.maker.city}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text(Fmt.inr(c.price), style: SutraType.figure(16, color: SutraColors.ink)),
                    if (c.badge != null) ...[const SizedBox(height: 4), DeliverBadgeChip(badge: c.badge!, strings: strings, dense: true)],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The maker in one line, tappable to their trust profile.
class MakerLine extends StatelessWidget {
  const MakerLine({super.key, required this.maker, required this.strings});
  final MakerTrust maker;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final m = maker;
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: const BorderRadius.all(SutraRadius.md),
      onTap: () => context.push('/bazaar/maker/${m.slug}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            InitialsBadge(name: m.name, color: hexColor(m.avatarColor), size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.businessName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text([m.city, ?m.cluster].join(' · '), style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text('${(m.onTimeRate * 100).round()}%', style: SutraType.figure(16, color: SutraColors.neel)),
            const SizedBox(width: 4),
            Text(strings.tr(MarketText.onTime), style: text.labelSmall),
            const Icon(Icons.chevron_right_rounded, color: SutraColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// The trust profile (B7) as a ledger page: a wax seal beside each fact that was checked.
class TrustLedger extends StatelessWidget {
  const TrustLedger({super.key, required this.maker, required this.strings});
  final MakerTrust maker;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final m = maker;
    final text = Theme.of(context).textTheme;
    final gstLabel = switch (m.gstScheme) {
      'UNREGISTERED' => s.tr(MarketText.unregistered),
      'COMPOSITION' => '${s.tr(MarketText.gstinChecked)} · ${s.tr(MarketText.composition)}',
      _ => s.tr(MarketText.gstinChecked),
    };
    Widget fact(bool checked, String label, {String? sub, Color color = SutraColors.sindoor, IconData icon = Icons.check_rounded}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              WaxSeal(checked: checked, color: color, icon: icon, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: checked ? SutraColors.ink : SutraColors.inkSoft)),
                    if (sub != null) Text(sub, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
    return LedgerCard(
      padding: const EdgeInsets.fromLTRB(36, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Figure(value: '${(m.onTimeRate * 100).round()}%', label: s.tr(MarketText.onTimeRate), color: SutraColors.neel),
              _Figure(value: '${m.ordersDone}', label: s.tr(MarketText.ordersDone)),
              _Figure(value: '${m.machines}', label: s.tr(MarketText.looms)),
            ],
          ),
          const Divider(height: 18, color: SutraColors.rule),
          fact(m.gstin != null && m.gstinFormatOk, gstLabel, sub: m.gstin == null ? null : '${m.gstin} · ${s.tr(MarketText.gstinNote)}'),
          fact(m.udyamRegistered, s.tr(MarketText.udyam), color: SutraColors.neel),
          for (final mark in m.marks) fact(true, markLabel(s, mark), color: SutraColors.haldiDeep, icon: Icons.workspace_premium_outlined),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${s.tr(MarketText.since)} ${Fmt.shortDate(m.since, hindi: s.isHindi)} ${m.since.year}', style: text.labelSmall),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.color = SutraColors.ink});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: SutraType.figure(22, color: color)),
            Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      );
}
