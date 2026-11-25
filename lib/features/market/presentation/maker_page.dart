import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../data/market_repository.dart';
import '../domain/market_models.dart';
import 'market_text.dart';
import 'market_widgets.dart';

/// A maker's trust profile (B7): who they are, what was checked, their story and everything they sell.
class MakerPageScreen extends ConsumerWidget {
  const MakerPageScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<MakerPage>(
              value: ref.watch(makerPageProvider(slug)),
              strings: s,
              onRetry: () => ref.invalidate(makerPageProvider(slug)),
              data: (p) {
                final m = p.maker;
                final text = Theme.of(context).textTheme;
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      sliver: SliverList.list(
                        children: [
                          Row(
                            children: [
                              InitialsBadge(name: m.name, color: hexColor(m.avatarColor), size: 64),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.businessName, style: SutraType.display(22), maxLines: 2),
                                    Text('${m.name} · ${m.city}, ${m.state}', style: text.bodySmall),
                                    if (m.cluster != null) Text('${m.industryEmoji} ${m.cluster}', style: text.labelMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const ThreadStripe(height: 4, radius: 2),
                          const SizedBox(height: 14),
                          TrustLedger(maker: m, strings: s),
                          if (m.story.trim().isNotEmpty) ...[
                            SectionHeader(s.tr(MarketText.theirWords)),
                            Text(m.story, style: text.bodyMedium?.copyWith(height: 1.5)),
                          ],
                          SectionHeader(s.tr(MarketText.allProducts)),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.56),
                        itemCount: p.products.length,
                        itemBuilder: (_, i) => MarketCardTile(card: p.products[i], strings: s),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
