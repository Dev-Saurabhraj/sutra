import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/common_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/outbox.dart';
import '../tokens.dart';
import 'form_bits.dart';

/// A form on a paper slip with one big save button. Handles busy state, errors, closing,
/// and a confirmation message — so each feature sheet only describes its fields and what "save" does.
class SheetForm extends ConsumerStatefulWidget {
  const SheetForm({super.key, required this.title, this.kicker, this.subtitle, required this.children, required this.saveLabel, required this.onSave, this.canSave = true, this.saveColor});

  final String title;
  final String? kicker;
  final String? subtitle;
  final List<Widget> children;
  final String saveLabel;
  final bool canSave;
  final Color? saveColor;

  /// Does the work; returns a short message to show after closing (or null for none).
  final Future<String?> Function() onSave;

  @override
  ConsumerState<SheetForm> createState() => _SheetFormState();
}

class _SheetFormState extends ConsumerState<SheetForm> {
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final done = await widget.onSave();
      navigator.pop();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on SavedOffline {
      // no network: the entry waits on the phone and goes out by itself later
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(s.tr(CommonText.savedOffline))));
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) setState(() => _error = s.isHindi ? (err.messageHi ?? err.message) : err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title: widget.title, kicker: widget.kicker, subtitle: widget.subtitle),
        ...widget.children,
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: SutraColors.kumkum))),
        const SizedBox(height: 18),
        FilledButton(
          style: widget.saveColor == null ? null : FilledButton.styleFrom(backgroundColor: widget.saveColor),
          onPressed: _busy || !widget.canSave ? null : _save,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Text(widget.saveLabel),
        ),
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(s.cancel)),
      ],
    );
  }
}
