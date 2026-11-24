import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/home_models.dart';

class HttpHomeRepository implements HomeRepository {
  HttpHomeRepository(this._api);
  final ApiClient _api;

  @override
  Future<HomeSummary> today() async => HomeSummary.fromJson(await _api.get('/home'));
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) => HttpHomeRepository(ref.watch(apiClientProvider)));
final homeProvider = FutureProvider.autoDispose<HomeSummary>((ref) => ref.watch(homeRepositoryProvider).today());
