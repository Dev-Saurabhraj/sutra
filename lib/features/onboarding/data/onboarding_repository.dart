import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';
import '../domain/onboarding_models.dart';

class HttpOnboardingRepository implements OnboardingRepository {
  HttpOnboardingRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<List<IndustryTemplate>> industries() async {
    final j = await _api.get('/industries');
    return (j['industries'] as List).map((e) => IndustryTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> submit(OnboardingDraft draft, {required String language}) async {
    final j = await _api.post('/onboarding', body: draft.toJson(language: language), idempotent: true);
    await _tokens.write(StoredTokens(accessToken: j['accessToken'] as String, refreshToken: j['refreshToken'] as String));
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => HttpOnboardingRepository(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider)),
);

final industriesProvider = FutureProvider<List<IndustryTemplate>>((ref) => ref.watch(onboardingRepositoryProvider).industries());
