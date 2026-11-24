import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../core/format/formatters.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/sheet_form.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';
import '../../money/money_text.dart';
import 'order_text.dart';

/// Goods leave: who carries them, the LR number, and a photo of the packed goods as proof.
class DispatchSheet extends ConsumerStatefulWidget {
  const DispatchSheet({super.key, required this.code, required this.order});
  final String code;
  final Order order;

  @override
  ConsumerState<DispatchSheet> createState() => _DispatchSheetState();
}

class _DispatchSheetState extends ConsumerState<DispatchSheet> {
  final _transporter = TextEditingController();
  final _lr = TextEditingController();
  final _vehicle = TextEditingController();
  DispatchPhoto? _photo;

  @override
  void dispose() {
    _transporter.dispose();
    _lr.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photo = DispatchPhoto(bytes: bytes, mediaType: file.mimeType ?? (file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg')));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final o = widget.order;
    return SheetForm(
      kicker: '${o.code} · ${o.qty} ${s.tr(OrderText.pieces)} · ${Fmt.inr(o.value)}',
      title: s.tr(OrderText.dispatchTitle),
      subtitle: s.tr(OrderText.dispatchSub),
      saveLabel: s.tr(OrderText.dispatch),
      saveColor: SutraColors.sindoor,
      onSave: () async {
        await ref.read(orderControllerProvider(widget.code).notifier).dispatch(transporter: _transporter.text, lrNumber: _lr.text, vehicleNo: _vehicle.text, photo: _photo);
        ref.invalidate(ewayBillProvider(widget.code));
        return s.tr(OrderText.dispatched);
      },
      children: [
        TextField(controller: _transporter, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(OrderText.transporter))),
        const SizedBox(height: 12),
        TextField(controller: _lr, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: s.tr(OrderText.lr))),
        const SizedBox(height: 12),
        TextField(controller: _vehicle, textCapitalization: TextCapitalization.characters, maxLength: 15, decoration: InputDecoration(labelText: s.tr(MoneyText.vehicle), counterText: '')),
        // X6: say up front if this consignment needs an e-way bill
        ref.watch(ewayBillProvider(widget.code)).maybeWhen(
              data: (e) => e['required'] == true
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${s.tr(MoneyText.ewayNeeded)}: ${s.pick(e['reasonHi'] as String, e['reasonEn'] as String)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SutraColors.kumkum, fontWeight: FontWeight.w600)),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        const SizedBox(height: 14),
        Text(s.tr(OrderText.proofPhoto), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_photo != null) ...[
              ClipRRect(borderRadius: const BorderRadius.all(SutraRadius.sm), child: Image.memory(_photo!.bytes, width: 72, height: 72, fit: BoxFit.cover)),
              const SizedBox(width: 12),
            ],
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(s.tr(_photo == null ? OrderText.addPhoto : OrderText.changePhoto)),
            ),
          ],
        ),
      ],
    );
  }
}
