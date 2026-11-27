import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sutra/features/fta/data/fta_data.dart';
import 'package:sutra/features/fta/domain/fta_models.dart';

void main() {
  group('DutySaving', () {
    test('computes the duty and the saving', () {
      final d = DutySaving.calc(invoiceValue: 100000, normalRate: 20, preferentialRate: 5)!;
      expect(d.normalDuty, 20000);
      expect(d.preferentialDuty, 5000);
      expect(d.saved, 15000);
      expect(d.savedPct, 15);
    });

    test('rejects incomplete or nonsensical input', () {
      expect(DutySaving.calc(invoiceValue: null, normalRate: 20, preferentialRate: 5), isNull);
      expect(DutySaving.calc(invoiceValue: 100, normalRate: -1, preferentialRate: 5), isNull);
      expect(DutySaving.calc(invoiceValue: 100, normalRate: 5, preferentialRate: 20), isNull);
    });
  });

  group('FtaEngine catalog', () {
    late FtaEngine engine;

    setUp(() {
      final container = ProviderContainer();
      engine = container.read(ftaEngineProvider);
      addTearDown(container.dispose);
    });

    test('maps destinations to the right agreements', () {
      expect(engine.forCountry('AE').map((a) => a.key), contains('uae-cepa'));
      expect(engine.forCountry('ASEAN').map((a) => a.key), contains('asean-aifta'));
      expect(engine.forCountry('CH').map((a) => a.key), contains('efta-tepa'));
      expect(engine.forCountry('XX'), isEmpty);
    });

    test('every listed destination has at least one agreement', () {
      for (final d in engine.destinations) {
        expect(engine.forCountry(d.code), isNotEmpty, reason: '${d.code} should have an agreement');
      }
    });

    test('every agreement points at a listed destination', () {
      final codes = engine.destinations.map((d) => d.code).toSet();
      for (final a in engine.agreements) {
        for (final c in a.countryCodes) {
          expect(codes, contains(c), reason: '${a.key} references unknown $c');
        }
      }
    });
  });
}
