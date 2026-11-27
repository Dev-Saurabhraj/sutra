import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sutra/core/format/formatters.dart';
import 'package:sutra/core/l10n/app_strings.dart';
import 'package:sutra/core/network/api_exception.dart';
import 'package:sutra/features/khata/domain/khata_models.dart';
import 'package:sutra/features/stock/domain/stock_models.dart';
import 'package:sutra/features/voice/domain/voice_models.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hi');
    await initializeDateFormatting('en_IN');
  });

  group('Fmt', () {
    test('formats rupees with Indian grouping', () {
      expect(Fmt.inr(124600), '₹1,24,600');
      expect(Fmt.inr(999.6), '₹1,000');
    });
    test('drops a trailing .0 on quantities', () {
      expect(Fmt.qty(2.0), '2');
      expect(Fmt.qty(2.7), '2.7');
      expect(Fmt.qty(12345.25), '12,345.3');
    });
    test('initials skip honorifics', () {
      expect(Fmt.initials('Rohit Kushwaha'), 'RK');
      expect(Fmt.initials('Mohd. Salim'), 'S');
    });
    test('relative time in both languages', () {
      final now = DateTime(2026, 11, 24, 12);
      expect(Fmt.ago(now.subtract(const Duration(hours: 3)), hindi: true, now: now), '3 घंटे पहले');
      expect(Fmt.ago(now.subtract(const Duration(days: 2)), hindi: false, now: now), '2d ago');
    });
  });

  group('AppStrings', () {
    test('both languages answer every question the same way', () {
      for (final lang in AppLang.values) {
        final s = AppStrings.of(lang);
        expect(s.lang, lang);
        expect(s.consentPoints, hasLength(5));
        expect(s.lastsDays(6), contains('6'));
        expect(s.msmeDaysLeft(-1), isNotEmpty);
        expect(s.schemeName('COMPOSITION'), isNotEmpty);
        expect(s.khataExport, isNotEmpty);
      }
      expect(AppStrings.of(AppLang.hi).pick('धागा', 'yarn'), 'धागा');
      expect(AppStrings.of(AppLang.en).pick('धागा', 'yarn'), 'yarn');
    });
  });

  group('models', () {
    test('MaterialHealth parses the API and fills the spool by days left', () {
      final m = MaterialHealth.fromJson({
        'id': 'm1', 'name': 'Zari', 'nameHi': 'ज़री', 'unit': 'kg', 'stock': 1.1, 'costPerUnit': 9200, 'stockValue': 10120,
        'daysLeft': 15, 'leadTimeDays': 10, 'status': 'LOW', 'reorderBy': '2026-11-27T00:00:00.000Z',
        'suggestedQty': 2.7, 'supplier': {'name': 'Mahalaxmi Zari Works'},
      });
      expect(m.status, StockStatus.low);
      expect(m.spoolFill, closeTo(0.5, 0.001));
      expect(m.supplierName, 'Mahalaxmi Zari Works');
    });

    test('unused material shows a full spool', () {
      final m = MaterialHealth.fromJson({
        'id': 'm2', 'name': 'Box', 'nameHi': 'डिब्बा', 'unit': 'pcs', 'stock': 40, 'costPerUnit': 24, 'stockValue': 960, 'daysLeft': null,
        'leadTimeDays': 2, 'status': 'OK', 'reorderBy': null, 'suggestedQty': 0, 'supplier': null,
      });
      expect(m.spoolFill, 1);
    });

    test('VoicePreview keeps blocked actions visible but unsaveable', () {
      final p = VoicePreview.fromJson({
        'entryId': 'e1', 'transcript': '2 saree Jaipur bheji', 'replyHi': 'ठीक है', 'parser': 'rules', 'canSave': false,
        'actions': [
          {'kind': 'SALE', 'label': 'Sold 2', 'labelHi': '2 भेजीं', 'blocked': {'en': 'Not allowed', 'hi': 'नहीं'}},
        ],
      });
      expect(p.canSave, isFalse);
      expect(p.actions.single.blocked, isTrue);
    });

    test('KhataEntry reads direction and the MSME clock', () {
      final e = KhataEntry.fromJson({
        'id': 'k1', 'party': 'Kaveri Boutique', 'direction': 'RECEIVE', 'amount': 21840, 'note': 'Oct order',
        'dueDate': '2026-11-21T00:00:00.000Z', 'settled': false, 'overdueDays': 3, 'msmeDaysLeft': 7,
      });
      expect(e.incoming, isTrue);
      expect(e.msmeDaysLeft, 7);
    });

    test('khata export filename follows the tab and the date', () {
      expect(khataExportFilename(settled: false, now: DateTime(2026, 11, 24)), 'khata-open-2026-11-24.csv');
      expect(khataExportFilename(settled: true, now: DateTime(2026, 11, 24)), 'khata-settled-2026-11-24.csv');
    });
  });

  test('ApiException keeps the Hindi message from error details', () {
    const e = ApiException(code: 'NOT_UNDERSTOOD', message: "Didn't catch that", messageHi: 'समझ नहीं आया');
    expect(ApiException.from(e).messageHi, 'समझ नहीं आया');
  });
}
