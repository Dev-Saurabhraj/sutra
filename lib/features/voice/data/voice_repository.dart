import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/voice_models.dart';

class HttpVoiceRepository implements VoiceRepository {
  HttpVoiceRepository(this._api);
  final ApiClient _api;

  @override
  Future<VoicePreview> preview(String transcript) async =>
      VoicePreview.fromJson(await _api.post('/voice/preview', body: {'transcript': transcript}));

  @override
  Future<List<VoiceResult>> confirm(String entryId) async {
    final j = await _api.post('/voice/$entryId/confirm', idempotent: true);
    return (j['results'] as List).map((e) => VoiceResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) => HttpVoiceRepository(ref.watch(apiClientProvider)));
