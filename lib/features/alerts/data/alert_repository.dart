import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/alert_models.dart';

class HttpAlertRepository implements AlertRepository {
  HttpAlertRepository(this._api);
  final ApiClient _api;

  @override
  Future<void> markRead(String id) => _api.post('/alerts/$id/read');
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) => HttpAlertRepository(ref.watch(apiClientProvider)));
