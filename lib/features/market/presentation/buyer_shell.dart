import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/thread_stripe.dart';
import 'market_text.dart';

/// The buyer's three places: the bazaar, their orders, their account. A woven strip on top,
/// and a shuttle under the tab you're on (the maker's bar has the charkha; buyers don't need it).
class BuyerShell extends ConsumerWidget {
  const BuyerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final items = [
      (Icons.storefront_outlined, s.tr(MarketText.navBazaar)),
      (Icons.receipt_long_outlined, s.tr(MarketText.navOrders)),
      (Icons.account_circle_outlined, s.tr(MarketText.navAccount)),
    ];
    return Scaffold(
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth), child: shell)),
      bottomNavigationBar: Material(
        color: SutraColors.card,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThreadStripe(height: 3),
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (final (i, (icon, label)) in items.indexed)
                      Expanded(
                        child: Semantics(
                          selected: shell.currentIndex == i,
                          button: true,
                          label: label,
                          child: InkWell(
                            onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                            child: _Tab(icon: icon, label: label, active: shell.currentIndex == i),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? SutraColors.sindoor : SutraColors.inkSoft;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: active ? FontWeight.w800 : FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: SutraMotion.normal,
          curve: SutraMotion.curve,
          width: active ? 26 : 0,
          height: 5,
          decoration: const BoxDecoration(color: SutraColors.haldiDeep, borderRadius: BorderRadius.all(Radius.circular(6))),
        ),
      ],
    );
  }
}
