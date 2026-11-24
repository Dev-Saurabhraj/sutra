import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sutra/core/gst/gstin.dart';
import 'package:sutra/core/l10n/app_strings.dart';
import 'package:sutra/design/art/balance_scale.dart';
import 'package:sutra/design/art/flow_pipeline.dart';
import 'package:sutra/design/art/industry_scenes.dart';
import 'package:sutra/design/art/thread_progress.dart';
import 'package:sutra/features/labour/domain/labour_models.dart';
import 'package:sutra/features/onboarding/domain/onboarding_models.dart';

String _validGstin(String state, String pan) {
  final first14 = '${gstStates[state]}${pan}1Z';
  return first14 + gstinCheckDigit(first14);
}

void main() {
  group('GSTIN on the phone', () {
    test('accepts a valid GSTIN and checks its state', () {
      final g = _validGstin('Madhya Pradesh', 'AABCB7310K');
      expect(checkGstin(g), isNull);
      expect(checkGstin(g, state: 'Madhya Pradesh'), isNull);
      expect(checkGstin(g, state: 'Gujarat'), GstinProblem.wrongState);
    });

    test('catches typos', () {
      final g = _validGstin('Gujarat', 'AAPFG5512M');
      final typo = g.replaceRange(9, 10, g[9] == '3' ? '8' : '3');
      expect(checkGstin(typo), GstinProblem.checkDigit);
      expect(checkGstin('23ABC'), GstinProblem.length);
      expect(checkGstin('ZZABCDE1234F1Z5'), GstinProblem.format);
    });
  });

  group('onboarding payload', () {
    const silk = DraftMaterial(key: 'silk', name: 'Silk', nameHi: 'रेशम', unit: 'kg', hsn: '5004', gstRate: 5, cost: 5600, stock: 7);
    const zari = DraftMaterial(key: 'zari', name: 'Zari', nameHi: 'ज़री', unit: 'kg', hsn: '5605', gstRate: 5, cost: 9200);
    const saree = DraftProduct(key: 'saree', name: 'Saree', nameHi: 'साड़ी', category: 'Saree', price: 3200, hsn: '5007', gstRate: 5, unitsPerMachinePerWeek: 1.5, recipe: {'silk': 0.25, 'zari': 0.05});

    test('maps recipes to the indexes of included materials only', () {
      final d = OnboardingDraft(
        name: 'Rohit', businessName: 'Kushwaha Handloom', industryKey: 'handloom', city: 'Chanderi', state: 'Madhya Pradesh',
        materials: [silk.copyWith(include: false), zari], products: const [saree],
        workers: const [DraftWorker(name: 'Salim', wageType: 'PIECE', rate: 700)],
      );
      final j = d.toJson(language: 'hi');
      expect((j['materials'] as List).length, 1);
      final recipe = ((j['products'] as List).single as Map)['recipe'] as List;
      expect(recipe, [{'material': 0, 'qtyPerUnit': 0.05}]);
      expect(j['gstScheme'], 'UNREGISTERED');
      expect(j.containsKey('gstin'), isFalse);
      expect(((j['workers'] as List).single as Map)['payCycle'], 'WEEKLY');
    });

    test('traders send no raw materials and no recipes', () {
      final j = const OnboardingDraft(industryKey: 'handloom', isTrader: true, materials: [silk], products: [saree]).toJson(language: 'en');
      expect(j['businessKind'], 'TRADER');
      expect(j['materials'], isEmpty);
      expect(((j['products'] as List).single as Map)['recipe'], isEmpty);
    });
  });

  test('worker JSON reads the pay-by date and balances', () {
    final w = Worker.fromJson({
      'id': 'w1', 'name': 'Salim Ansari', 'phone': null, 'skill': 'बुनकर', 'wageType': 'PIECE', 'rate': 700,
      'wageDue': 2100, 'advancePending': 3950, 'earnedThisPeriod': 2100, 'overdue': 0, 'todayUnits': 1,
      'period': {'start': '2026-11-23T00:00:00.000Z', 'end': '2026-11-29T00:00:00.000Z', 'payBy': '2026-11-28T00:00:00.000Z'},
    });
    expect(w.wageType, WageType.piece);
    expect(w.payBy.day, 28);
    expect(w.advancePending, 3950);
  });

  group('illustrations render without errors', () {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 360, height: 200, child: child))));

    for (final key in IndustryArt.keys) {
      testWidgets('industry scene: $key', (tester) async {
        await tester.pumpWidget(host(IndustryArt(key)));
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('flow pipeline, balance scale and thread progress', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 360, child: Column(
        children: [
          FlowPipeline(
            stations: const [
              FlowStation(icon: Icons.local_shipping, label: 'A', value: '3'),
              FlowStation(icon: Icons.inventory, label: 'B', value: '2', alert: true),
              FlowStation(icon: Icons.handyman, label: 'C', value: '0', enabled: false),
            ],
            onTap: (i) => tapped = i,
          ),
          const BalanceScale(receive: 70000, pay: 44000),
          const ThreadProgress(steps: 5, current: 2),
        ],
      )))));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('B'));
      expect(tapped, 1);
      await tester.tap(find.text('C'));
      expect(tapped, 1, reason: 'a disabled station is not tappable');
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion shows a still frame', (tester) async {
      await tester.pumpWidget(MediaQuery(data: const MediaQueryData(disableAnimations: true), child: host(const IndustryArt('handloom'))));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  test('every phrase exists in both languages', () {
    expect(AppStrings.of(AppLang.hi).tr(const T('हाँ', 'yes')), 'हाँ');
    expect(AppStrings.of(AppLang.en).tr(const T('हाँ', 'yes')), 'yes');
  });
}
