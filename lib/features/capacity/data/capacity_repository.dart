import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/capacity_models.dart';

String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HttpCapacityRepository implements CapacityRepository {
  HttpCapacityRepository(this._api);
  final ApiClient _api;

  @override
  Future<CapacityCalendar> calendar() async => CapacityCalendar.fromJson(await _api.get('/capacity'));

  @override
  Future<(CapacityCalendar, List<OrderAtRisk>)> add(NewDaysOff e) async {
    final j = await _api.post('/capacity', idempotent: true, body: {
      'kind': e.kind.code,
      'startsOn': _day(e.startsOn),
      'endsOn': _day(e.endsOn),
      'machinesOff': e.machinesOff,
      if (e.note != null && e.note!.trim().isNotEmpty) 'note': e.note!.trim(),
    });
    final risk = [
      for (final r in (j['atRisk'] as List? ?? const []).cast<Map<String, dynamic>>())
        OrderAtRisk(code: r['code'] as String, promised: (r['promised'] as num).toInt(), nowPossible: (r['nowPossible'] as num).toInt()),
    ];
    return (CapacityCalendar.fromJson(j), risk);
  }

  @override
  Future<CapacityCalendar> remove(String id) async {
    final j = await _api.delete('/capacity/$id');
    return CapacityCalendar.fromJson(j);
  }
}

final capacityRepositoryProvider = Provider<CapacityRepository>((ref) => HttpCapacityRepository(ref.watch(apiClientProvider)));
final capacityProvider = FutureProvider.autoDispose((ref) => ref.watch(capacityRepositoryProvider).calendar());
