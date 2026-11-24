import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/art/thread_meter.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/product_thumb.dart';
import '../../../design/widgets/stamp.dart';
import '../../orders/presentation/order_text.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_models.dart';
import 'catalog_text.dart';

/// The shop window: every product as a card the way a buyer would see it, with your margin on the back.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(CatalogText.title))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: RefreshIndicator(
              color: SutraColors.sindoor,
              onRefresh: () => ref.refresh(catalogProvider.future),
              child: AsyncView<CatalogList>(
                value: ref.watch(catalogProvider),
                strings: s,
                onRetry: () => ref.invalidate(catalogProvider),
                data: (c) => CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      sliver: SliverToBoxAdapter(child: _Summary(list: c, strings: s)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      sliver: SliverGrid.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.66),
                        itemCount: c.items.length,
                        itemBuilder: (_, i) => _ProductCard(item: c.items[i], strings: s),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.list, required this.strings});
  final CatalogList list;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${list.published}/${list.total}', style: SutraType.figure(28, color: SutraColors.neel)),
            const SizedBox(width: 8),
            Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(s.tr(CatalogText.shown), style: Theme.of(context).textTheme.bodyMedium))),
          ],
        ),
        const SizedBox(height: 6),
        WovenBar(value: list.total == 0 ? 0 : list.published / list.total, color: SutraColors.neel, height: 12),
        const SizedBox(height: 10),
        Text(s.tr(CatalogText.intro), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.strings});
  final CatalogItem item;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final i = item;
    final text = Theme.of(context).textTheme;
    final m = i.price0;
    final (marginLabel, tone) = m.belowCost
        ? (s.tr(OrderText.loss), Tone.critical)
        : m.thin
            ? (s.tr(OrderText.thin), Tone.low)
            : ('${Fmt.qty(m.pct)}%', Tone.ok);
    return Material(
      color: SutraColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(SutraRadius.md), side: BorderSide(color: SutraColors.rule)),
      child: InkWell(
        onTap: () => context.push('/catalog/${i.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(builder: (_, box) => ProductThumb(palette: i.palette, imageUrl: i.imageUrl, size: box.maxWidth, radius: Radius.zero)),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: SutraColors.card.withValues(alpha: 0.94), borderRadius: const BorderRadius.all(SutraRadius.sm)),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Stamp(i.published ? s.tr(CatalogText.live) : s.tr(CatalogText.hidden), tone: i.published ? Tone.ok : Tone.neutral, size: 9, angle: 0),
                      ),
                    ),
                  ),
                  if (i.imageUrl == null)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: const BorderRadius.all(SutraRadius.sm)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(s.tr(CatalogText.needsPhoto), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.pick(i.nameHi, i.name), style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(child: Text(Fmt.inr(i.price), style: SutraType.figure(16, color: SutraColors.neel), maxLines: 1)),
                        Stamp(marginLabel, tone: tone, size: 9, angle: 0),
                      ],
                    ),
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
