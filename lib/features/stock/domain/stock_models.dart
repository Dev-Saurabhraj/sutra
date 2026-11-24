import '../../../design/tokens.dart';

enum StockStatus {
  critical,
  low,
  ok;

  static StockStatus parse(String s) => switch (s) {
        'CRITICAL' => StockStatus.critical,
        'LOW' => StockStatus.low,
        _ => StockStatus.ok,
      };

  Tone get tone => switch (this) {
        StockStatus.critical => Tone.critical,
        StockStatus.low => Tone.low,
        StockStatus.ok => Tone.ok,
      };
}

class MaterialHealth {
  const MaterialHealth({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.unit,
    required this.stock,
    required this.costPerUnit,
    required this.stockValue,
    required this.daysLeft,
    required this.leadTimeDays,
    required this.status,
    required this.reorderBy,
    required this.suggestedQty,
    required this.supplierName,
  });

  final String id;
  final String name;
  final String nameHi;
  final String unit;
  final double stock;
  final double costPerUnit;
  final double stockValue;
  final double? daysLeft;
  final int leadTimeDays;
  final StockStatus status;
  final DateTime? reorderBy;
  final double suggestedQty;
  final String? supplierName;

  /// How full the spool looks: days left against a comfortable buffer (lead time + 20 days).
  double get spoolFill => daysLeft == null ? 1 : (daysLeft! / (leadTimeDays + 20)).clamp(0.0, 1.0);

  factory MaterialHealth.fromJson(Map<String, dynamic> j) => MaterialHealth(
        id: j['id'] as String,
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        unit: j['unit'] as String,
        stock: (j['stock'] as num).toDouble(),
        costPerUnit: (j['costPerUnit'] as num).toDouble(),
        stockValue: (j['stockValue'] as num).toDouble(),
        daysLeft: (j['daysLeft'] as num?)?.toDouble(),
        leadTimeDays: (j['leadTimeDays'] as num).toInt(),
        status: StockStatus.parse(j['status'] as String),
        reorderBy: j['reorderBy'] == null ? null : DateTime.parse(j['reorderBy'] as String),
        suggestedQty: (j['suggestedQty'] as num).toDouble(),
        supplierName: (j['supplier'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

class ProductStock {
  const ProductStock({required this.id, required this.name, required this.nameHi, required this.category, required this.stock, required this.price, required this.palette});

  final String id;
  final String name;
  final String nameHi;
  final String category;
  final int stock;
  final double price;
  final String palette;

  factory ProductStock.fromJson(Map<String, dynamic> j) => ProductStock(
        id: j['id'] as String,
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        category: j['category'] as String,
        stock: (j['stock'] as num).toInt(),
        price: (j['price'] as num).toDouble(),
        palette: j['palette'] as String,
      );
}

class ReorderResult {
  const ReorderResult({required this.message, required this.whatsappUrl, required this.supplier, required this.eta});

  final String message;
  final String whatsappUrl;
  final String supplier;
  final String eta;

  factory ReorderResult.fromJson(Map<String, dynamic> j) => ReorderResult(
        message: j['message'] as String,
        whatsappUrl: j['whatsappUrl'] as String,
        supplier: j['supplier'] as String,
        eta: j['eta'] as String,
      );
}

abstract interface class StockRepository {
  Future<List<MaterialHealth>> materials();
  Future<List<ProductStock>> products();
  Future<ReorderResult> reorder(String materialId, double qty);
}
