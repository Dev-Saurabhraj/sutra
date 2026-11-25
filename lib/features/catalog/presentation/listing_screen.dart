import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/art/scan_thread.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/async_view.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/product_thumb.dart';
import '../../orders/presentation/order_screen.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_models.dart';
import 'catalog_text.dart';

/// Photo → your words → what buyers read → price. One screen, four numbered steps.
class ListingScreen extends ConsumerWidget {
  const ListingScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.tr(CatalogText.title))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: AsyncView<CatalogList>(
              value: ref.watch(catalogProvider),
              strings: s,
              onRetry: () => ref.invalidate(catalogProvider),
              data: (c) {
                final item = c.items.where((i) => i.id == productId).firstOrNull;
                if (item == null) return ErrorNote(error: ApiException(code: 'NOT_FOUND', message: 'Product not found'), strings: s);
                return _Editor(key: ValueKey(item.id), item: item, strings: s);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.item, required this.strings});
  final CatalogItem item;
  final AppStrings strings;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _story = TextEditingController(text: widget.item.story);
  final _note = TextEditingController();
  late double _price = widget.item.price;
  CatalogPhoto? _photo;
  String? _imageUrl;
  String? _writer;
  bool _drafting = false;
  bool _saving = false;

  AppStrings get s => widget.strings;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.item.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _story.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 2000, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photo = CatalogPhoto(bytes: bytes, mediaType: file.mimeType ?? (file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg')));
  }

  Future<void> _draft() async {
    setState(() => _drafting = true);
    try {
      final d = await ref.read(catalogRepositoryProvider).draft(widget.item.id, note: _note.text.trim(), photo: _photo);
      final template = d.writer == 'template';
      final keepStory = template && _story.text.trim().isNotEmpty;
      setState(() {
        _imageUrl = d.imageUrl;
        _photo = null; // the cleaned photo is now the product's photo
        if (!template || _name.text.trim().isEmpty) _name.text = d.title;
        if (!keepStory) _story.text = d.story;
        _writer = d.writer;
      });
      if (keepStory && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.tr(CatalogText.keptStory))));
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  Future<void> _save({required bool publish, bool acceptBelowCost = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(catalogRepositoryProvider).update(
            widget.item.id,
            name: _name.text.trim(),
            story: _story.text.trim(),
            price: _price,
            published: publish,
            acceptBelowCost: acceptBelowCost,
          );
      ref.invalidate(catalogProvider);
      messenger.showSnackBar(SnackBar(content: Text(s.tr(publish ? CatalogText.published : CatalogText.saved))));
    } on Object catch (e) {
      final err = ApiException.from(e);
      if (err.code == 'BELOW_COST' && mounted) {
        final anyway = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(s.tr(CatalogText.belowCostTitle)),
            content: Text(err.message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.tr(CatalogText.fixPrice))),
              TextButton(style: TextButton.styleFrom(foregroundColor: SutraColors.kumkum), onPressed: () => Navigator.pop(ctx, true), child: Text(s.tr(CatalogText.belowCostAnyway))),
            ],
          ),
        );
        if (anyway == true) return _save(publish: publish, acceptBelowCost: true);
      } else {
        _toast(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(Object e) {
    final err = ApiException.from(e);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final text = Theme.of(context).textTheme;
    final check = i.price0.at(_price);
    return ListView(
      padding: SutraSpace.page,
      children: [
        _Step(s.tr(CatalogText.step1)),
        ClipRRect(
          borderRadius: const BorderRadius.all(SutraRadius.md),
          child: AspectRatio(
            aspectRatio: 1,
            child: ScanThread(
              active: _drafting && _photo != null,
              child: _photo != null
                  ? Image.memory(_photo!.bytes, fit: BoxFit.cover)
                  : LayoutBuilder(builder: (_, box) => ProductThumb(palette: i.palette, imageUrl: _imageUrl, size: box.maxWidth, radius: Radius.zero)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: _drafting ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: Text(s.tr(CatalogText.camera)))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: _drafting ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: Text(s.tr(CatalogText.gallery)))),
          ],
        ),
        const SizedBox(height: 4),
        Text(s.tr(CatalogText.cleanNote), style: text.labelSmall?.copyWith(color: SutraColors.inkSoft)),

        _Step(s.tr(CatalogText.step2)),
        TextField(controller: _note, minLines: 2, maxLines: 4, maxLength: 600, decoration: InputDecoration(hintText: s.tr(CatalogText.noteHint), counterText: '')),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: SutraColors.neel),
          onPressed: _drafting ? null : _draft,
          icon: _drafting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : const Icon(Icons.edit_note_rounded),
          label: Text(s.tr(_drafting ? CatalogText.writing : CatalogText.makeStory)),
        ),

        _Step(s.tr(CatalogText.step3)),
        if (_writer != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.tr(_writer == 'template' ? CatalogText.byTemplate : CatalogText.byClaude),
                style: text.labelSmall?.copyWith(color: _writer == 'template' ? SutraColors.haldiDeep : SutraColors.neel, fontWeight: FontWeight.w700)),
          ),
        TextField(controller: _name, maxLength: 80, decoration: InputDecoration(labelText: s.tr(CatalogText.name), counterText: '')),
        const SizedBox(height: 10),
        TextField(controller: _story, minLines: 4, maxLines: 10, maxLength: 1200, decoration: InputDecoration(labelText: s.tr(CatalogText.story), alignLabelWithHint: true)),

        _Step(s.tr(CatalogText.step4)),
        NumberField(label: s.tr(CatalogText.listPrice), initial: _price, prefix: '₹ ', onChanged: (v) => setState(() => _price = v ?? i.price)),
        const SizedBox(height: 12),
        PriceFloorCard(price: check, strings: s),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: SutraColors.sindoor, minimumSize: const Size.fromHeight(52)),
          onPressed: _saving || _drafting ? null : () => _save(publish: true),
          child: _saving
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(s.tr(CatalogText.publish)),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _saving || _drafting ? null : () => _save(publish: false),
          child: Text(s.tr(i.published ? CatalogText.unpublish : CatalogText.save)),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(2, 20, 2, 8), child: Text(label, style: SutraType.display(16)));
}
