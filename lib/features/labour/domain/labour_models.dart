enum WageType {
  daily,
  piece,
  monthly;

  static WageType parse(String s) => switch (s) {
        'PIECE' => WageType.piece,
        'MONTHLY' => WageType.monthly,
        _ => WageType.daily,
      };

  String get api => name.toUpperCase();
}

class Worker {
  const Worker({
    required this.id,
    required this.name,
    required this.phone,
    required this.skill,
    required this.wageType,
    required this.rate,
    required this.wageDue,
    required this.advancePending,
    required this.earnedThisPeriod,
    required this.overdue,
    required this.payBy,
    required this.todayUnits,
  });

  final String id;
  final String name;
  final String? phone;
  final String? skill;
  final WageType wageType;
  final double rate;

  /// Earned but not yet paid (negative = paid ahead).
  final double wageDue;

  /// Advance (peshgi) still to be recovered.
  final double advancePending;
  final double earnedThisPeriod;

  /// Part of the due amount whose legal pay-by date has passed.
  final double overdue;
  final DateTime payBy;

  /// Today's attendance: 1, 0.5, 0, or null if not marked.
  final double? todayUnits;

  factory Worker.fromJson(Map<String, dynamic> j) => Worker(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        skill: j['skill'] as String?,
        wageType: WageType.parse(j['wageType'] as String),
        rate: (j['rate'] as num).toDouble(),
        wageDue: (j['wageDue'] as num).toDouble(),
        advancePending: (j['advancePending'] as num).toDouble(),
        earnedThisPeriod: (j['earnedThisPeriod'] as num).toDouble(),
        overdue: (j['overdue'] as num).toDouble(),
        payBy: DateTime.parse((j['period'] as Map<String, dynamic>)['payBy'] as String),
        todayUnits: (j['todayUnits'] as num?)?.toDouble(),
      );
}

class TeamSummary {
  const TeamSummary({required this.workers, required this.wageDue, required this.overdue, required this.advancePending, required this.earnedThisPeriod, required this.presentToday});

  final List<Worker> workers;
  final double wageDue;
  final double overdue;
  final double advancePending;
  final double earnedThisPeriod;
  final int presentToday;

  factory TeamSummary.fromJson(Map<String, dynamic> j) {
    final t = j['totals'] as Map<String, dynamic>;
    return TeamSummary(
      workers: (j['workers'] as List).map((e) => Worker.fromJson(e as Map<String, dynamic>)).toList(),
      wageDue: (t['wageDue'] as num).toDouble(),
      overdue: (t['overdue'] as num).toDouble(),
      advancePending: (t['advancePending'] as num).toDouble(),
      earnedThisPeriod: (t['earnedThisPeriod'] as num).toDouble(),
      presentToday: (t['presentToday'] as num).toInt(),
    );
  }
}

/// How a wage payment splits: part adjusted against the advance (≤ 50% of the period's wages), the rest in hand.
class PayPreview {
  const PayPreview({required this.wageDue, required this.advancePending, required this.recovery, required this.cash});

  final double wageDue;
  final double advancePending;
  final double recovery;
  final double cash;

  factory PayPreview.fromJson(Map<String, dynamic> j) => PayPreview(
        wageDue: (j['wageDue'] as num).toDouble(),
        advancePending: (j['advancePending'] as num).toDouble(),
        recovery: (j['recovery'] as num).toDouble(),
        cash: (j['cash'] as num).toDouble(),
      );
}

class WageSlip {
  const WageSlip({required this.textHi, required this.textEn, required this.whatsappUrl});
  final String textHi;
  final String textEn;
  final String whatsappUrl;

  factory WageSlip.fromJson(Map<String, dynamic> j) =>
      WageSlip(textHi: j['textHi'] as String, textEn: j['textEn'] as String, whatsappUrl: j['whatsappUrl'] as String);
}

/// One line of a worker's history: work done (earning) or money given.
class LedgerItem {
  const LedgerItem({required this.kind, required this.amount, required this.at, this.units, this.note});

  /// ATTENDANCE | PIECE | WAGE | ADVANCE | RECOVERY
  final String kind;
  final double amount;
  final DateTime at;
  final double? units;
  final String? note;

  bool get isEarning => kind == 'ATTENDANCE' || kind == 'PIECE';
}

abstract interface class LabourRepository {
  Future<TeamSummary> team();
  Future<void> addWorker({required String name, String? phone, required WageType wageType, required double rate});
  Future<TeamSummary> markAttendance(Map<String, double> marks);
  Future<void> addPieceWork(String workerId, {required double qty});
  Future<PayPreview> payPreview(String workerId);
  Future<WageSlip> pay(String workerId, {required String mode, double? cash});
  Future<void> giveAdvance(String workerId, {required double amount, required String mode});
  Future<List<LedgerItem>> history(String workerId);
  Future<WageSlip> slip(String workerId);
}
