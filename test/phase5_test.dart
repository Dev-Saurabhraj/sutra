import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sutra/core/l10n/strings_en.dart';
import 'package:sutra/design/art/shop_scene.dart';
import 'package:sutra/design/widgets/wax_seal.dart';
import 'package:sutra/features/auth/domain/me.dart';
import 'package:sutra/features/capacity/domain/capacity_models.dart';
import 'package:sutra/features/market/domain/market_models.dart';
import 'package:sutra/features/market/presentation/market_widgets.dart';
import 'package:sutra/features/orders/domain/order_models.dart';

Map<String, dynamic> _maker({String slug = 'rohit', List<String> marks = const ['HANDLOOM_MARK', 'GI_CHANDERI']}) => {
      'slug': slug, 'name': 'Rohit Kushwaha', 'businessName': 'Kushwaha Handloom', 'city': 'Chanderi', 'state': 'Madhya Pradesh',
      'story': 'Third-generation weaver.', 'avatarColor': '#B4441F', 'industry': {'key': 'handloom', 'name': 'Handloom', 'nameHi': 'हथकरघा', 'emoji': '🧵'},
      'cluster': {'slug': 'chanderi', 'name': 'Chanderi Handloom Cluster'}, 'machines': 12, 'since': '2026-09-10T12:00:00.000Z', 'ordersDone': 5,
      'onTimeRate': 0.94, 'gstin': '23RJVPK5073P1ZY', 'gstinFormatOk': true, 'gstScheme': 'REGULAR', 'udyamRegistered': true, 'marks': marks,
    };

Map<String, dynamic> _card(String id, String maker) => {
      'id': id, 'name': 'Chanderi Silk-Cotton Saree', 'category': 'Silk-Cotton Saree', 'price': 3070, 'palette': '#B4441F,#E9C46A', 'imageUrl': null,
      'maker': {'slug': maker, 'businessName': maker, 'city': 'Chanderi', 'cluster': 'Chanderi Handloom Cluster', 'onTimeRate': 0.9, 'avatarColor': '#0F766E'},
      'badge': {'ready': 24, 'perWeek': 13, 'slowWeek': true},
    };

void main() {
  setUpAll(() => initializeDateFormatting());

  group('buyer account', () {
    test('a buyer session has a buyer and no producer', () {
      final me = Me.fromJson({
        'user': {'id': 'u', 'phone': '+919700000001', 'role': 'BUYER', 'language': 'en', 'needsConsent': false, 'needsOnboarding': false},
        'producer': null,
        'buyer': {'id': 'b', 'name': 'Anjali Rao', 'business': 'Kaveri Boutique', 'city': 'Bengaluru', 'state': 'Karnataka', 'gstin': null, 'phone': '+919700000001'},
        'consentVersion': 'v',
      });
      expect(me.isBuyer, isTrue);
      expect(me.buyer!.state, 'Karnataka');
      expect(me.copyWith().buyer, isNotNull);
    });
  });

  group('market models', () {
    test('quote with a cluster split and GST for the buyer state', () {
      final q = QuoteResult.fromJson({
        'product': _card('p1', 'rohit'),
        'qty': 150,
        'wantedBy': '2026-12-15T12:00:00.000Z',
        'plan': {
          'qty': 150, 'wantedBy': '2026-12-15T12:00:00.000Z', 'ready': 24, 'perDay': 2.06, 'backlogDays': 0, 'qtyByWanted': 61,
          'fullDate': '2027-01-28T12:00:00.000Z', 'canMeet': false, 'shortfalls': [], 'curve': [{'date': '2026-11-25', 'units': 24}, {'date': '2026-12-15', 'units': 61}],
          'counted': [{'id': 'e1', 'kind': 'WEDDING', 'startsOn': '2026-12-01', 'endsOn': '2026-12-06', 'machinesOff': 3, 'note': 'Wedding'}],
        },
        'sale': {'allowed': true, 'reasonEn': null, 'warningEn': null, 'document': 'TAX', 'taxable': 460500, 'tax': 23025, 'total': 483525, 'interState': true},
        'split': {
          'covered': 150, 'qty': 150, 'canMeet': true,
          'rows': [
            {'assigned': 61, 'maker': _maker(), 'product': _card('p1', 'rohit'), 'value': 187270},
            {'assigned': 89, 'maker': _maker(slug: 'rukhsana', marks: const []), 'product': _card('p2', 'rukhsana'), 'value': 284800},
          ],
        },
      });
      expect(q.plan.counted.single.kind, CapacityKind.wedding);
      expect(q.plan.counted.single.days, 6);
      expect(q.sale.interState, isTrue);
      expect(q.split!.rows.map((r) => r.assigned), [61, 89]);
      expect(q.split!.value, 187270 + 284800);
      expect(q.product.badge!.slowWeek, isTrue);
    });

    test('filter equality keeps the same provider for the same search', () {
      const a = MarketFilter(q: 'saree', industry: 'handloom');
      expect(a, const MarketFilter(q: 'saree', industry: 'handloom'));
      expect(a.copyWith(clearIndustry: true).industry, isNull);
      expect(a.query, {'q': 'saree', 'industry': 'handloom'});
    });

    test('a request split across makers lists a proforma for each', () {
      final r = RequestResult.fromJson({
        'group': 'REQ-101',
        'total': 250000,
        'orders': [
          {'code': 'SUT-1187', 'maker': 'Kushwaha Handloom', 'qty': 61, 'rate': 3070, 'proforma': {'id': 'i1', 'number': 'KH/P26-27/0002', 'total': 196633.5}},
          {'code': 'SUT-1188', 'maker': 'Bano Weaves', 'qty': 33, 'rate': 3200, 'proforma': {'id': 'i2', 'number': 'BW/P26-27/0001', 'total': 110880}},
        ],
      });
      expect(r.group, 'REQ-101');
      expect(r.orders.last.proformaNumber, 'BW/P26-27/0001');
    });

    test('capacity calendar reads days and machine-days lost', () {
      final c = CapacityCalendar.fromJson({
        'machines': 12, 'machineLabel': 'loom', 'machineLabelHi': 'करघा', 'machineDaysLost': 44,
        'days': [{'date': '2026-11-24', 'machines': 12, 'off': 0}, {'date': '2026-11-26', 'machines': 11, 'off': 1}],
        'events': [{'id': 'e', 'kind': 'POWER_CUT', 'startsOn': '2026-11-26', 'endsOn': '2026-11-26', 'machinesOff': 1, 'note': null}],
      });
      expect(c.days.last.off, 1);
      expect(c.events.single.kind, CapacityKind.powerCut);
    });
  });

  group('pictures', () {
    testWidgets('trust ledger seals checked facts and lists marks', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: TrustLedger(maker: MakerTrust.fromJson(_maker()), strings: const EnglishStrings()))),
      ));
      expect(find.text('GSTIN format checked'), findsOneWidget);
      expect(find.text('Handloom Mark'), findsOneWidget);
      expect(find.text('GI: Chanderi Sarees'), findsOneWidget);
      expect(find.byType(WaxSeal), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shop scene and the badge render', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 120, child: ShopArt()),
              DeliverBadgeChip(badge: const DeliverBadge(ready: 24, perWeek: 13, slowWeek: true), strings: const EnglishStrings()),
            ],
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('24 ready · 13/week'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
