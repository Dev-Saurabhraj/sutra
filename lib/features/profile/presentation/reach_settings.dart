import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/common_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/form_bits.dart';
import '../../../design/widgets/sheet_form.dart';
import '../../auth/presentation/session_controller.dart';
import '../../shell/reach.dart';

/// X4 (DPDP): take all your data with you, or delete the account. Used by makers, buyers and cluster admins.
class PrivacyActions extends ConsumerStatefulWidget {
  const PrivacyActions({super.key});

  @override
  ConsumerState<PrivacyActions> createState() => _PrivacyActionsState();
}

class _PrivacyActionsState extends ConsumerState<PrivacyActions> {
  bool _busy = false;

  Future<void> _download() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final j = await ref.read(apiClientProvider).get('/me/export');
      final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(j)));
      final name = 'sutra-data-${DateTime.now().toIso8601String().substring(0, 10)}.json';
      await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: 'application/json')], fileNameOverrides: [name]));
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.tr(CommonText.deleteSure)),
        content: Text(s.tr(CommonText.deleteBody)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: SutraColors.kumkum), onPressed: () => Navigator.pop(ctx, true), child: Text(s.tr(CommonText.deleteYes))),
        ],
      ),
    );
    if (sure != true) return;
    try {
      final r = await ref.read(apiClientProvider).delete('/me');
      await ref.read(tokenStoreProvider).clear();
      ref.read(sessionControllerProvider.notifier).expired();
      messenger.showSnackBar(SnackBar(content: Text(s.isHindi ? '${r['keptHi'] ?? ''}' : '${r['kept'] ?? ''}')));
    } catch (e) {
      final err = ApiException.from(e);
      messenger.showSnackBar(SnackBar(content: Text(s.isHindi ? (err.messageHi ?? err.message) : err.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(onPressed: _busy ? null : _download, icon: const Icon(Icons.download_outlined), label: Text(s.tr(CommonText.download))),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: SutraColors.kumkum),
          onPressed: _delete,
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(s.tr(CommonText.deleteAccount)),
        ),
      ],
    );
  }
}

/// X5 switch: read new alerts aloud.
class VoiceAlertsSwitch extends ConsumerWidget {
  const VoiceAlertsSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: SutraColors.neel,
      value: ref.watch(voiceAlertsProvider),
      onChanged: (v) => ref.read(voiceAlertsProvider.notifier).set(v),
      title: Text(s.tr(CommonText.voiceAlerts)),
      subtitle: Text(s.tr(CommonText.voiceAlertsSub)),
    );
  }
}

/// P26: hand the phone to a helper. Asks for a 4-digit owner PIN.
class HelperModeCard extends ConsumerWidget {
  const HelperModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr(CommonText.helperSub), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showSutraSheet<void>(context, const PinSheet(start: true)),
          icon: const Icon(Icons.supervisor_account_outlined),
          label: Text(s.tr(CommonText.startHelper)),
        ),
      ],
    );
  }
}

/// Set the PIN (start helper mode) or enter it (owner unlock).
class PinSheet extends ConsumerStatefulWidget {
  const PinSheet({super.key, required this.start});
  final bool start;

  @override
  ConsumerState<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends ConsumerState<PinSheet> {
  String _pin = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SheetForm(
      title: s.tr(widget.start ? CommonText.helperMode : CommonText.unlock),
      subtitle: widget.start ? s.tr(CommonText.helperSub) : null,
      saveLabel: s.tr(widget.start ? CommonText.startHelper : CommonText.unlock),
      canSave: RegExp(r'^\d{4}$').hasMatch(_pin),
      onSave: () async {
        final ctrl = ref.read(helperModeProvider.notifier);
        if (widget.start) {
          await ctrl.start(_pin);
          return s.tr(CommonText.helperOn);
        }
        if (!await ctrl.unlock(_pin)) throw ApiException(code: 'WRONG_PIN', message: s.tr(CommonText.wrongPin), messageHi: s.tr(CommonText.wrongPin));
        return null;
      },
      children: [
        TextField(
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: s.tr(widget.start ? CommonText.setPin : CommonText.enterPin), counterText: ''),
          onChanged: (v) => setState(() => _pin = v),
        ),
      ],
    );
  }
}
