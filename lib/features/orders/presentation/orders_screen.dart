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
import '../../catalog/presentation/catalog_text.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';
import 'order_text.dart';

/// The orders inbox: new requests to answer, orders being made or on the road, and finished ones.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final tab = ref.watch(orderTabProvider);
    final inbox = ref.watch(orderInboxProvider);
    final counts = inbox.valueOrNull?.counts;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tr(OrderText.title)),
        actions: [
          TextButton.icon(onPressed: () => context.push('/catalog'), icon: const Icon(Icons.auto_stories_outlined), label: Text(s.tr(CatalogText.title))),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SegmentedButton<OrderTab>(
                    showSelectedIcon: false,
                    segments: [
                      for (final t in OrderTab.values)
                        ButtonSegment(value: t, label: Text(_tabLabel(s, t, counts?[t]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    selected: {tab},
                    onSelectionChanged: (v) => ref.read(orderTabProvider.notifier).state = v.first,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: SutraColors.sindoor,
                    onRefresh: () => ref.refresh(orderInboxProvider.future),
                    child: AsyncView<OrderInbox>(
                      value: inbox,
                      strings: s,
                      onRetry: () => ref.invalidate(orderInboxProvider),
                      data: (b) => b.orders.isEmpty
                          ? ListView(padding: SutraSpace.page, children: [_Empty(text: s.tr(_emptyFor(tab)))])
                          : ListView.separated(
                              padding: SutraSpace.page,
                              itemCount: b.orders.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => OrderCard(order: b.orders[i], strings: s),
                            ),
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

  static String _tabLabel(AppStrings s, OrderTab t, int? n) {
    final name = s.tr(switch (t) { OrderTab.fresh => OrderText.tabNew, OrderTab.active => OrderText.tabActive, OrderTab.done => OrderText.tabDone });
    return n == null || n == 0 ? name : '$name $n';
  }

  static T _emptyFor(OrderTab t) => switch (t) { OrderTab.fresh => OrderText.emptyNew, OrderTab.active => OrderText.emptyActive, OrderTab.done => OrderText.emptyDone };
}

/// Stamp text and tone for a stage.
(String, Tone) stageStamp(AppStrings s, OrderStage stage) => switch (stage) {
      OrderStage.quoted => (s.tr(OrderText.stageAsked), Tone.due),
      OrderStage.confirmed || OrderStage.making => (s.tr(OrderText.stageMaking), Tone.low),
      OrderStage.dispatched => (s.tr(OrderText.stageSent), Tone.neutral),
      OrderStage.delivered => (s.tr(OrderText.stageReached), Tone.ok),
      OrderStage.declined => (s.tr(OrderText.declined), Tone.critical),
    };

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.strings});
  final Order order;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final o = order;
    final text = Theme.of(context).textTheme;
    final (stamp, tone) = stageStamp(s, o.stage);
    final note = o.lastMessage == null ? null : (s.isHindi ? (o.lastMessage!.textHi ?? o.lastMessage!.text) : o.lastMessage!.text);
    return Material(
      color: SutraColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(SutraRadius.md), side: BorderSide(color: SutraColors.rule)),
      child: InkWell(
        borderRadius: const BorderRadius.all(SutraRadius.md),
        onTap: () => context.push('/order/${o.code}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductThumb(palette: o.product.palette, imageUrl: o.product.imageUrl, size: 54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.party, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(s.pick(o.product.nameHi, o.product.name), style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('${o.qty} ${s.tr(OrderText.pieces)}', style: SutraType.figure(16)),
                            const SizedBox(width: 10),
                            Flexible(child: Text(Fmt.inr(o.value), style: SutraType.figure(16, color: SutraColors.neel), maxLines: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stamp(stamp, tone: tone, size: 10),
                      if (o.wantedBy != null && o.stage.index < OrderStage.dispatched.index) ...[
                        const SizedBox(height: 10),
                        Text(s.tr(OrderText.wanted), style: text.labelSmall),
                        Text(Fmt.shortDate(o.wantedBy!, hindi: s.isHindi), style: text.labelMedium?.copyWith(color: SutraColors.sindoorDeep, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ],
              ),
              if (note != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: const BoxDecoration(color: SutraColors.paper, borderRadius: BorderRadius.all(SutraRadius.sm)),
                  child: Row(
                    children: [
                      Icon(o.lastMessage!.fromBuyer ? Icons.mail_outline_rounded : Icons.reply_rounded, size: 16, color: SutraColors.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(child: Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: SutraColors.rule),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
          ],
        ),
      );
}
