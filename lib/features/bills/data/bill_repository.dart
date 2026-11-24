import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/bill_models.dart';

class HttpBillRepository implements BillRepository {
  HttpBillRepository(this._api);
  final ApiClient _api;

  @override
  Future<({bool aiEnabled, List<SampleBill> samples})> samples() async {
    final j = await _api.get('/bills/samples');
    return (
      aiEnabled: j['aiEnabled'] as bool,
      samples: [
        for (final s in (j['samples'] as List).cast<Map<String, dynamic>>())
          SampleBill(key: s['key'] as String, label: s['label'] as String, labelHi: s['labelHi'] as String),
      ],
    );
  }

  @override
  Future<BillDraft> scanPhoto(BillPhoto photo) async => BillDraft.fromJson(
        await _api.post('/bills/scan', body: {
          'image': {'base64': base64Encode(photo.bytes), 'mediaType': photo.mediaType},
        }),
      );

  @override
  Future<BillDraft> scanSample(String key) async => BillDraft.fromJson(await _api.post('/bills/scan', body: {'sampleKey': key}));

  @override
  Future<BillSaved> confirm(String scanId, List<String?> materialIds) async =>
      BillSaved.fromJson(await _api.post('/bills/$scanId/confirm', body: {'materialIds': materialIds}, idempotent: true));
}

final billRepositoryProvider = Provider<BillRepository>((ref) => HttpBillRepository(ref.watch(apiClientProvider)));
final billSamplesProvider = FutureProvider.autoDispose((ref) => ref.watch(billRepositoryProvider).samples());
