class KhataEntry {
  const KhataEntry({
    required this.id,
    required this.party,
    required this.incoming,
    required this.amount,
    required this.note,
    required this.dueDate,
    required this.settled,
    required this.overdueDays,
    required this.msmeDaysLeft,
  });

  final String id;
  final String party;

  /// true = they owe us (लेना), false = we owe them (देना).
  final bool incoming;
  final double amount;
  final String note;
  final DateTime? dueDate;
  final bool settled;
  final int overdueDays;
  final int? msmeDaysLeft;

  factory KhataEntry.fromJson(Map<String, dynamic> j) => KhataEntry(
        id: j['id'] as String,
        party: j['party'] as String,
        incoming: j['direction'] == 'RECEIVE',
        amount: (j['amount'] as num).toDouble(),
        note: j['note'] as String,
        dueDate: j['dueDate'] == null ? null : DateTime.parse(j['dueDate'] as String),
        settled: j['settled'] as bool,
        overdueDays: (j['overdueDays'] as num).toInt(),
        msmeDaysLeft: (j['msmeDaysLeft'] as num?)?.toInt(),
      );
}

class KhataPage {
  const KhataPage({required this.toReceive, required this.toPay, required this.entries});

  final double toReceive;
  final double toPay;
  final List<KhataEntry> entries;

  factory KhataPage.fromJson(Map<String, dynamic> j) {
    final totals = j['totals'] as Map<String, dynamic>;
    return KhataPage(
      toReceive: (totals['toReceive'] as num).toDouble(),
      toPay: (totals['toPay'] as num).toDouble(),
      entries: (j['entries'] as List).map((e) => KhataEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class Reminder {
  const Reminder({required this.messageHi, required this.messageEn, required this.whatsappUrl, required this.upiUrl});

  final String messageHi;
  final String messageEn;
  final String whatsappUrl;
  final String? upiUrl;

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        messageHi: j['messageHi'] as String,
        messageEn: j['messageEn'] as String,
        whatsappUrl: j['whatsappUrl'] as String,
        upiUrl: j['upiUrl'] as String?,
      );
}

abstract interface class KhataRepository {
  Future<KhataPage> page({required bool settled});
  Future<void> settle(String id);
  Future<Reminder> reminder(String id);
}
