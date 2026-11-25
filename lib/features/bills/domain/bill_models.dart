import 'dart:typed_data';

class BillLine {
  const BillLine({required this.description, required this.hsn, required this.qty, required this.unit, required this.rate, required this.materialId});

  final String description;
  final String hsn;
  final double qty;
  final String unit;
  final double rate;

  /// The producer's material this line is (empty when nothing matched).
  final String materialId;

  double get amount => qty * rate;

  factory BillLine.fromJson(Map<String, dynamic> j) => BillLine(
        description: j['description'] as String,
        hsn: (j['hsn'] as String?) ?? '',
        qty: (j['qty'] as num).toDouble(),
        unit: j['unit'] as String,
        rate: (j['rate'] as num).toDouble(),
        materialId: (j['materialId'] as String?) ?? '',
      );
}

class MaterialChoice {
  const MaterialChoice({required this.id, required this.name, required this.nameHi, required this.unit});
  final String id;
  final String name;
  final String nameHi;
  final String unit;

  factory MaterialChoice.fromJson(Map<String, dynamic> j) =>
      MaterialChoice(id: j['id'] as String, name: j['name'] as String, nameHi: j['nameHi'] as String, unit: j['unit'] as String);
}

/// What Sutra read from a bill photo, plus the checks, waiting for the user's "yes".
class BillDraft {
  const BillDraft({
    required this.scanId,
    required this.parser,
    required this.supplierName,
    required this.supplierKnown,
    required this.supplierGstin,
    required this.gstinValid,
    required this.gstinReason,
    required this.billNo,
    required this.billDate,
    required this.lines,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
    required this.mathOk,
    required this.itc,
    required this.materials,
  });

  final String scanId;
  final String parser;
  final String supplierName;
  final bool supplierKnown;
  final String supplierGstin;
  final bool gstinValid;
  final String? gstinReason;
  final String billNo;
  final String billDate;
  final List<BillLine> lines;
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double total;
  final bool mathOk;
  final double itc;
  final List<MaterialChoice> materials;

  bool get readByAi => parser.startsWith('ai:');

  factory BillDraft.fromJson(Map<String, dynamic> j) {
    final bill = j['bill'] as Map<String, dynamic>;
    final checks = j['checks'] as Map<String, dynamic>;
    final gstin = checks['gstin'] as Map<String, dynamic>;
    final supplier = j['supplier'] as Map<String, dynamic>;
    return BillDraft(
      scanId: j['scanId'] as String,
      parser: j['parser'] as String,
      supplierName: supplier['name'] as String,
      supplierKnown: supplier['known'] as bool,
      supplierGstin: bill['supplierGstin'] as String,
      gstinValid: gstin['valid'] as bool,
      gstinReason: gstin['reason'] as String?,
      billNo: bill['billNo'] as String,
      billDate: bill['billDate'] as String,
      lines: (bill['items'] as List).map((e) => BillLine.fromJson(e as Map<String, dynamic>)).toList(),
      taxable: (bill['taxable'] as num).toDouble(),
      cgst: (bill['cgst'] as num).toDouble(),
      sgst: (bill['sgst'] as num).toDouble(),
      igst: (bill['igst'] as num).toDouble(),
      total: (bill['total'] as num).toDouble(),
      mathOk: checks['mathOk'] as bool,
      itc: (checks['itc'] as num).toDouble(),
      materials: (j['materials'] as List).map((e) => MaterialChoice.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class StockUpdate {
  const StockUpdate({required this.name, required this.nameHi, required this.unit, required this.qty, required this.stock});
  final String name;
  final String nameHi;
  final String unit;
  final double qty;
  final double stock;
}

class BillSaved {
  const BillSaved({required this.supplier, required this.updates, required this.itc, required this.itcAtRisk});
  final String supplier;
  final List<StockUpdate> updates;
  final double itc;
  final bool itcAtRisk;

  factory BillSaved.fromJson(Map<String, dynamic> j) => BillSaved(
        supplier: j['supplier'] as String,
        itc: (j['itc'] as num).toDouble(),
        itcAtRisk: j['itcAtRisk'] as bool,
        updates: [
          for (final u in (j['updated'] as List).cast<Map<String, dynamic>>())
            StockUpdate(name: u['name'] as String, nameHi: u['nameHi'] as String, unit: u['unit'] as String, qty: (u['qty'] as num).toDouble(), stock: (u['stock'] as num).toDouble()),
        ],
      );
}

class SampleBill {
  const SampleBill({required this.key, required this.label, required this.labelHi});
  final String key;
  final String label;
  final String labelHi;

  String get asset => 'assets/samples/bill-$key.jpg';
}

class BillPhoto {
  const BillPhoto({required this.bytes, required this.mediaType});
  final Uint8List bytes;
  final String mediaType;
}

abstract interface class BillRepository {
  /// Whether photos can be read (AI on) and the demo sample bills.
  Future<({bool aiEnabled, List<SampleBill> samples})> samples();
  Future<BillDraft> scanPhoto(BillPhoto photo);
  Future<BillDraft> scanSample(String key);

  /// [materialIds]: per line, which material it is (null = skip the line).
  Future<BillSaved> confirm(String scanId, List<String?> materialIds);
}
