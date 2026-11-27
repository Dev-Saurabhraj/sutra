import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/khata_models.dart';

class HttpKhataRepository implements KhataRepository {
  HttpKhataRepository(this._api);
  final ApiClient _api;

  @override
  Future<KhataPage> page({required bool settled}) async =>
      KhataPage.fromJson(await _api.get('/khata', query: {'status': settled ? 'settled' : 'open'}));

  @override
  Future<void> settle(String id) => _api.postQueueable('/khata/$id/settle');

  @override
  Future<Reminder> reminder(String id) async => Reminder.fromJson(await _api.get('/khata/$id/reminder'));

  @override
  Future<Uint8List> exportCsv({required bool settled}) =>
      _api.getBytes('/khata/export.csv', query: {'status': settled ? 'settled' : 'open'});
}

final khataRepositoryProvider = Provider<KhataRepository>((ref) => HttpKhataRepository(ref.watch(apiClientProvider)));

final khataPageProvider = FutureProvider.autoDispose.family<KhataPage, bool>(
  (ref, settled) => ref.watch(khataRepositoryProvider).page(settled: settled),
);
