import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sutra/design/art/scan_thread.dart';
import 'package:sutra/design/art/thread_meter.dart';
import 'package:sutra/design/tokens.dart';
import 'package:sutra/features/bills/domain/bill_models.dart';
import 'package:sutra/features/gst/domain/gst_models.dart';

void main() {
  group('bill draft', () {
    final json = {
      'scanId': 's1',
      'parser': 'sample',
      'bill': {
        'supplierName': 'Shree Ganesh Yarn Agency', 'supplierGstin': '24AAPFG5512M1Z0', 'billNo': 'SGY/1193', 'billDate': '2026-11-22',
        'items': [{'description': 'Mulberry Raw Silk Yarn', 'materialId': 'm-silk', 'hsn': '5004', 'qty': 3, 'unit': 'kg', 'rate': 5650}],
        'taxable': 16950, 'cgst': 0, 'sgst': 0, 'igst': 847.5, 'total': 17797.5,
      },
      'checks': {'gstin': {'valid': false, 'reason': 'Check digit does not match'}, 'mathOk': true, 'itc': 847.5, 'itcAtRisk': true},
      'supplier': {'known': false, 'id': null, 'name': 'Shree Ganesh Yarn Agency'},
      'materials': [{'id': 'm-silk', 'name': 'Mulberry silk yarn', 'nameHi': 'रेशम धागा', 'unit': 'kg', 'stock': 7.5}],
    };

    test('reads lines, checks and the GSTIN problem', () {
      final d = BillDraft.fromJson(json);
      expect(d.readByAi, isFalse);
      expect(d.gstinValid, isFalse);
      expect(d.lines.single.amount, 16950);
      expect(d.lines.single.materialId, 'm-silk');
      expect(d.itc, 847.5);
      expect(d.materials.single.nameHi, 'रेशम धागा');
    });

    test('saved bill lists stock changes', () {
      final saved = BillSaved.fromJson({
        'supplier': 'Mahalaxmi Zari Works', 'itc': 1830, 'itcAtRisk': false,
        'updated': [{'name': 'Zari', 'nameHi': 'ज़री', 'unit': 'kg', 'qty': 4, 'stock': 5.1}],
      });
      expect(saved.updates.single.stock, 5.1);
    });
  });

  group('GST summary by scheme', () {
    Map<String, dynamic> base(String scheme) => {
          'scheme': scheme,
          'period': {'kind': 'MONTH', 'key': '2026-11', 'label': 'Nov 2026'},
          'sales': {'count': 2, 'taxable': 26180, 'b2b': 1, 'b2c': 1, 'interState': 1},
          'purchases': {'count': 5, 'taxable': 100000},
          'fyTurnover': 259755,
          'issues': [
            {'kind': 'BAD_SUPPLIER_GSTIN', 'text': 'bad', 'textHi': 'गलत', 'amount': 847.5},
          ],
          'filing': {'en': 'GSTR-1 by the 11th', 'hi': 'GSTR-1 11 तक'},
        };

    test('regular: payable, credit and at-risk', () {
      final g = GstSummary.fromJson({
        ...base('REGULAR'),
        'outputTax': {'total': 1309},
        'itc': {'total': 6953.86, 'atRisk': 847.5},
        'net': {'payable': 0, 'carryForward': 5644.86},
      });
      expect(g.scheme, GstScheme.regular);
      expect(g.carryForward, 5644.86);
      expect(g.itcAtRisk, 847.5);
      expect(g.issues.single.textHi, 'गलत');
    });

    test('composition and unregistered read their own blocks', () {
      final c = GstSummary.fromJson({...base('COMPOSITION'), 'composition': {'tax': 749.52, 'limit': 15000000}});
      expect(c.compositionTax, 749.52);
      final u = GstSummary.fromJson({...base('UNREGISTERED'), 'registration': {'threshold': 4000000, 'mustRegister': true}});
      expect(u.mustRegister, isTrue);
      expect(u.payable, 0);
    });

    test('period choice builds the right query', () {
      expect(const PeriodChoice.month('2026-11').query, {'month': '2026-11'});
      expect(const PeriodChoice.quarter('2026-Q3').query, {'quarter': '2026-Q3'});
      expect(const PeriodChoice.quarter('2026-Q3'), const PeriodChoice.quarter('2026-Q3'));
    });
  });

  testWidgets('scan thread and woven bar render', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(height: 200, width: 300, child: ScanThread(child: ColoredBox(color: Colors.white))),
            SizedBox(width: 300, child: WovenBar(value: 0.7, color: SutraColors.neel, marker: 0.8)),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });
}
