import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/consent_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/khata/presentation/khata_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/splash_screen.dart';
import '../features/stock/presentation/stock_screen.dart';
import '../features/voice/presentation/voice_screen.dart';

/// Bridges Riverpod session changes to go_router's refresh.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }
}

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
        SignedIn(:final me) when me.user.needsConsent => at == '/consent' ? null : '/consent',
        SignedIn() => (at == '/login' || at == '/consent' || at == '/splash') ? '/home' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/consent', builder: (_, _) => const ConsentScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/stock', builder: (_, _) => const StockScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/voice', builder: (_, _) => const VoiceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/khata', builder: (_, _) => const KhataScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});
