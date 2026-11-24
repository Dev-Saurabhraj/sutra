import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sutra/core/l10n/strings_en.dart';
import 'package:sutra/design/art/production_curve.dart';
import 'package:sutra/design/art/stage_thread.dart';
import 'package:sutra/features/catalog/domain/catalog_models.dart';
import 'package:sutra/features/orders/domain/order_models.dart';
import 'package:sutra/features/orders/presentation/order_screen.dart';

Map<String, dynamic> _order({String status = 'QUOTED'}) => {
      'id': 'o1', 'code': 'SUT-1186', 'status': status, 'channel': 'MARKETPLACE', 'qty': 200, 'rate': 2824,
      'wantedBy': '2026-12-15T10:00:00.000Z', 'promisedQtyByWanted': null, 'fullDate': null, 'createdAt': '2026-11-24T05:00:00.000Z',
      'dispatchedAt': null, 'deliveredAt': null, 'transporter': null, 'lrNumber': null, 'hasDispatchPhoto': false,
      'product': {'id': 'p1', 'name': 'Chanderi Silk-Cotton Saree', 'nameHi': 'चंदेरी सिल्क-कॉटन साड़ी', 'palette': '#B4441F,#E9C46A', 'imageUrl': null, 'price': 3070, 'stock': 24},
      'buyer': {'id': 'b1', 'name': 'Anjali Rao', 'business': 'Kaveri Boutique', 'city': 'Bengaluru', 'state': 'Karnataka', 'gstin': null, 'phone': null},
    };

Map<String, dynamic> _detail() => {
      'order': _order(),
      'actions': ['accept', 'decline'],
      'canDeliver': {
        'qty': 200, 'wantedBy': '2026-12-15T10:00:00.000Z', 'ready': 24, 'perDay': 2.06, 'backlogDays': 0, 'qtyByWanted': 65,
        'fullDate': '2027-02-18T10:00:00.000Z', 'canMeet': false,
        'shortfalls': [
          {'materialId': 'm1', 'name': 'Mulberry silk yarn', 'nameHi': 'रेशम धागा', 'unit': 'kg', 'needQty': 39, 'supplierName': 'Shree Krishna Silk Traders', 'leadTimeDays': 7, 'orderBy': '2026-12-02T00:00:00.000Z', 'late': false},
        ],
        'curve': [
          {'date': '2026-11-24', 'units': 24},
          {'date': '2026-12-08', 'units': 53},
          {'date': '2026-12-22', 'units': 82},
          {'date': '2027-02-18', 'units': 200},
        ],
      },
      'price': {'rate': 2824, 'cost': {'materials': 1998, 'labour': 700, 'total': 2698}, 'margin': {'perUnit': 126, 'pct': 4.5, 'belowCost': false, 'thin': true}, 'labourKnown': true},
      'messages': [
        {'id': 'm1', 'sender': 'BUYER', 'text': 'Can you supply 200?', 'textHi': 'क्या आप 200 दे सकते हैं?', 'textEn': 'Can you supply 200?', 'createdAt': '2026-11-24T05:00:00.000Z', 'translated': true},
      ],
      'invoices': [],
    };

void main() {
  group('order detail', () {
    test('reads the plan, price check, letters and allowed actions', () {
      final d = OrderDetail.fromJson(_detail());
      expect(d.order.stage, OrderStage.quoted);
      expect(d.order.value, 200 * 2824);
      expect(d.order.party, 'Kaveri Boutique, Bengaluru');
      expect(d.actions, {OrderAction.accept, OrderAction.decline});
      expect(d.plan!.canMeet, isFalse);
      expect(d.plan!.onTimeShare, closeTo(0.325, 0.001));
      expect(d.plan!.shortfalls.single.supplierName, 'Shree Krishna Silk Traders');
      expect(d.plan!.curve.last.units, 200);
      expect(d.price!.thin, isTrue);
      expect(d.messages.single.forProducer(true), 'क्या आप 200 दे सकते हैं?');
      expect(d.messages.single.forProducer(false), 'Can you supply 200?');
    });

    test('stages sit on the thread in order', () {
      expect(OrderStage.parse('IN_PRODUCTION').step, 1);
      expect(OrderStage.parse('DISPATCHED').step, 2);
      expect(OrderStage.parse('DELIVERED').step, 3);
      expect(OrderStage.parse('DECLINED'), OrderStage.declined);
    });

    test('inbox counts per tab', () {
      final b = OrderInbox.fromJson({'tab': 'new', 'counts': {'new': 2, 'active': 1, 'done': 14}, 'orders': [_order()]});
      expect(b.counts[OrderTab.fresh], 2);
      expect(b.counts[OrderTab.done], 14);
      expect(b.orders.single.code, 'SUT-1186');
    });
  });

  group('price floor', () {
    final base = PriceCheck.fromJson({'rate': 3000, 'cost': {'materials': 2000, 'labour': 700, 'total': 2700}, 'margin': {'perUnit': 300, 'pct': 10, 'belowCost': false, 'thin': false}});

    test('recomputes live at a new price, like the server', () {
      expect(base.at(2600).belowCost, isTrue);
      expect(base.at(2600).perUnit, -100);
      expect(base.at(2900).thin, isTrue);
      expect(base.at(3600).thin, isFalse);
      expect(base.at(3600).pct, 25);
    });

    test('catalog item carries its cost at the list price', () {
      final i = CatalogItem.fromJson({
        'id': 'p1', 'slug': 's', 'name': 'Saree', 'nameHi': 'साड़ी', 'category': 'Saree', 'stock': 3, 'price': 3070, 'hsn': '5007', 'gstRate': 5,
        'unitsPerMachinePerWeek': 1.5, 'palette': '#a33', 'imageUrl': '/media/catalog/x.jpg', 'story': 'Woven by hand.', 'mrp': 6000, 'published': true,
        'cost': {'materials': 1998, 'labour': 700, 'total': 2698}, 'margin': {'perUnit': 372, 'pct': 12.1, 'belowCost': false, 'thin': false}, 'labourKnown': true, 'ready': true,
      });
      expect(i.price0.cost, 2698);
      expect(i.price0.rate, 3070);
      expect(i.ready, isTrue);
    });
  });

  group('pictures', () {
    testWidgets('production curve and stage thread draw without overflow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ProductionCurve(
                samples: const [(day: 0, units: 24), (day: 14, units: 53), (day: 28, units: 82), (day: 86, units: 200)],
                target: 200,
                wantedDay: 21,
                promised: 65,
                wantedLabel: '15 Dec',
                targetLabel: '200 pcs',
              ),
              const StageThread(labels: ['Asked', 'Making', 'Sent', 'Reached'], current: 1),
              const StageThread(labels: ['Asked', 'Making', 'Sent', 'Reached'], current: 0, stopped: true),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Making'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('price floor card shows a loss in red ink', (tester) async {
      final loss = PriceCheck.fromJson({'rate': 800, 'cost': {'materials': 600, 'labour': 300, 'total': 900}, 'margin': {'perUnit': -100, 'pct': -12.5, 'belowCost': true, 'thin': false}});
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PriceFloorCard(price: loss, strings: const EnglishStrings())))));
      expect(find.textContaining('LOSS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
