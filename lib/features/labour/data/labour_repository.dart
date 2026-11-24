import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/labour_models.dart';

class HttpLabourRepository implements LabourRepository {
  HttpLabourRepository(this._api);
  final ApiClient _api;

  @override
  Future<TeamSummary> team() async => TeamSummary.fromJson(await _api.get('/labour'));

  @override
  Future<void> addWorker({required String name, String? phone, required WageType wageType, required double rate}) => _api.post(
        '/labour/workers',
        body: {'name': name, 'phone': ?phone, 'wageType': wageType.api, 'rate': rate, 'payCycle': wageType == WageType.monthly ? 'MONTHLY' : 'WEEKLY'},
        idempotent: true,
      );

  @override
  Future<TeamSummary> markAttendance(Map<String, double> marks) async => TeamSummary.fromJson(await _api.post(
        '/labour/attendance',
        body: {
          'marks': [for (final e in marks.entries) {'workerId': e.key, 'units': e.value}],
        },
      ));

  @override
  Future<void> addPieceWork(String workerId, {required double qty}) => _api.postQueueable('/labour/workers/$workerId/piece', body: {'qty': qty});

  @override
  Future<PayPreview> payPreview(String workerId) async => PayPreview.fromJson(await _api.get('/labour/workers/$workerId/pay-preview'));

  @override
  Future<WageSlip> pay(String workerId, {required String mode, double? cash}) async {
    final j = await _api.post('/labour/workers/$workerId/pay', body: {'mode': mode, 'cash': ?cash}, idempotent: true);
    return WageSlip.fromJson(j['slip'] as Map<String, dynamic>);
  }

  @override
  Future<void> giveAdvance(String workerId, {required double amount, required String mode}) =>
      _api.post('/labour/workers/$workerId/advance', body: {'amount': amount, 'mode': mode}, idempotent: true);

  @override
  Future<List<LedgerItem>> history(String workerId) async {
    final j = await _api.get('/labour/workers/$workerId/history');
    final items = [
      for (final e in (j['entries'] as List).cast<Map<String, dynamic>>())
        LedgerItem(kind: e['kind'] as String, amount: (e['amount'] as num).toDouble(), at: DateTime.parse(e['date'] as String), units: (e['units'] as num).toDouble(), note: e['note'] as String?),
      for (final p in (j['payments'] as List).cast<Map<String, dynamic>>())
        LedgerItem(kind: p['kind'] as String, amount: (p['amount'] as num).toDouble(), at: DateTime.parse(p['paidAt'] as String), note: p['note'] as String?),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return items;
  }

  @override
  Future<WageSlip> slip(String workerId) async => WageSlip.fromJson(await _api.get('/labour/workers/$workerId/slip'));
}

final labourRepositoryProvider = Provider<LabourRepository>((ref) => HttpLabourRepository(ref.watch(apiClientProvider)));
final teamProvider = FutureProvider.autoDispose<TeamSummary>((ref) => ref.watch(labourRepositoryProvider).team());
