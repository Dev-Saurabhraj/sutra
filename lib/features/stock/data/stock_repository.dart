import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/stock_models.dart';

class HttpStockRepository implements StockRepository {
  HttpStockRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<MaterialHealth>> materials() async {
    final j = await _api.get('/stock/materials');
    return (j['materials'] as List).map((e) => MaterialHealth.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ProductStock>> products() async {
    final j = await _api.get('/stock/products');
    return (j['products'] as List).map((e) => ProductStock.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ReorderResult> reorder(String materialId, double qty) async {
    final j = await _api.post('/stock/materials/$materialId/reorder', body: {'qty': qty}, idempotent: true);
    return ReorderResult.fromJson(j);
  }
}

final stockRepositoryProvider = Provider<StockRepository>((ref) => HttpStockRepository(ref.watch(apiClientProvider)));

final materialsProvider = FutureProvider.autoDispose<List<MaterialHealth>>((ref) => ref.watch(stockRepositoryProvider).materials());
final productsProvider = FutureProvider.autoDispose<List<ProductStock>>((ref) => ref.watch(stockRepositoryProvider).products());
