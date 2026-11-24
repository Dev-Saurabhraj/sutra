import 'dart:typed_data';

class GstPeriod {
  const GstPeriod({required this.key, required this.label});
  final String key;
  final String label;
}

class GstPeriods {
  const GstPeriods({required this.months, required this.quarters});
  final List<GstPeriod> months;
  final List<GstPeriod> quarters;

  factory GstPeriods.fromJson(Map<String, dynamic> j) {
    List<GstPeriod> read(String k) =>
        [for (final p in (j[k] as List).cast<Map<String, dynamic>>()) GstPeriod(key: p['key'] as String, label: p['label'] as String)];
    return GstPeriods(months: read('months'), quarters: read('quarters'));
  }
}

class GstIssue {
  const GstIssue({required this.kind, required this.text, required this.textHi, required this.amount});
  final String kind;
  final String text;
  final String textHi;
  final double amount;
}

enum GstScheme {
  regular,
  composition,
  unregistered;

  static GstScheme parse(String s) => switch (s) {
        'COMPOSITION' => GstScheme.composition,
        'UNREGISTERED' => GstScheme.unregistered,
        _ => GstScheme.regular,
      };
}

/// The GST picture for one period. Which fields are filled depends on the scheme.
class GstSummary {
  const GstSummary({
    required this.scheme,
    required this.periodLabel,
    required this.salesCount,
    required this.salesTaxable,
    required this.b2b,
    required this.b2c,
    required this.purchasesCount,
    required this.fyTurnover,
    required this.issues,
    required this.filingHi,
    required this.filingEn,
    this.outputTax = 0,
    this.itc = 0,
    this.itcAtRisk = 0,
    this.payable = 0,
    this.carryForward = 0,
    this.compositionTax = 0,
    this.compositionLimit = 0,
    this.registrationThreshold = 0,
    this.mustRegister = false,
  });

  final GstScheme scheme;
  final String periodLabel;
  final int salesCount;
  final double salesTaxable;
  final int b2b;
  final int b2c;
  final int purchasesCount;
  final double fyTurnover;
  final List<GstIssue> issues;
  final String filingHi;
  final String filingEn;
  // regular
  final double outputTax;
  final double itc;
  final double itcAtRisk;
  final double payable;
  final double carryForward;
  // composition
  final double compositionTax;
  final double compositionLimit;
  // unregistered
  final double registrationThreshold;
  final bool mustRegister;

  factory GstSummary.fromJson(Map<String, dynamic> j) {
    final sales = j['sales'] as Map<String, dynamic>;
    final filing = j['filing'] as Map<String, dynamic>;
    double n(Map<String, dynamic>? m, String k) => ((m?[k] as num?) ?? 0).toDouble();
    final out = j['outputTax'] as Map<String, dynamic>?;
    final itc = j['itc'] as Map<String, dynamic>?;
    final net = j['net'] as Map<String, dynamic>?;
    final comp = j['composition'] as Map<String, dynamic>?;
    final reg = j['registration'] as Map<String, dynamic>?;
    return GstSummary(
      scheme: GstScheme.parse(j['scheme'] as String),
      periodLabel: (j['period'] as Map<String, dynamic>)['label'] as String,
      salesCount: (sales['count'] as num).toInt(),
      salesTaxable: (sales['taxable'] as num).toDouble(),
      b2b: (sales['b2b'] as num).toInt(),
      b2c: (sales['b2c'] as num).toInt(),
      purchasesCount: ((j['purchases'] as Map<String, dynamic>)['count'] as num).toInt(),
      fyTurnover: (j['fyTurnover'] as num).toDouble(),
      issues: [
        for (final i in (j['issues'] as List).cast<Map<String, dynamic>>())
          GstIssue(kind: i['kind'] as String, text: i['text'] as String, textHi: i['textHi'] as String, amount: (i['amount'] as num).toDouble()),
      ],
      filingHi: filing['hi'] as String,
      filingEn: filing['en'] as String,
      outputTax: n(out, 'total'),
      itc: n(itc, 'total'),
      itcAtRisk: n(itc, 'atRisk'),
      payable: n(net, 'payable'),
      carryForward: n(net, 'carryForward'),
      compositionTax: n(comp, 'tax'),
      compositionLimit: n(comp, 'limit'),
      registrationThreshold: n(reg, 'threshold'),
      mustRegister: (reg?['mustRegister'] as bool?) ?? false,
    );
  }
}

class InvoiceRow {
  const InvoiceRow({
    required this.id,
    required this.number,
    required this.kind,
    required this.buyerName,
    required this.buyerGstin,
    required this.buyerState,
    required this.itemName,
    required this.hsn,
    required this.qty,
    required this.rate,
    required this.taxable,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
    required this.issuedAt,
  });

  final String id;
  final String number;
  final String kind; // TAX | PROFORMA | BILL_OF_SUPPLY
  final String buyerName;
  final String? buyerGstin;
  final String buyerState;
  final String itemName;
  final String hsn;
  final double qty;
  final double rate;
  final double taxable;
  final double gstRate;
  final double cgst;
  final double sgst;
  final double igst;
  final double total;
  final DateTime issuedAt;

  factory InvoiceRow.fromJson(Map<String, dynamic> j) {
    double n(String k) => (j[k] as num).toDouble();
    return InvoiceRow(
      id: j['id'] as String,
      number: j['number'] as String,
      kind: j['kind'] as String,
      buyerName: j['buyerName'] as String,
      buyerGstin: j['buyerGstin'] as String?,
      buyerState: j['buyerState'] as String,
      itemName: j['itemName'] as String,
      hsn: j['hsn'] as String,
      qty: n('qty'),
      rate: n('rate'),
      taxable: n('taxable'),
      gstRate: n('gstRate'),
      cgst: n('cgst'),
      sgst: n('sgst'),
      igst: n('igst'),
      total: n('total'),
      issuedAt: DateTime.parse(j['issuedAt'] as String),
    );
  }
}

/// Which period the screen shows: a month ("2026-11") or a quarter ("2026-Q3").
class PeriodChoice {
  const PeriodChoice.month(this.key) : quarter = false;
  const PeriodChoice.quarter(this.key) : quarter = true;
  final String key;
  final bool quarter;

  Map<String, String> get query => quarter ? {'quarter': key} : {'month': key};

  @override
  bool operator ==(Object other) => other is PeriodChoice && other.key == key && other.quarter == quarter;
  @override
  int get hashCode => Object.hash(key, quarter);
}

abstract interface class GstRepository {
  Future<GstPeriods> periods();
  Future<GstSummary> summary(PeriodChoice? period);
  Future<Uint8List> csv(PeriodChoice? period);
  Future<Uint8List> gstr1(PeriodChoice? period);
  Future<List<InvoiceRow>> invoices({int limit = 30});
  Future<InvoiceRow> invoice(String id);
  Future<Uint8List> invoicePdf(String id);
}
