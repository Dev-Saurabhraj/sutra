import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/product_thumb.dart';
import '../../../design/widgets/stamp.dart';
import '../../orders/domain/order_models.dart';
import '../data/market_repository.dart';
import '../domain/market_models.dart';
import 'market_text.dart';

(String, Tone) buyerStage(AppStrings s, OrderStage stage) => switch (stage) {
      OrderStage.quoted => (s.tr(MarketText.stageAsked), Tone.due),
      OrderStage.confirmed || OrderStage.making => (s.tr(MarketText.stageMaking), Tone.low),
      OrderStage.dispatched => (s.tr(MarketText.stageSent), Tone.neutral),
      OrderStage.delivered => (s.tr(MarketText.stageReached), Tone.ok),
      OrderStage.declined => (s.tr(MarketText.declined), Tone.critical),
    };

/// B6: every order the buyer placed, newest first, with where it is.
class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(MarketText.myOrders))),
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => ref.refresh(buyerOrdersProvider.future),
          child: AsyncView<List<BuyerOrder>>(
            value: ref.watch(buyerOrdersProvider),
            strings: s,
            onRetry: () => ref.invalidate(buyerOrdersProvider),
            data: (orders) => orders.isEmpty
                ? ListView(padding: SutraSpace.page, children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                      child: Text(s.tr(MarketText.noOrders), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                    ),
                  ])
                : ListView.separated(
                    padding: SutraSpace.page,
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderTile(order: orders[i], strings: s),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.strings});
  final BuyerOrder order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final o = order;
    final text = Theme.of(context).textTheme;
    final (label, tone) = buyerStage(s, o.stage);
    return Material(
      color: SutraColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(SutraRadius.md), side: BorderSide(color: SutraColors.rule)),
      child: InkWell(
        borderRadius: const BorderRadius.all(SutraRadius.md),
        onTap: () => context.push('/my-order/${o.code}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumb(palette: o.palette, imageUrl: o.imageUrl, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.productName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${o.maker} · ${o.code}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('${o.qty} ${s.tr(MarketText.pieces)}', style: SutraType.figure(15)),
                        const SizedBox(width: 10),
                        Flexible(child: Text(Fmt.inr(o.value), style: SutraType.figure(15, color: SutraColors.neel), maxLines: 1)),
                      ],
                    ),
                    if (o.group != null) ...[
                      const SizedBox(height: 6),
                      Text('${o.group} · ${s.tr(MarketText.partOf)}', style: text.labelSmall?.copyWith(color: SutraColors.haldiDeep, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stamp(label, tone: tone, size: 10),
                  if (o.wantedBy != null && o.stage.index < OrderStage.dispatched.index) ...[
                    const SizedBox(height: 8),
                    Text(Fmt.shortDate(o.wantedBy!, hindi: s.isHindi), style: text.labelMedium?.copyWith(color: SutraColors.sindoorDeep, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
