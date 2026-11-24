import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/tokens.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';
import 'order_text.dart';

/// Messages as letters on slips, not chat bubbles: the buyer's on the left on neel-washed paper,
/// yours on the right on haldi paper. A translated letter says so and shows the original on tap.
class OrderLetters extends StatelessWidget {
  const OrderLetters({super.key, required this.messages, required this.strings});
  final List<OrderMessage> messages;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in messages) Padding(padding: const EdgeInsets.only(bottom: 10), child: _Letter(message: m, strings: strings)),
      ],
    );
  }
}

class _Letter extends StatefulWidget {
  const _Letter({required this.message, required this.strings});
  final OrderMessage message;
  final AppStrings strings;

  @override
  State<_Letter> createState() => _LetterState();
}

class _LetterState extends State<_Letter> {
  bool _original = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final s = widget.strings;
    final text = Theme.of(context).textTheme;
    final mine = !m.fromBuyer;
    // the buyer's letter is translated for you; yours is translated for the buyer
    final shown = mine ? m.text : (_original ? m.text : m.forProducer(s.isHindi));
    final note = mine
        ? (m.translated ? null : s.tr(OrderText.notTranslated))
        : (m.translated && s.isHindi ? s.tr(OrderText.translatedFrom) : null);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: mine ? SutraColors.haldiWash : SutraColors.neelWash,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 3),
              bottomRight: Radius.circular(mine ? 3 : 14),
            ),
            border: Border(left: BorderSide(color: mine ? SutraColors.haldiDeep : SutraColors.neel, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shown, style: text.bodyMedium?.copyWith(height: 1.45)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [if (mine) s.tr(OrderText.you), Fmt.ago(m.at, hindi: s.isHindi), ?note].join(' · '),
                      style: text.labelSmall?.copyWith(color: SutraColors.inkSoft),
                      maxLines: 2,
                    ),
                  ),
                  if (!mine && m.translated && s.isHindi)
                    InkWell(
                      onTap: () => setState(() => _original = !_original),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(s.tr(_original ? OrderText.showTranslation : OrderText.showOriginal),
                            style: text.labelSmall?.copyWith(color: SutraColors.neel, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Write a reply. Hindi is fine: the buyer gets English when translation is on.
class LetterComposer extends ConsumerStatefulWidget {
  const LetterComposer({super.key, required this.code, required this.strings});
  final String code;
  final AppStrings strings;

  @override
  ConsumerState<LetterComposer> createState() => _LetterComposerState();
}

class _LetterComposerState extends ConsumerState<LetterComposer> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final s = widget.strings;
    setState(() => _busy = true);
    try {
      await ref.read(orderControllerProvider(widget.code).notifier).send(t);
      _text.clear();
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            minLines: 1,
            maxLines: 4,
            maxLength: 1000,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(hintText: s.tr(OrderText.writeHint), counterText: ''),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size(52, 52)),
          tooltip: s.tr(OrderText.send),
          onPressed: _busy ? null : _send,
          icon: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}
