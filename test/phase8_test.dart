import 'package:flutter_test/flutter_test.dart';
import 'package:sutra/features/orders/domain/order_models.dart';
import 'package:sutra/features/shell/reach.dart';

void main() {
  test('an order carries its advance (B8)', () {
    final o = Order.fromJson({
      'id': 'o', 'code': 'SUT-1187', 'status': 'IN_PRODUCTION', 'channel': 'MARKETPLACE', 'qty': 61, 'rate': 3070, 'createdAt': '2026-11-24T05:00:00.000Z',
      'product': {'id': 'p', 'name': 'Saree', 'nameHi': 'साड़ी', 'palette': '#a33', 'imageUrl': null, 'price': 3070, 'stock': 24},
      'buyer': null, 'vehicleNo': 'MP07AB1234',
      'advance': {'amount': 58990.05, 'status': 'CLAIMED', 'ref': '432112345678', 'upiUrl': 'upi://pay?pa=x@y&am=58990.05'},
    });
    expect(o.advance!.status, AdvanceStatus.claimed);
    expect(o.advance!.ref, '432112345678');
    expect(o.vehicleNo, 'MP07AB1234');
  });

  test('no advance asked → null', () {
    expect(AdvanceInfo.fromJson(null), isNull);
    expect(AdvanceStatus.parse('PAID'), AdvanceStatus.paid);
  });

  test('a helper may not record money by voice', () {
    expect(helperMoneyKinds.contains('WAGE_PAID'), isTrue);
    expect(helperMoneyKinds.contains('PRODUCE'), isFalse);
    expect(blockedForHelper('/schemes'), isTrue);
  });
}
