import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';

double _n(Object? v) => (v as num?)?.toDouble() ?? 0;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ClusterMaker {
  const ClusterMaker(this.j);
  final Map<String, dynamic> j;
  String get businessName => j['businessName'] as String;
  String get name => j['name'] as String;
  String get avatarColor => j['avatarColor'] as String;
  int get machines => _i(j['machines']);
  double get onTimeRate => _n(j['onTimeRate']);
  double get made30 => _n(j['made30']);
  double get sales30 => _n(j['sales30']);
  int get newRequests => _i(j['newRequests']);
  int get openOrders => _i(j['openOrders']);
  int get stockCritical => _i((j['stock'] as Map)['critical']);
  int get stockLow => _i((j['stock'] as Map)['low']);
  String get scheme => (j['gst'] as Map)['scheme'] as String;
  bool? get gstinOk => (j['gst'] as Map)['gstinOk'] as bool?;
}

class ClusterOverview {
  ClusterOverview(Map<String, dynamic> j)
      : name = (j['cluster'] as Map)['name'] as String,
        totals = (j['totals'] as Map).cast<String, dynamic>(),
        makers = [for (final m in (j['makers'] as List).cast<Map<String, dynamic>>()) ClusterMaker(m)];
  final String name;
  final Map<String, dynamic> totals;
  final List<ClusterMaker> makers;
  num t(String k) => (totals[k] as num?) ?? 0;
}

class SplitRow {
  const SplitRow(this.j);
  final Map<String, dynamic> j;
  String get maker => j['maker'] as String;
  String get avatarColor => j['avatarColor'] as String;
  int get capacity => _i(j['capacity']);
  int get assigned => _i(j['assigned']);
  double get value => _n(j['value']);
  double get rate => _n(j['rate']);
}

class SplitPlan {
  SplitPlan(Map<String, dynamic> j)
      : qty = _i(j['qty']),
        covered = _i(j['covered']),
        canMeet = j['canMeet'] as bool,
        value = _n(j['value']),
        rows = [for (final r in (j['rows'] as List).cast<Map<String, dynamic>>()) SplitRow(r)];
  final int qty;
  final int covered;
  final bool canMeet;
  final double value;
  final List<SplitRow> rows;
}

class GroupBuyItem {
  const GroupBuyItem(this.j);
  final Map<String, dynamic> j;
  String get name => j['name'] as String;
  String get nameHi => j['nameHi'] as String;
  String get unit => j['unit'] as String;
  double get qty => _n(j['qty']);
  double get value => _n(j['value']);
  double get possibleSaving => _n(j['possibleSaving']);
  String get message => j['message'] as String;
  List<(String, double)> get makers => [for (final m in (j['makers'] as List).cast<Map<String, dynamic>>()) (m['businessName'] as String, _n(m['qty']))];
  List<(String, String)> get suppliers => [for (final x in (j['suppliers'] as List).cast<Map<String, dynamic>>()) (x['name'] as String, x['phone'] as String)];
}

class ClusterRepository {
  ClusterRepository(this._api);
  final ApiClient _api;

  Future<ClusterOverview> overview() async => ClusterOverview(await _api.get('/cluster'));

  Map<String, dynamic> _bulk(String category, int qty, DateTime wantedBy, String? buyer) =>
      {'category': category, 'qty': qty, 'wantedBy': _day(wantedBy), if (buyer != null && buyer.trim().isNotEmpty) 'buyer': buyer.trim()};

  Future<SplitPlan> split(String category, int qty, DateTime wantedBy) async => SplitPlan(await _api.post('/cluster/split', body: _bulk(category, qty, wantedBy, null)));

  Future<Map<String, dynamic>> send(String category, int qty, DateTime wantedBy, String? buyer) =>
      _api.post('/cluster/split/send', body: _bulk(category, qty, wantedBy, buyer), idempotent: true);

  Future<(double, List<GroupBuyItem>)> groupBuy() async {
    final j = await _api.get('/cluster/group-buy');
    return (_n(j['total']), [for (final i in (j['items'] as List).cast<Map<String, dynamic>>()) GroupBuyItem(i)]);
  }

  Future<Map<String, dynamic>> compliance() => _api.get('/cluster/compliance');
  Future<Map<String, dynamic>> impact() => _api.get('/cluster/impact');
  Future<List<String>> categories() async {
    final j = await _api.get('/cluster/categories');
    return (j['categories'] as List).cast<String>();
  }
}

final clusterRepositoryProvider = Provider((ref) => ClusterRepository(ref.watch(apiClientProvider)));
final clusterOverviewProvider = FutureProvider.autoDispose((ref) => ref.watch(clusterRepositoryProvider).overview());
final groupBuyProvider = FutureProvider.autoDispose((ref) => ref.watch(clusterRepositoryProvider).groupBuy());
final complianceProvider = FutureProvider.autoDispose((ref) => ref.watch(clusterRepositoryProvider).compliance());
final impactProvider = FutureProvider.autoDispose((ref) => ref.watch(clusterRepositoryProvider).impact());
final clusterCategoriesProvider = FutureProvider.autoDispose((ref) => ref.watch(clusterRepositoryProvider).categories());
