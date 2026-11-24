import '../../stock/domain/stock_models.dart';

/// The five stations of the goods journey, with the numbers that matter at each.
class FlowSummary {
  const FlowSummary({
    required this.isTrader,
    required this.suppliers,
    required this.toPay,
    required this.rawItems,
    required this.rawLow,
    required this.rawValue,
    required this.openOrders,
    required this.madeThisWeek,
    required this.readyItems,
    required this.readyUnits,
    required this.readyValue,
    required this.clients,
    required this.toReceive,
    required this.soldThisWeek,
    required this.materials,
    required this.products,
  });

  final bool isTrader;
  final int suppliers;
  final double toPay;
  final int rawItems;
  final int rawLow;
  final double rawValue;
  final int openOrders;
  final double madeThisWeek;
  final int readyItems;
  final int readyUnits;
  final double readyValue;
  final int clients;
  final double toReceive;
  final double soldThisWeek;
  final List<MaterialHealth> materials;
  final List<ProductStock> products;

  factory FlowSummary.fromJson(Map<String, dynamic> j) {
    final raw = j['raw'] as Map<String, dynamic>;
    final making = j['making'] as Map<String, dynamic>;
    final ready = j['ready'] as Map<String, dynamic>;
    final clients = j['clients'] as Map<String, dynamic>;
    final suppliers = j['suppliers'] as Map<String, dynamic>;
    return FlowSummary(
      isTrader: j['kind'] == 'TRADER',
      suppliers: (suppliers['count'] as num).toInt(),
      toPay: (suppliers['toPay'] as num).toDouble(),
      rawItems: (raw['items'] as num).toInt(),
      rawLow: (raw['low'] as num).toInt(),
      rawValue: (raw['value'] as num).toDouble(),
      openOrders: (making['openOrders'] as num).toInt(),
      madeThisWeek: (making['madeThisWeek'] as num).toDouble(),
      readyItems: (ready['items'] as num).toInt(),
      readyUnits: (ready['units'] as num).toInt(),
      readyValue: (ready['value'] as num).toDouble(),
      clients: (clients['count'] as num).toInt(),
      toReceive: (clients['toReceive'] as num).toDouble(),
      soldThisWeek: (clients['soldThisWeek'] as num).toDouble(),
      materials: (j['materials'] as List).map((e) => MaterialHealth.fromJson(e as Map<String, dynamic>)).toList(),
      products: (j['products'] as List).map((e) => ProductStock.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class Partner {
  const Partner({required this.id, required this.name, required this.phone, required this.city, this.business, this.leadTimeDays});

  final String id;
  final String name;
  final String phone;
  final String city;
  final String? business;
  final int? leadTimeDays;

  String get display => business ?? name;

  factory Partner.supplier(Map<String, dynamic> j) => Partner(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String,
        city: j['city'] as String,
        leadTimeDays: (j['leadTimeDays'] as num).toInt(),
      );

  factory Partner.client(Map<String, dynamic> j) => Partner(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String,
        city: j['city'] as String,
        business: j['business'] as String?,
      );
}

class Movement {
  const Movement({required this.kind, required this.qty, required this.note, required this.at, required this.unit});

  final String kind; // PURCHASE | CONSUME | PRODUCE | SALE | ADJUST
  final double qty;
  final String? note;
  final DateTime at;
  final String unit;

  factory Movement.fromJson(Map<String, dynamic> j) => Movement(
        kind: j['kind'] as String,
        qty: (j['qty'] as num).toDouble(),
        note: j['note'] as String?,
        at: DateTime.parse(j['createdAt'] as String),
        unit: (j['item'] as Map<String, dynamic>)['unit'] as String,
      );
}

class SaleResult {
  const SaleResult({required this.invoiceNumber, required this.total});
  final String invoiceNumber;
  final double total;
}

abstract interface class InventoryRepository {
  Future<FlowSummary> flow();
  Future<List<Partner>> suppliers();
  Future<List<Partner>> clients();
  Future<Partner> addSupplier({required String name, required String phone, required String city, required int leadTimeDays});
  Future<Partner> addClient({required String name, String? business, required String phone, required String city});
  Future<void> addMaterial({required String name, required String unit, required double cost, required double stock, String? supplierId});
  Future<void> addProduct({required String name, required double price, required int stock, required Map<String, double> recipe});
  Future<void> stockIn(String materialId, {required double qty, double? rate, String? supplierId});
  Future<void> produce(String productId, {required int qty, String? workerId});
  Future<SaleResult> sell(String productId, {required int qty, double? rate, String? clientId, String? walkInName, String? walkInCity});
  Future<void> adjustMaterial(String materialId, double actual);
  Future<void> adjustProduct(String productId, int actual);
  Future<List<Movement>> movements({String? materialId, String? productId});
}
