import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/art/shop_scene.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../data/market_repository.dart';
import '../domain/market_models.dart';
import 'market_text.dart';
import 'market_widgets.dart';

/// The bazaar (B1): search, craft / cluster / category chips, and a grid of products with the Can Deliver badge.
class BazaarScreen extends ConsumerStatefulWidget {
  const BazaarScreen({super.key});

  @override
  ConsumerState<BazaarScreen> createState() => _BazaarScreenState();
}

class _BazaarScreenState extends ConsumerState<BazaarScreen> {
  late final _search = TextEditingController(text: ref.read(marketFilterProvider).q);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => ref.read(marketFilterProvider.notifier).update((f) => f.copyWith(q: v)));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final filter = ref.watch(marketFilterProvider);
    final result = ref.watch(browseProvider);
    final facets = result.valueOrNull?.facets;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => ref.refresh(browseProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(strings: s)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(hintText: s.tr(MarketText.search), prefixIcon: const Icon(Icons.search_rounded)),
                  ),
                ),
              ),
              if (facets != null)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ChipRow(
                        strings: s,
                        // emoji in a chip label measures narrower than it renders on some platforms and clips the text
                        options: [for (final i in facets.industries) (i.key, s.pick(i.labelHi ?? i.label, i.label))],
                        selected: filter.industry,
                        onSelect: (v) => ref.read(marketFilterProvider.notifier).update((f) => f.copyWith(industry: v, clearIndustry: v == null, clearCategory: true)),
                      ),
                      _ChipRow(
                        strings: s,
                        options: [for (final c in facets.clusters) (c.key, c.label)],
                        selected: filter.cluster,
                        onSelect: (v) => ref.read(marketFilterProvider.notifier).update((f) => f.copyWith(cluster: v, clearCluster: v == null)),
                      ),
                      _ChipRow(
                        strings: s,
                        options: [for (final c in facets.categories) (c, c)],
                        selected: filter.category,
                        onSelect: (v) => ref.read(marketFilterProvider.notifier).update((f) => f.copyWith(category: v, clearCategory: v == null)),
                      ),
                    ],
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                sliver: result.when(
                  skipLoadingOnRefresh: true,
                  skipLoadingOnReload: true,
                  data: (b) => b.items.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Text(s.tr(MarketText.nothing), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                          ),
                        )
                      : SliverGrid.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.56),
                          itemCount: b.items.length,
                          itemBuilder: (_, i) => MarketCardTile(card: b.items[i], strings: s),
                        ),
                  loading: () => SliverToBoxAdapter(child: AsyncView<BrowseResult>(value: const AsyncLoading(), strings: s, data: (_) => const SizedBox())),
                  error: (e, _) => SliverToBoxAdapter(child: ErrorNote(error: e, strings: s, onRetry: () => ref.invalidate(browseProvider))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(SutraRadius.lg),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF7EA), Color(0xFFF6E7D3)]),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 132,
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(strings.tr(MarketText.bazaarTitle), style: SutraType.display(21), maxLines: 2),
                            const SizedBox(height: 6),
                            Text(strings.tr(MarketText.bazaarSub), style: Theme.of(context).textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                    const Expanded(flex: 4, child: Padding(padding: EdgeInsets.fromLTRB(0, 8, 12, 6), child: ShopArt())),
                  ],
                ),
              ),
              const ThreadStripe(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.strings, required this.options, required this.selected, required this.onSelect});
  final AppStrings strings;
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          ChoiceChip(label: Text(strings.tr(MarketText.all)), selected: selected == null, onSelected: (_) => onSelect(null)),
          for (final (key, label) in options) ...[
            const SizedBox(width: 8),
            ChoiceChip(label: Text(label), selected: selected == key, onSelected: (_) => onSelect(selected == key ? null : key)),
          ],
        ],
      ),
    );
  }
}
