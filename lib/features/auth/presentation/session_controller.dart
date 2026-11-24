import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository_http.dart';
import '../domain/auth_repository.dart';
import '../domain/me.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider)),
);

sealed class SessionState {
  const SessionState();
}

class SignedOut extends SessionState {
  const SignedOut();
}

class SignedIn extends SessionState {
  const SignedIn(this.me);
  final Me me;
}

/// Who is using the app. The router listens to this to decide which screen to show.
class SessionController extends AsyncNotifier<SessionState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<SessionState> build() async {
    try {
      final me = await _repo.loadMe();
      return me == null ? const SignedOut() : SignedIn(me);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return const SignedOut();
      rethrow;
    }
  }

  Future<void> signIn(String phone, String code) async {
    await _repo.verifyOtp(phone, code);
    final me = await _repo.loadMe();
    state = AsyncData(me == null ? const SignedOut() : SignedIn(me));
  }

  Future<void> acceptConsent() async {
    final current = state.valueOrNull;
    if (current is! SignedIn) return;
    await _repo.acceptConsent(current.me.consentVersion);
    state = AsyncData(SignedIn(current.me.copyWith(user: current.me.user.withConsent())));
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(SignedOut());
  }

  /// Re-read the profile, e.g. after onboarding stored a new session.
  Future<void> reload() async {
    final me = await _repo.loadMe();
    state = AsyncData(me == null ? const SignedOut() : SignedIn(me));
  }

  /// Called by the API client when the refresh token is no longer valid.
  void expired() => state = const AsyncData(SignedOut());

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, SessionState>(SessionController.new);

/// The signed-in producer profile (screens below the login gate can rely on it).
final meProvider = Provider<Me?>((ref) {
  final s = ref.watch(sessionControllerProvider).valueOrNull;
  return s is SignedIn ? s.me : null;
});

