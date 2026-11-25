import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/charkha_mic.dart';
import '../../../design/widgets/parchi.dart';
import '../../../design/widgets/stamp.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/voice_examples.dart';
import '../domain/voice_models.dart';
import '../../../core/l10n/common_text.dart';
import '../../shell/reach.dart';
import 'voice_controller.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final v = ref.watch(voiceControllerProvider);
    final ctrl = ref.read(voiceControllerProvider.notifier);
    final industry = ref.watch(meProvider)?.producer?.industry.key;
    if (_text.text != v.transcript) _text.text = v.transcript;

    final status = !v.micAvailable ? s.micUnavailable : (v.phase == VoicePhase.listening ? s.listening : s.tapToSpeak);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: SutraSpace.page,
          children: [
            Text(s.voiceTitle, style: SutraType.display(28)),
            const SizedBox(height: 24),
            Center(
              child: CharkhaMic(
                listening: v.phase == VoicePhase.listening,
                enabled: v.micAvailable && !v.busy,
                onTap: ctrl.toggleMic,
                semanticLabel: status,
              ),
            ),
            const SizedBox(height: 12),
            Text(status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    onChanged: ctrl.setText,
                    onSubmitted: (_) => ctrl.understand(),
                    textInputAction: TextInputAction.go,
                    decoration: InputDecoration(hintText: s.typeHere),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size(72, 52)),
                  onPressed: v.busy || v.transcript.trim().isEmpty ? null : () => ctrl.understand(),
                  child: v.phase == VoicePhase.understanding
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(s.understand),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(s.tryThese, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in VoiceExamples.forIndustry(industry))
                  ActionChip(
                    label: Text('“$e”'),
                    backgroundColor: SutraColors.card,
                    side: const BorderSide(color: SutraColors.rule),
                    onPressed: v.busy ? null : () => ctrl.understand(e),
                  ),
              ],
            ),
            if (v.error != null) ...[
              const SizedBox(height: 16),
              _Note(text: s.isHindi ? (v.error!.messageHi ?? v.error!.message) : v.error!.message),
            ],
            if (v.preview != null) ...[
              const SizedBox(height: 22),
              _PreviewSlip(preview: v.preview!, strings: s, saving: v.phase == VoicePhase.saving, onYes: ctrl.confirm, onNo: ctrl.discard),
            ],
            if (v.phase == VoicePhase.saved) ...[
              const SizedBox(height: 22),
              _SavedSlip(results: v.results, strings: s),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewSlip extends ConsumerWidget {
  const _PreviewSlip({required this.preview, required this.strings, required this.saving, required this.onYes, required this.onNo});

  final VoicePreview preview;
  final AppStrings strings;
  final bool saving;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final helperMoney = ref.watch(helperModeProvider) && preview.actions.any((a) => helperMoneyKinds.contains(a.kind));
    final canSave = preview.canSave && !helperMoney;
    return Parchi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.readBy, style: text.labelSmall),
          Text('“${preview.transcript}”', style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: SutraColors.inkSoft)),
          const SizedBox(height: 8),
          Text(strings.shallIWrite, style: SutraType.display(22)),
          const SizedBox(height: 10),
          for (final a in preview.actions) _ActionLine(action: a, strings: strings),
          if (helperMoney)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(strings.tr(CommonText.helperNoMoney), style: text.bodySmall?.copyWith(color: SutraColors.kumkum))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: saving ? null : onNo, child: Text(strings.wrong))),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: saving || !canSave ? null : onYes,
                  icon: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.edit_note_rounded),
                  label: Text(canSave ? strings.yesWrite : strings.cannotSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.action, required this.strings});
  final VoiceActionView action;
  final AppStrings strings;

  (String, Tone) get _stamp => switch (action.kind) {
        'PRODUCE' => (strings.kindMade, Tone.ok),
        'SALE' => (strings.kindSold, Tone.due),
        'PURCHASE' => (strings.kindBought, Tone.low),
        _ => (strings.kindMoney, Tone.neutral),
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (label, tone) = _stamp;
    final effect = strings.isHindi ? action.effectHi : action.effect;
    final warning = strings.isHindi ? action.warningHi : action.warning;
    final blocked = strings.isHindi ? action.blockedHi : action.blockedEn;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blocked != null ? const Color(0xFFFDECEC) : SutraColors.paper,
        borderRadius: const BorderRadius.all(SutraRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64, child: Align(alignment: Alignment.topLeft, child: Stamp(label, tone: tone, size: 10))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.pick(action.labelHi, action.label), style: text.titleSmall),
                if (effect != null) Text(effect, style: text.bodySmall),
                if (warning != null) _Inline(icon: Icons.info_outline_rounded, color: SutraColors.haldiDeep, text: warning),
                if (blocked != null) _Inline(icon: Icons.block_rounded, color: SutraColors.kumkum, text: blocked),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedSlip extends StatelessWidget {
  const _SavedSlip({required this.results, required this.strings});
  final List<VoiceResult> results;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Parchi(
      color: const Color(0xFFF1F8F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stamp(strings.written, tone: Tone.ok, thunk: true, size: 15),
          const SizedBox(height: 14),
          for (final r in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_rounded, color: SutraColors.neel, size: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(strings.pick(r.textHi, r.text), style: text.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Inline extends StatelessWidget {
  const _Inline({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(color: SutraColors.haldiWash, borderRadius: BorderRadius.all(SutraRadius.md)),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SutraColors.haldiDeep)),
    );
  }
}
