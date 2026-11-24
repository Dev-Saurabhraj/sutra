import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/parchi.dart';
import '../data/stock_repository.dart';
import '../domain/stock_models.dart';

/// Reorder slip: suggested quantity, supplier lead time, one tap to WhatsApp.
Future<void> showReorderSheet(BuildContext context, MaterialHealth material) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReorderSheet(material: material),
  );
}

class _ReorderSheet extends ConsumerStatefulWidget {
  const _ReorderSheet({required this.material});
  final MaterialHealth material;

  @override
  ConsumerState<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends ConsumerState<_ReorderSheet> {
  late double _qty = widget.material.suggestedQty > 0 ? widget.material.suggestedQty : 1;
  bool _busy = false;

  double get _step => _qty >= 50 ? 5 : (_qty >= 5 ? 1 : 0.5);

  Future<void> _send() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final r = await ref.read(stockRepositoryProvider).reorder(widget.material.id, _qty);
      await ref.read(linkLauncherProvider).open(r.whatsappUrl);
      ref.invalidate(materialsProvider);
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(s.reorderSent(r.eta))));
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final m = widget.material;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Parchi(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.reorderTitle, style: text.labelSmall),
              const SizedBox(height: 4),
              Text(s.pick(m.nameHi, m.name), style: SutraType.display(22)),
              if (m.supplierName != null)
                Text(s.supplierTakes(m.supplierName!, m.leadTimeDays), style: text.bodySmall),
              const SizedBox(height: 20),
              Text(s.quantity, style: text.labelMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StepButton(icon: Icons.remove_rounded, onTap: () => setState(() => _qty = (_qty - _step).clamp(_step, 100000))),
                  Expanded(
                    child: Text(
                      '${Fmt.qty(_qty)} ${m.unit}',
                      textAlign: TextAlign.center,
                      style: SutraType.figure(30, color: SutraColors.sindoorDeep),
                    ),
                  ),
                  _StepButton(icon: Icons.add_rounded, onTap: () => setState(() => _qty += _step)),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: SutraColors.neel),
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send_rounded),
                label: Text(s.sendOnWhatsApp),
              ),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
        onPressed: onTap,
        child: Icon(icon, size: 26),
      ),
    );
  }
}
