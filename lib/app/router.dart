import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/consent_screen.dart';
import '../features/bills/presentation/bill_screen.dart';
import '../features/capacity/presentation/capacity_screen.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/catalog/presentation/listing_screen.dart';
import '../features/gst/presentation/gst_screen.dart';
import '../features/gst/presentation/invoice_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/khata/presentation/khata_screen.dart';
import '../features/labour/presentation/labour_screen.dart';
import '../features/market/presentation/bazaar_screen.dart';
import '../features/market/presentation/buyer_account_screen.dart';
import '../features/market/presentation/buyer_order_screen.dart';
import '../features/market/presentation/buyer_orders_screen.dart';
import '../features/market/presentation/buyer_shell.dart';
import '../features/market/presentation/maker_page.dart';
import '../features/market/presentation/product_page.dart';
import '../features/money/money_screens.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/orders/presentation/order_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/cluster/presentation/cluster_screens.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/reach.dart';
import '../features/stock/presentation/prices_screen.dart';
import '../features/shell/splash_screen.dart';
import '../features/voice/presentation/voice_screen.dart';

/// Bridges Riverpod session changes to go_router's refresh.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
    ref.listen(helperModeProvider, (_, _) => notifyListeners());
  }
}

const _gates = {'/splash', '/login', '/consent', '/onboarding'};

/// Buyers live in the bazaar; makers in the bahi. Each is kept out of the other's screens.
const _buyerRoots = ['/bazaar', '/my-orders', '/my-order', '/account'];
bool _isBuyerPath(String at) => _buyerRoots.any((p) => at == p || at.startsWith('$p/'));

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final at = state.matchedLocation;
      if (session.isLoading || session.hasError) return at == '/splash' ? null : '/splash';
      return switch (session.requireValue) {
        SignedOut() => at == '/login' ? null : '/login',
        // consent first (DPDP), then set up the business, then the app
        SignedIn(:final me) when me.user.needsConsent => at == '/consent' ? null : '/consent',
        SignedIn(:final me) when !me.isClusterAdmin && (me.user.needsOnboarding || (me.producer == null && me.buyer == null)) => at == '/onboarding' ? null : '/onboarding',
        SignedIn(:final me) when me.isClusterAdmin => at == '/cluster' ? null : '/cluster',
        SignedIn(:final me) when me.isBuyer => _gates.contains(at) || !_isBuyerPath(at) ? '/bazaar' : null,
        // helper (munim) mode: money screens stay closed until the owner's PIN
        SignedIn() when ref.read(helperModeProvider) && blockedForHelper(at) => '/home',
        SignedIn() => _gates.contains(at) || _isBuyerPath(at) ? '/home' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/consent', builder: (_, _) => const ConsentScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/inventory', builder: (_, _) => const InventoryScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/voice', builder: (_, _) => const VoiceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/khata', builder: (_, _) => const KhataScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/labour', builder: (_, _) => const LabourScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      // the buyer's side (B1-B7)
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => BuyerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/bazaar', builder: (_, _) => const BazaarScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/my-orders', builder: (_, _) => const BuyerOrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/account', builder: (_, _) => const BuyerAccountScreen())]),
        ],
      ),
      GoRoute(path: '/bazaar/p/:id', builder: (_, state) => ProductPageScreen(productId: state.pathParameters['id']!)),
      GoRoute(path: '/bazaar/maker/:slug', builder: (_, state) => MakerPageScreen(slug: state.pathParameters['slug']!)),
      GoRoute(path: '/my-order/:code', builder: (_, state) => BuyerOrderScreen(code: state.pathParameters['code']!)),
      // full-screen tasks opened from anywhere (back returns to where you were)
      GoRoute(path: '/capacity', builder: (_, _) => const CapacityScreen()),
      GoRoute(path: '/prices', builder: (_, _) => const PricesScreen()),
      GoRoute(path: '/schemes', builder: (_, _) => const SchemesScreen()),
      GoRoute(path: '/gst/2b', builder: (_, _) => const ReconcileScreen()),
      // the cooperative / FPO secretary (C1-C5)
      GoRoute(path: '/cluster', builder: (_, _) => const ClusterShell()),
      GoRoute(path: '/bill', builder: (_, _) => const BillScreen()),
      GoRoute(path: '/gst', builder: (_, _) => const GstScreen()),
      GoRoute(path: '/invoice/:id', builder: (_, state) => InvoiceScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
      GoRoute(path: '/order/:code', builder: (_, state) => OrderScreen(code: state.pathParameters['code']!)),
      GoRoute(path: '/catalog', builder: (_, _) => const CatalogScreen()),
      GoRoute(path: '/catalog/:id', builder: (_, state) => ListingScreen(productId: state.pathParameters['id']!)),
      // old links from alerts and earlier builds
      GoRoute(path: '/stock', redirect: (_, _) => '/inventory'),
    ],
  );
});
