import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/art/flow_pipeline.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../stock/domain/stock_models.dart';
import '../../stock/presentation/material_row.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_models.dart';
import 'inventory_sheets.dart';
import 'inventory_text.dart';

enum Station { supplier, raw, making, ready, client }

final selectedStationProvider = StateProvider.autoDispose<Station>((_) => Station.raw);

/// Inventory as one journey: supplier → raw material → making → ready goods → client.
/// The thread at the top is both the picture and the navigation.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final flow = ref.watch(flowProvider);
    final station = ref.watch(selectedStationProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: SutraColors.sindoor,
          onRefresh: () => ref.refresh(flowProvider.future),
          child: AsyncView<FlowSummary>(
            value: flow,
            strings: s,
            onRetry: () => ref.invalidate(flowProvider),
            data: (f) => ListView(
              padding: SutraSpace.page,
              children: [
                Text(s.tr(InvText.title), style: SutraType.display(28)),
                const SizedBox(height: 14),
                FlowPipeline(
                  stations: stationsFor(f, s),
                  selected: station.index,
                  onTap: (i) => ref.read(selectedStationProvider.notifier).state = Station.values[i],
                ),
                _Hint(text: s.tr(_hint(station, f.isTrader))),
                const SizedBox(height: 12),
                switch (station) {
                  Station.supplier => _SuppliersView(flow: f, strings: s),
                  Station.raw => _RawView(flow: f, strings: s),
                  Station.making => _ProductsView(flow: f, strings: s, making: true),
                  Station.ready => _ProductsView(flow: f, strings: s, making: false),
                  Station.client => _ClientsView(flow: f, strings: s),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  static T _hint(Station s, bool trader) => switch (s) {
        Station.supplier => InvText.supplierHint,
        Station.raw => InvText.rawHint,
        Station.making => trader ? InvText.traderMakingHint : InvText.makingHint,
        Station.ready => InvText.readyHint,
        Station.client => InvText.clientHint,
      };
}

/// The five stations with the number that matters at each (also used on the home screen).
List<FlowStation> stationsFor(FlowSummary f, AppStrings s) => [
      FlowStation(icon: Icons.local_shipping_outlined, label: s.tr(InvText.supplier), value: '${f.suppliers}'),
      FlowStation(icon: Icons.inventory_2_outlined, label: s.tr(InvText.raw), value: '${f.rawItems}', alert: f.rawLow > 0, enabled: !f.isTrader),
      FlowStation(icon: Icons.handyman_outlined, label: s.tr(InvText.making), value: Fmt.qty(f.madeThisWeek), enabled: !f.isTrader),
      FlowStation(icon: Icons.checkroom_outlined, label: s.tr(InvText.ready), value: '${f.readyUnits}'),
      FlowStation(icon: Icons.storefront_outlined, label: s.tr(InvText.client), value: '${f.clients}'),
    ];

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: SutraMotion.normal,
      child: Container(
        key: ValueKey(text),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(color: SutraColors.haldiWash, borderRadius: BorderRadius.all(SutraRadius.sm)),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 18, color: SutraColors.haldiDeep),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: SutraColors.haldiDeep, fontSize: 13.5, height: 1.4))),
          ],
        ),
      ),
    );
  }
}

/// A big total line on top of a station ("To pay ₹18,400").
class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.label, required this.value, this.action});
  final String label;
  final Widget value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 10),
          value,
          const Spacer(),
          ?action,
        ],
      ),
    );
  }
}

class _RawView extends ConsumerWidget {
  const _RawView({required this.flow, required this.strings});
  final FlowSummary flow;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalBar(
          label: strings.kpiStockValue,
          value: AmountText(flow.rawValue, size: 20),
          action: TextButton.icon(onPressed: () => showAddMaterialSheet(context), icon: const Icon(Icons.add_rounded), label: Text(strings.tr(InvText.addMaterial))),
        ),
        LedgerCard(
          padding: const EdgeInsets.fromLTRB(34, 4, 12, 4),
          child: Column(
            children: [
              for (final (i, m) in flow.materials.indexed) ...[
                if (i > 0) const Divider(),
                MaterialRow(
                  material: m,
                  strings: strings,
                  onTap: () => showMaterialActions(context, m),
                  trailing: FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    onPressed: () => showStockInSheet(context, m),
                    child: Text(strings.tr(InvText.stockIn)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductsView extends ConsumerWidget {
  const _ProductsView({required this.flow, required this.strings, required this.making});
  final FlowSummary flow;
  final AppStrings strings;
  final bool making;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    if (making && flow.isTrader) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalBar(
          label: making ? strings.tr(InvText.madeThisWeek) : strings.kpiStockValue,
          value: making ? Text(Fmt.qty(flow.madeThisWeek), style: SutraType.figure(20)) : AmountText(flow.readyValue, size: 20),
          action: TextButton.icon(onPressed: () => showAddProductSheet(context, flow), icon: const Icon(Icons.add_rounded), label: Text(strings.tr(InvText.addProduct))),
        ),
        LedgerCard(
          padding: const EdgeInsets.fromLTRB(34, 4, 12, 4),
          child: Column(
            children: [
              for (final (i, p) in flow.products.indexed) ...[
                if (i > 0) const Divider(),
                _ProductRow(product: p, strings: strings, making: making, text: text),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.strings, required this.making, required this.text});
  final ProductStock product;
  final AppStrings strings;
  final bool making;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return InkWell(
      onTap: () => showProductActions(context, p),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            WovenSwatch(palette: p.palette, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.pick(p.nameHi, p.name), style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text('${p.stock} ${strings.ready} · ${Fmt.inr(p.price)}', style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            making
                ? FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14), backgroundColor: SutraColors.neelWash, foregroundColor: SutraColors.neelDeep),
                    onPressed: () => showMakeSheet(context, p),
                    child: Text(strings.tr(InvText.made)),
                  )
                : FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    onPressed: p.stock > 0 ? () => showSellSheet(context, p) : null,
                    child: Text(strings.tr(InvText.sold)),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SuppliersView extends ConsumerWidget {
  const _SuppliersView({required this.flow, required this.strings});
  final FlowSummary flow;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalBar(
          label: strings.tr(InvText.toPay),
          value: AmountText(flow.toPay, size: 20, incoming: false),
          action: TextButton.icon(onPressed: () => showAddPartnerSheet(context, supplier: true), icon: const Icon(Icons.add_rounded), label: Text(strings.tr(InvText.addSupplier))),
        ),
        _PartnerList(provider: suppliersProvider, strings: strings, supplier: true),
      ],
    );
  }
}

class _ClientsView extends ConsumerWidget {
  const _ClientsView({required this.flow, required this.strings});
  final FlowSummary flow;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalBar(
          label: strings.tr(InvText.toReceive),
          value: AmountText(flow.toReceive, size: 20, incoming: true),
          action: TextButton.icon(onPressed: () => showAddPartnerSheet(context, supplier: false), icon: const Icon(Icons.add_rounded), label: Text(strings.tr(InvText.addClient))),
        ),
        _PartnerList(provider: clientsProvider, strings: strings, supplier: false),
      ],
    );
  }
}

class _PartnerList extends ConsumerWidget {
  const _PartnerList({required this.provider, required this.strings, required this.supplier});
  final AutoDisposeFutureProvider<List<Partner>> provider;
  final AppStrings strings;
  final bool supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return AsyncView<List<Partner>>(
      value: ref.watch(provider),
      strings: strings,
      onRetry: () => ref.invalidate(provider),
      data: (list) => list.isEmpty
          ? Padding(padding: const EdgeInsets.all(24), child: Text(strings.tr(InvText.none), textAlign: TextAlign.center))
          : LedgerCard(
              padding: const EdgeInsets.fromLTRB(34, 4, 8, 4),
              child: Column(
                children: [
                  for (final (i, p) in list.indexed) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: InitialsBadge(name: p.display, color: supplier ? SutraColors.haldiDeep : SutraColors.neel, size: 40),
                      title: Text(p.display, style: text.titleSmall),
                      subtitle: Text([p.city, if (supplier && p.leadTimeDays != null) '${p.leadTimeDays} ${strings.tr(InvText.leadDays)}'].where((x) => x.isNotEmpty).join(' · ')),
                      trailing: p.phone.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.chat_outlined, color: SutraColors.neel),
                              onPressed: () => ref.read(linkLauncherProvider).open('https://wa.me/${p.phone.replaceAll(RegExp(r'\D'), '')}'),
                            ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
