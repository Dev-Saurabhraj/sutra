import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sutra/app/providers.dart';
import 'package:sutra/core/network/api_exception.dart';
import 'package:sutra/core/network/outbox.dart';
import 'package:sutra/features/auth/domain/me.dart';
import 'package:sutra/features/shell/reach.dart';

void main() {
  group('offline outbox (P27)', () {
    test('keeps entries in order with their keys, and removes the sent one', () async {
      SharedPreferences.setMockInitialValues({});
      final counts = <int>[];
      final box = Outbox(await SharedPreferences.getInstance(), onChanged: counts.add);
      await box.add(OutboxItem(path: '/khata/1/settle', body: null, key: 'k1', at: DateTime(2026, 11, 24)));
      await box.add(OutboxItem(path: '/inventory/products/p/produce', body: {'qty': 6}, key: 'k2', at: DateTime(2026, 11, 24)));
      expect(box.items.map((i) => i.key), ['k1', 'k2']);
      expect((box.items.last.body as Map)['qty'], 6);
      await box.remove('k1');
      expect(box.count, 1);
      expect(counts, [1, 2, 1]);
    });

    test('a kept entry is reported as saved, not as an error', () {
      final e = ApiException.from(const SavedOffline());
      expect(e.code, 'SAVED_OFFLINE');
      expect(e.messageHi, contains('फ़ोन में सेव'));
    });
  });

  group('helper mode (P26)', () {
    test('starts with a PIN and only the right PIN unlocks', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance())]);
      addTearDown(c.dispose);
      expect(c.read(helperModeProvider), isFalse);
      await c.read(helperModeProvider.notifier).start('4821');
      expect(c.read(helperModeProvider), isTrue);
      expect(await c.read(helperModeProvider.notifier).unlock('1111'), isFalse);
      expect(c.read(helperModeProvider), isTrue);
      expect(await c.read(helperModeProvider.notifier).unlock('4821'), isTrue);
      expect(c.read(helperModeProvider), isFalse);
    });

    test('money screens are closed to a helper; goods and voice are open', () {
      expect(blockedForHelper('/khata'), isTrue);
      expect(blockedForHelper('/invoice/abc'), isTrue);
      expect(blockedForHelper('/inventory'), isFalse);
      expect(blockedForHelper('/voice'), isFalse);
    });
  });

  test('a cluster admin session has a cluster and no business', () {
    final me = Me.fromJson({
      'user': {'id': 'u', 'phone': '+919600000001', 'role': 'CLUSTER_ADMIN', 'language': 'hi', 'needsConsent': false, 'needsOnboarding': false},
      'producer': null,
      'buyer': null,
      'cluster': {'id': 'c', 'slug': 'chanderi', 'name': 'Chanderi Handloom Cluster', 'city': 'Chanderi', 'state': 'Madhya Pradesh'},
      'consentVersion': 'v',
    });
    expect(me.isClusterAdmin, isTrue);
    expect(me.isBuyer, isFalse);
  });
}
