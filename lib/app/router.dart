import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/consent_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/khata/presentation/khata_screen.dart';
import '../features/labour/presentation/labour_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/splash_screen.dart';
import '../features/voice/presentation/voice_screen.dart';

/// Bridges Riverpod session changes to go_router's refresh.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }
}

const _gates = {'/splash', '/login', '/consent', '/onboarding'};

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
        SignedIn(:final me) when me.user.needsOnboarding || me.producer == null => at == '/onboarding' ? null : '/onboarding',
        SignedIn() => _gates.contains(at) ? '/home' : null,
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
      // old links from alerts and earlier builds
      GoRoute(path: '/stock', redirect: (_, _) => '/inventory'),
    ],
  );
});
