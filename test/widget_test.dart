import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sutra/design/tokens.dart';
import 'package:sutra/design/widgets/charkha_mic.dart';
import 'package:sutra/design/widgets/ledger_card.dart';
import 'package:sutra/design/widgets/parchi.dart';
import 'package:sutra/design/widgets/spool_gauge.dart';
import 'package:sutra/design/widgets/stamp.dart';
import 'package:sutra/design/widgets/thread_stripe.dart';
import 'package:sutra/design/widgets/woven_nav_bar.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('Stamp shows its label in upper case and lands with a press', (tester) async {
    await tester.pumpWidget(_host(const Stamp('paid', tone: Tone.ok, thunk: true)));
    expect(find.text('PAID'), findsOneWidget);
    await tester.pumpAndSettle();
    final scale = tester.widget<ScaleTransition>(find.descendant(of: find.byType(Stamp), matching: find.byType(ScaleTransition)));
    expect(scale.scale.value, closeTo(1.0, 0.001));
  });

  testWidgets('SpoolGauge, ThreadStripe, LedgerCard and Parchi render', (tester) async {
    await tester.pumpWidget(_host(const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpoolGauge(fill: 0.1, tone: Tone.critical),
        SizedBox(width: 200, child: ThreadStripe()),
        SizedBox(width: 300, child: LedgerCard(child: LedgerLine(label: 'Sales', value: Text('₹1,24,600')))),
        SizedBox(width: 300, child: Parchi(child: Text('यह लिखूँ?'))),
      ],
    )));
    await tester.pumpAndSettle();
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('यह लिखूँ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CharkhaMic calls back on tap and ignores taps when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(CharkhaMic(listening: false, onTap: () => taps++)));
    await tester.tap(find.byType(CharkhaMic));
    expect(taps, 1);

    await tester.pumpWidget(_host(CharkhaMic(listening: false, enabled: false, onTap: () => taps++)));
    await tester.tap(find.byType(CharkhaMic));
    expect(taps, 1);
  });

  testWidgets('CharkhaMic spins while listening', (tester) async {
    await tester.pumpWidget(_host(CharkhaMic(listening: true, onTap: () {})));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    await tester.pumpWidget(_host(CharkhaMic(listening: false, onTap: () {})));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('WovenNavBar maps taps to tab indexes around the charkha', (tester) async {
    int? selected;
    var charkha = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: WovenNavBar(
          items: const [
            WovenNavItem(icon: Icons.home, label: 'Home'),
            WovenNavItem(icon: Icons.inventory, label: 'Stock'),
            WovenNavItem(icon: Icons.book, label: 'Khata'),
            WovenNavItem(icon: Icons.person, label: 'Me'),
          ],
          currentIndex: 0,
          onSelect: (i) => selected = i,
          onCharkha: () => charkha++,
          charkhaLabel: 'Speak',
        ),
      ),
    ));
    await tester.tap(find.text('Khata'));
    expect(selected, 2);
    await tester.tap(find.byType(CharkhaMic));
    expect(charkha, 1);
  });
}
