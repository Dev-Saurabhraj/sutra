import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design/tokens.dart';
import '../../design/widgets/woven_nav_bar.dart';

/// Branch order in the router: 0 home · 1 stock · 2 voice (charkha) · 3 khata · 4 profile.
const voiceBranch = 2;
const _tabBranches = [0, 1, 3, 4];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final tabIndex = _tabBranches.indexOf(shell.currentIndex);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth), child: shell),
      ),
      bottomNavigationBar: WovenNavBar(
        items: [
          WovenNavItem(icon: Icons.wb_sunny_outlined, label: s.navHome),
          WovenNavItem(icon: Icons.inventory_2_outlined, label: s.navStock),
          WovenNavItem(icon: Icons.menu_book_outlined, label: s.navKhata),
          WovenNavItem(icon: Icons.storefront_outlined, label: s.navProfile),
        ],
        currentIndex: tabIndex < 0 ? null : tabIndex,
        onSelect: (i) => shell.goBranch(_tabBranches[i], initialLocation: _tabBranches[i] == shell.currentIndex),
        onCharkha: () => shell.goBranch(voiceBranch),
        charkhaLabel: s.navVoice,
        charkhaActive: shell.currentIndex == voiceBranch,
      ),
    );
  }
}
