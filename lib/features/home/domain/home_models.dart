import '../../alerts/domain/alert_models.dart';
import '../../auth/domain/me.dart';
import '../../stock/domain/stock_models.dart';

class Bilingual {
  const Bilingual(this.hi, this.en);
  final String hi;
  final String en;

  factory Bilingual.fromJson(Map<String, dynamic> j) => Bilingual(j['hi'] as String, j['en'] as String);
}

class HomeKpis {
  const HomeKpis({required this.sales30d, required this.invoices30d, required this.stockValue, required this.toReceive, required this.toPay, required this.openOrders, required this.newRequests});

  final double sales30d;
  final int invoices30d;
  final double stockValue;
  final double toReceive;
  final double toPay;
  final int openOrders;
  final int newRequests;

  factory HomeKpis.fromJson(Map<String, dynamic> j) => HomeKpis(
        sales30d: (j['sales30d'] as num).toDouble(),
        invoices30d: (j['invoices30d'] as num).toInt(),
        stockValue: (j['stockValue'] as num).toDouble(),
        toReceive: (j['toReceive'] as num).toDouble(),
        toPay: (j['toPay'] as num).toDouble(),
        openOrders: (j['openOrders'] as num).toInt(),
        newRequests: (j['newRequests'] as num).toInt(),
      );
}

class HomeSummary {
  const HomeSummary({required this.producer, required this.greeting, required this.spoken, required this.alerts, required this.kpis, required this.materials});

  final ProducerProfile producer;
  final Bilingual greeting;
  final Bilingual spoken;
  final List<AlertItem> alerts;
  final HomeKpis kpis;
  final List<MaterialHealth> materials;

  factory HomeSummary.fromJson(Map<String, dynamic> j) => HomeSummary(
        producer: ProducerProfile.fromJson(j['producer'] as Map<String, dynamic>),
        greeting: Bilingual.fromJson(j['greeting'] as Map<String, dynamic>),
        spoken: Bilingual.fromJson(j['spoken'] as Map<String, dynamic>),
        alerts: (j['alerts'] as List).map((e) => AlertItem.fromJson(e as Map<String, dynamic>)).toList(),
        kpis: HomeKpis.fromJson(j['kpis'] as Map<String, dynamic>),
        materials: (j['materials'] as List).map((e) => MaterialHealth.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

abstract interface class HomeRepository {
  Future<HomeSummary> today();
}
