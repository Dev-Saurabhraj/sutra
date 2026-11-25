import 'package:flutter_test/flutter_test.dart';
import 'package:sutra/features/auth/domain/me.dart';
import 'package:sutra/features/shell/reach.dart';

void main() {
  test('a CA session opens the CA portal, not onboarding', () {
    final me = Me.fromJson({
      'user': {'id': 'u', 'phone': '+919500000001', 'role': 'CA', 'language': 'en', 'needsConsent': false, 'needsOnboarding': false},
      'producer': null, 'buyer': null, 'cluster': null, 'ca': {'name': 'CA Meera Joshi'}, 'consentVersion': 'v',
    });
    expect(me.isCa, isTrue);
    expect(me.caName, 'CA Meera Joshi');
    expect(me.copyWith().isCa, isTrue);
  });

  test('ONDC, early pay and cluster joining are owner-only in helper mode', () {
    expect(blockedForHelper('/ondc'), isTrue);
    expect(blockedForHelper('/early-pay'), isTrue);
  });
}
