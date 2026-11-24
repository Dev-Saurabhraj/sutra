import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/sheet_form.dart';
import '../../../design/widgets/stamp.dart';
import '../../home/data/home_repository.dart';
import '../../khata/data/khata_repository.dart';
import '../../labour/data/labour_repository.dart';
import '../../labour/domain/labour_models.dart';
import '../../stock/data/stock_repository.dart';
import '../../stock/domain/stock_models.dart';
import '../../stock/presentation/reorder_sheet.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_models.dart';
import 'inventory_text.dart';

/// Everything that shows stock, money or wages changes after an inventory action.
void refreshBusiness(WidgetRef ref) {
  ref
    ..invalidate(flowProvider)
    ..invalidate(homeProvider)
    ..invalidate(materialsProvider)
    ..invalidate(productsProvider)
    ..invalidate(suppliersProvider)
    ..invalidate(clientsProvider)
    ..invalidate(teamProvider)
    ..invalidate(khataPageProvider);
}

double _step(double v) => v >= 50 ? 5 : (v >= 5 ? 1 : 0.5);

// ---------------------------------------------------------------- raw material

Future<void> showStockInSheet(BuildContext context, MaterialHealth m) => showSutraSheet(context, _StockInSheet(material: m));

class _StockInSheet extends ConsumerStatefulWidget {
  const _StockInSheet({required this.material});
  final MaterialHealth material;

  @override
  ConsumerState<_StockInSheet> createState() => _StockInSheetState();
}

class _StockInSheetState extends ConsumerState<_StockInSheet> {
  late double _qty = widget.material.suggestedQty > 0 ? widget.material.suggestedQty : 1;
  late double? _rate = widget.material.costPerUnit;
  String? _supplierId;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final m = widget.material;
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? const <Partner>[];
    return SheetForm(
      kicker: s.tr(InvText.stockIn),
      title: s.pick(m.nameHi, m.name),
      saveLabel: s.tr(InvText.save),
      onSave: () async {
        await ref.read(inventoryRepositoryProvider).stockIn(m.id, qty: _qty, rate: _rate, supplierId: _supplierId);
        refreshBusiness(ref);
        return s.tr(InvText.saved);
      },
      children: [
        Text(s.tr(InvText.howMuch), style: Theme.of(context).textTheme.labelMedium),
        QtyStepper(value: _qty, unit: m.unit, step: _step(_qty), min: _step(_qty), onChanged: (v) => setState(() => _qty = v)),
        const SizedBox(height: 12),
        NumberField(label: '${s.tr(InvText.ratePer)} ${m.unit}', prefix: '₹ ', initial: _rate, onChanged: (v) => _rate = v),
        const SizedBox(height: 12),
        if (suppliers.isNotEmpty)
          DropdownButtonFormField<String?>(
            initialValue: _supplierId,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.tr(InvText.fromSupplier)),
            items: [
              DropdownMenuItem(value: null, child: Text(m.supplierName ?? '-')),
              for (final p in suppliers) DropdownMenuItem(value: p.id, child: Text(p.display)),
            ],
            onChanged: (v) => setState(() => _supplierId = v),
          ),
      ],
    );
  }
}

Future<void> showMaterialActions(BuildContext context, MaterialHealth m) {
  return showSutraSheet(
    context,
    Consumer(builder: (context, ref, _) {
      final s = ref.watch(stringsProvider);
      void then(Future<void> Function() open) {
        Navigator.of(context).pop();
        open();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title: s.pick(m.nameHi, m.name), subtitle: '${Fmt.qty(m.stock)} ${m.unit} · ${Fmt.inr(m.stockValue)}'),
          _ActionTile(icon: Icons.move_to_inbox_outlined, label: s.tr(InvText.stockIn), onTap: () => then(() => showStockInSheet(context, m))),
          if (m.supplierName != null) _ActionTile(icon: Icons.send_outlined, label: s.reorder, onTap: () => then(() => showReorderSheet(context, m))),
          _ActionTile(icon: Icons.fact_check_outlined, label: s.tr(InvText.count), onTap: () => then(() => _showCountSheet(context, materialId: m.id, name: s.pick(m.nameHi, m.name), current: m.stock, unit: m.unit))),
          _ActionTile(icon: Icons.history_rounded, label: s.tr(InvText.history), onTap: () => then(() => _showHistory(context, materialId: m.id, name: s.pick(m.nameHi, m.name)))),
        ],
      );
    }),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: SutraSpace.minTouch + 8,
        leading: Icon(icon, color: SutraColors.neel),
        title: Text(label, style: Theme.of(context).textTheme.titleSmall),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}

// ---------------------------------------------------------------- finished goods

Future<void> showProductActions(BuildContext context, ProductStock p) {
  return showSutraSheet(
    context,
    Consumer(builder: (context, ref, _) {
      final s = ref.watch(stringsProvider);
      final trader = ref.watch(flowProvider).valueOrNull?.isTrader ?? false;
      void then(Future<void> Function() open) {
        Navigator.of(context).pop();
        open();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title: s.pick(p.nameHi, p.name), subtitle: '${p.stock} ${s.ready} · ${Fmt.inr(p.price)}'),
          if (!trader) _ActionTile(icon: Icons.handyman_outlined, label: s.tr(InvText.made), onTap: () => then(() => showMakeSheet(context, p))),
          _ActionTile(icon: Icons.sell_outlined, label: s.tr(InvText.sold), onTap: () => then(() => showSellSheet(context, p))),
          _ActionTile(icon: Icons.fact_check_outlined, label: s.tr(InvText.count), onTap: () => then(() => _showCountSheet(context, productId: p.id, name: s.pick(p.nameHi, p.name), current: p.stock.toDouble(), unit: ''))),
          _ActionTile(icon: Icons.history_rounded, label: s.tr(InvText.history), onTap: () => then(() => _showHistory(context, productId: p.id, name: s.pick(p.nameHi, p.name)))),
        ],
      );
    }),
  );
}

Future<void> showMakeSheet(BuildContext context, ProductStock p) => showSutraSheet(context, _MakeSheet(product: p));

class _MakeSheet extends ConsumerStatefulWidget {
  const _MakeSheet({required this.product});
  final ProductStock product;

  @override
  ConsumerState<_MakeSheet> createState() => _MakeSheetState();
}

class _MakeSheetState extends ConsumerState<_MakeSheet> {
  double _qty = 1;
  String? _workerId;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final p = widget.product;
    final pieceWorkers = (ref.watch(teamProvider).valueOrNull?.workers ?? const <Worker>[]).where((w) => w.wageType == WageType.piece).toList();
    return SheetForm(
      kicker: s.tr(InvText.made),
      title: s.pick(p.nameHi, p.name),
      saveLabel: s.tr(InvText.save),
      saveColor: SutraColors.neel,
      onSave: () async {
        await ref.read(inventoryRepositoryProvider).produce(p.id, qty: _qty.round(), workerId: _workerId);
        refreshBusiness(ref);
        return s.tr(InvText.saved);
      },
      children: [
        QtyStepper(value: _qty, min: 1, onChanged: (v) => setState(() => _qty = v)),
        if (pieceWorkers.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(s.tr(InvText.whoMade), style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(label: Text(s.tr(InvText.nobody)), selected: _workerId == null, onSelected: (_) => setState(() => _workerId = null)),
              for (final w in pieceWorkers)
                ChoiceChip(label: Text('${w.name} · ${Fmt.inr(w.rate)}'), selected: _workerId == w.id, onSelected: (_) => setState(() => _workerId = w.id)),
            ],
          ),
        ],
      ],
    );
  }
}

Future<void> showSellSheet(BuildContext context, ProductStock p) => showSutraSheet(context, _SellSheet(product: p));

class _SellSheet extends ConsumerStatefulWidget {
  const _SellSheet({required this.product});
  final ProductStock product;

  @override
  ConsumerState<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends ConsumerState<_SellSheet> {
  double _qty = 1;
  late double? _rate = widget.product.price;
  String? _clientId;
  String _name = '';
  String _city = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final p = widget.product;
    final clients = ref.watch(clientsProvider).valueOrNull ?? const <Partner>[];
    return SheetForm(
      kicker: s.tr(InvText.sold),
      title: s.pick(p.nameHi, p.name),
      subtitle: '${p.stock} ${s.ready}',
      saveLabel: s.tr(InvText.save),
      onSave: () async {
        final r = await ref.read(inventoryRepositoryProvider).sell(p.id, qty: _qty.round(), rate: _rate, clientId: _clientId, walkInName: _name, walkInCity: _city);
        refreshBusiness(ref);
        return '${s.tr(InvText.billMade)}: ${r.invoiceNumber} · ${Fmt.inr(r.total)}';
      },
      children: [
        QtyStepper(value: _qty, min: 1, onChanged: (v) => setState(() => _qty = v)),
        const SizedBox(height: 12),
        NumberField(label: s.tr(InvText.price), prefix: '₹ ', initial: _rate, onChanged: (v) => _rate = v),
        const SizedBox(height: 14),
        Text(s.tr(InvText.toWhom), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in clients) ChoiceChip(label: Text(c.display), selected: _clientId == c.id, onSelected: (_) => setState(() => _clientId = c.id)),
            ChoiceChip(label: Text(s.tr(InvText.walkIn)), selected: _clientId == null, onSelected: (_) => setState(() => _clientId = null)),
          ],
        ),
        if (_clientId == null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(labelText: s.tr(InvText.walkInName)), onChanged: (v) => _name = v)),
              const SizedBox(width: 12),
              Expanded(child: TextField(decoration: InputDecoration(labelText: s.tr(InvText.walkInCity)), onChanged: (v) => _city = v)),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- add things

Future<void> showAddMaterialSheet(BuildContext context) => showSutraSheet(context, const _AddMaterialSheet());

class _AddMaterialSheet extends ConsumerStatefulWidget {
  const _AddMaterialSheet();

  @override
  ConsumerState<_AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends ConsumerState<_AddMaterialSheet> {
  String _name = '';
  String _unit = 'kg';
  double _cost = 0;
  double _stock = 0;
  String? _supplierId;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? const <Partner>[];
    return SheetForm(
      title: s.tr(InvText.addMaterial),
      saveLabel: s.tr(InvText.save),
      canSave: _name.trim().isNotEmpty && _unit.trim().isNotEmpty,
      onSave: () async {
        await ref.read(inventoryRepositoryProvider).addMaterial(name: _name.trim(), unit: _unit.trim(), cost: _cost, stock: _stock, supplierId: _supplierId);
        refreshBusiness(ref);
        return s.tr(InvText.saved);
      },
      children: [
        TextField(decoration: InputDecoration(labelText: s.tr(InvText.name)), onChanged: (v) => setState(() => _name = v)),
        const SizedBox(height: 10),
        TextFormField(initialValue: _unit, decoration: InputDecoration(labelText: s.tr(InvText.unit)), onChanged: (v) => setState(() => _unit = v)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: NumberField(label: s.tr(InvText.cost), prefix: '₹ ', initial: null, onChanged: (v) => _cost = v ?? 0)),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: s.tr(InvText.opening), initial: null, onChanged: (v) => _stock = v ?? 0)),
          ],
        ),
        if (suppliers.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: _supplierId,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.tr(InvText.fromSupplier)),
            items: [const DropdownMenuItem(value: null, child: Text('-')), for (final p in suppliers) DropdownMenuItem(value: p.id, child: Text(p.display))],
            onChanged: (v) => setState(() => _supplierId = v),
          ),
        ],
      ],
    );
  }
}

Future<void> showAddProductSheet(BuildContext context, FlowSummary flow) => showSutraSheet(context, _AddProductSheet(flow: flow));

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet({required this.flow});
  final FlowSummary flow;

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  String _name = '';
  double _price = 0;
  double _stock = 0;
  final Map<String, double> _recipe = {};

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SheetForm(
      title: s.tr(InvText.addProduct),
      saveLabel: s.tr(InvText.save),
      canSave: _name.trim().isNotEmpty && _price > 0,
      onSave: () async {
        await ref.read(inventoryRepositoryProvider).addProduct(name: _name.trim(), price: _price, stock: _stock.round(), recipe: {..._recipe}..removeWhere((_, v) => v <= 0));
        refreshBusiness(ref);
        return s.tr(InvText.saved);
      },
      children: [
        TextField(decoration: InputDecoration(labelText: s.tr(InvText.name)), onChanged: (v) => setState(() => _name = v)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: NumberField(label: s.tr(InvText.price), prefix: '₹ ', initial: null, onChanged: (v) => setState(() => _price = v ?? 0))),
            const SizedBox(width: 12),
            Expanded(child: NumberField(label: s.tr(InvText.opening), decimals: false, initial: null, onChanged: (v) => _stock = v ?? 0)),
          ],
        ),
        if (!widget.flow.isTrader && widget.flow.materials.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(s.tr(InvText.recipe), style: Theme.of(context).textTheme.labelMedium),
          for (final m in widget.flow.materials)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: NumberField(label: s.pick(m.nameHi, m.name), suffix: m.unit, initial: null, onChanged: (v) => _recipe[m.id] = v ?? 0),
            ),
        ],
      ],
    );
  }
}

Future<void> showAddPartnerSheet(BuildContext context, {required bool supplier}) => showSutraSheet(context, _AddPartnerSheet(supplier: supplier));

class _AddPartnerSheet extends ConsumerStatefulWidget {
  const _AddPartnerSheet({required this.supplier});
  final bool supplier;

  @override
  ConsumerState<_AddPartnerSheet> createState() => _AddPartnerSheetState();
}

class _AddPartnerSheetState extends ConsumerState<_AddPartnerSheet> {
  String _name = '';
  String _business = '';
  String _phone = '';
  String _city = '';
  double _lead = 7;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final repo = ref.read(inventoryRepositoryProvider);
    return SheetForm(
      title: s.tr(widget.supplier ? InvText.addSupplier : InvText.addClient),
      saveLabel: s.tr(InvText.save),
      canSave: _name.trim().isNotEmpty,
      onSave: () async {
        if (widget.supplier) {
          await repo.addSupplier(name: _name.trim(), phone: _phone.trim(), city: _city.trim(), leadTimeDays: _lead.round());
        } else {
          await repo.addClient(name: _name.trim(), business: _business.trim().isEmpty ? null : _business.trim(), phone: _phone.trim(), city: _city.trim());
        }
        refreshBusiness(ref);
        return s.tr(InvText.saved);
      },
      children: [
        TextField(textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(InvText.name)), onChanged: (v) => setState(() => _name = v)),
        if (!widget.supplier) ...[
          const SizedBox(height: 10),
          TextField(textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(InvText.business)), onChanged: (v) => _business = v),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.tr(InvText.phone)), onChanged: (v) => _phone = v)),
            const SizedBox(width: 12),
            Expanded(child: TextField(textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(InvText.city)), onChanged: (v) => _city = v)),
          ],
        ),
        if (widget.supplier) ...[
          const SizedBox(height: 14),
          Text(s.tr(InvText.leadDays), style: Theme.of(context).textTheme.labelMedium),
          QtyStepper(value: _lead, min: 0, onChanged: (v) => setState(() => _lead = v)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- count & history

Future<void> _showCountSheet(BuildContext context, {String? materialId, String? productId, required String name, required double current, required String unit}) {
  return showSutraSheet(
    context,
    Consumer(builder: (context, ref, _) {
      final s = ref.watch(stringsProvider);
      var actual = current;
      return SheetForm(
        kicker: s.tr(InvText.count),
        title: name,
        subtitle: '${Fmt.qty(current)} $unit',
        saveLabel: s.tr(InvText.save),
        onSave: () async {
          final repo = ref.read(inventoryRepositoryProvider);
          if (materialId != null) {
            await repo.adjustMaterial(materialId, actual);
          } else {
            await repo.adjustProduct(productId!, actual.round());
          }
          refreshBusiness(ref);
          return s.tr(InvText.saved);
        },
        children: [NumberField(label: s.tr(InvText.actualCount), suffix: unit, initial: current, onChanged: (v) => actual = v ?? current)],
      );
    }),
  );
}

Future<void> _showHistory(BuildContext context, {String? materialId, String? productId, required String name}) {
  return showSutraSheet(
    context,
    Consumer(builder: (context, ref, _) {
      final s = ref.watch(stringsProvider);
      final future = ref.read(inventoryRepositoryProvider).movements(materialId: materialId, productId: productId);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(kicker: s.tr(InvText.history), title: name),
          FutureBuilder<List<Movement>>(
            future: future,
            builder: (context, snap) {
              if (snap.hasError) return ErrorNote(error: snap.error!, strings: s);
              if (!snap.hasData) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              return Column(children: [for (final m in snap.data!) _MovementRow(movement: m, strings: s)]);
            },
          ),
        ],
      );
    }),
  );
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.strings});
  final Movement movement;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final m = movement;
    final (T label, Tone tone) = switch (m.kind) {
      'PURCHASE' => (InvText.kindPurchase, Tone.ok),
      'CONSUME' => (InvText.kindConsume, Tone.low),
      'PRODUCE' => (InvText.kindProduce, Tone.ok),
      'SALE' => (InvText.kindSale, Tone.due),
      _ => (InvText.kindAdjust, Tone.neutral),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 64, child: Align(alignment: Alignment.centerLeft, child: Stamp(strings.tr(label), tone: tone, size: 10))),
          Expanded(child: Text('${m.qty > 0 ? '+' : ''}${Fmt.qty(m.qty)} ${m.unit}${m.note == null ? '' : ' · ${m.note}'}', style: Theme.of(context).textTheme.bodyMedium)),
          Text(Fmt.shortDate(m.at, hindi: strings.isHindi), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
