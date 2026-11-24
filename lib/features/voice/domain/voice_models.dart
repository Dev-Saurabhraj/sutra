class VoiceActionView {
  const VoiceActionView({required this.kind, required this.label, required this.labelHi, this.effect, this.effectHi, this.warning, this.warningHi, this.blockedEn, this.blockedHi});

  final String kind;
  final String label;
  final String labelHi;
  final String? effect;
  final String? effectHi;
  final String? warning;
  final String? warningHi;
  final String? blockedEn;
  final String? blockedHi;

  bool get blocked => blockedEn != null;

  factory VoiceActionView.fromJson(Map<String, dynamic> j) {
    final blocked = j['blocked'] as Map<String, dynamic>?;
    return VoiceActionView(
      kind: j['kind'] as String,
      label: j['label'] as String,
      labelHi: j['labelHi'] as String,
      effect: j['effect'] as String?,
      effectHi: j['effectHi'] as String?,
      warning: j['warning'] as String?,
      warningHi: j['warningHi'] as String?,
      blockedEn: blocked?['en'] as String?,
      blockedHi: blocked?['hi'] as String?,
    );
  }
}

class VoicePreview {
  const VoicePreview({required this.entryId, required this.transcript, required this.replyHi, required this.parser, required this.canSave, required this.actions});

  final String entryId;
  final String transcript;
  final String replyHi;
  final String parser;
  final bool canSave;
  final List<VoiceActionView> actions;

  factory VoicePreview.fromJson(Map<String, dynamic> j) => VoicePreview(
        entryId: j['entryId'] as String,
        transcript: j['transcript'] as String,
        replyHi: j['replyHi'] as String,
        parser: j['parser'] as String,
        canSave: j['canSave'] as bool,
        actions: (j['actions'] as List).map((e) => VoiceActionView.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class VoiceResult {
  const VoiceResult({required this.text, required this.textHi, this.invoiceNumber});

  final String text;
  final String textHi;
  final String? invoiceNumber;

  factory VoiceResult.fromJson(Map<String, dynamic> j) => VoiceResult(
        text: j['text'] as String,
        textHi: j['textHi'] as String,
        invoiceNumber: (j['invoice'] as Map<String, dynamic>?)?['number'] as String?,
      );
}

abstract interface class VoiceRepository {
  Future<VoicePreview> preview(String transcript);
  Future<List<VoiceResult>> confirm(String entryId);
}
