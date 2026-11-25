import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/product_thumb.dart';
import '../data/market_repository.dart';
import '../domain/market_models.dart';
import 'market_text.dart';
import 'market_widgets.dart';
import 'quote_panel.dart';

/// One product: photo, the maker, price, story, then "how many, by when?" answered on the spot.
class ProductPageScreen extends ConsumerWidget {
  const ProductPageScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<ProductPage>(
              value: ref.watch(productPageProvider(productId)),
              strings: s,
              onRetry: () => ref.invalidate(productPageProvider(productId)),
              data: (p) => _Body(page: p, strings: s),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.page, required this.strings});
  final ProductPage page;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final p = page.product;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: SutraSpace.page,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(SutraRadius.lg),
          child: AspectRatio(
            aspectRatio: 1.25,
            child: LayoutBuilder(builder: (_, box) => ProductThumb(palette: p.palette, imageUrl: p.imageUrl, size: box.maxWidth, radius: Radius.zero)),
          ),
        ),
        const SizedBox(height: 14),
        Text(p.name, style: SutraType.display(22)),
        Text(p.category, style: text.bodySmall),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Fmt.inr(p.price), style: SutraType.figure(28, color: SutraColors.ink)),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('${s.tr(MarketText.wholesale)} · ${s.tr(MarketText.mrp)} ${Fmt.inr(page.mrp)}', style: text.bodySmall, maxLines: 2),
              ),
            ),
          ],
        ),
        if (p.badge != null) ...[const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: DeliverBadgeChip(badge: p.badge!, strings: s))],
        const SizedBox(height: 8),
        MakerLine(maker: page.maker, strings: s),
        SectionHeader(s.tr(MarketText.askQuote)),
        QuotePanel(productId: p.id, strings: s),
        if (page.story.trim().isNotEmpty) ...[
          SectionHeader(s.tr(MarketText.about)),
          Text(page.story, style: text.bodyMedium?.copyWith(height: 1.5)),
        ],
        SectionHeader(s.tr(MarketText.trust)),
        TrustLedger(maker: page.maker, strings: s),
        if (page.more.isNotEmpty) ...[
          SectionHeader(s.tr(MarketText.moreFromMaker)),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: page.more.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(width: 168, child: MarketCardTile(card: page.more[i], strings: s)),
            ),
          ),
        ],
      ],
    );
  }
}
