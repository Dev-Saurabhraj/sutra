import '../../orders/domain/order_models.dart';

class CapacityDay {
  const CapacityDay({required this.date, required this.machines, required this.off});
  final DateTime date;
  final int machines;
  final int off;
}

/// The next six weeks as machines working per day, and the entries that take machines off.
class CapacityCalendar {
  const CapacityCalendar({required this.machines, required this.machineLabel, required this.machineLabelHi, required this.days, required this.machineDaysLost, required this.events});
  final int machines;
  final String machineLabel;
  final String machineLabelHi;
  final List<CapacityDay> days;
  final int machineDaysLost;
  final List<CapacityEvent> events;

  factory CapacityCalendar.fromJson(Map<String, dynamic> j) => CapacityCalendar(
        machines: (j['machines'] as num).toInt(),
        machineLabel: j['machineLabel'] as String,
        machineLabelHi: j['machineLabelHi'] as String,
        days: [
          for (final d in (j['days'] as List).cast<Map<String, dynamic>>())
            CapacityDay(date: DateTime.parse(d['date'] as String), machines: (d['machines'] as num).toInt(), off: (d['off'] as num).toInt()),
        ],
        machineDaysLost: (j['machineDaysLost'] as num).toInt(),
        events: [for (final e in (j['events'] as List).cast<Map<String, dynamic>>()) CapacityEvent.fromJson(e)],
      );
}

/// An accepted order that the new days off make late.
class OrderAtRisk {
  const OrderAtRisk({required this.code, required this.promised, required this.nowPossible});
  final String code;
  final int promised;
  final int nowPossible;
}

class NewDaysOff {
  const NewDaysOff({required this.kind, required this.startsOn, required this.endsOn, required this.machinesOff, this.note});
  final CapacityKind kind;
  final DateTime startsOn;
  final DateTime endsOn;
  final int machinesOff;
  final String? note;
}

abstract interface class CapacityRepository {
  Future<CapacityCalendar> calendar();
  Future<(CapacityCalendar, List<OrderAtRisk>)> add(NewDaysOff e);
  Future<CapacityCalendar> remove(String id);
}
