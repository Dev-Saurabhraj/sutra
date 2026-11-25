import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/inventory_models.dart';

class HttpInventoryRepository implements InventoryRepository {
  HttpInventoryRepository(this._api);
  final ApiClient _api;

  @override
  Future<FlowSummary> flow() async => FlowSummary.fromJson(await _api.get('/inventory/flow'));

  @override
  Future<List<Partner>> suppliers() async =>
      ((await _api.get('/inventory/suppliers'))['suppliers'] as List).map((e) => Partner.supplier(e as Map<String, dynamic>)).toList();

  @override
  Future<List<Partner>> clients() async =>
      ((await _api.get('/inventory/clients'))['clients'] as List).map((e) => Partner.client(e as Map<String, dynamic>)).toList();

  @override
  Future<Partner> addSupplier({required String name, required String phone, required String city, required int leadTimeDays}) async =>
      Partner.supplier(await _api.post('/inventory/suppliers', body: {'name': name, 'phone': phone, 'city': city, 'leadTimeDays': leadTimeDays}, idempotent: true));

  @override
  Future<Partner> addClient({required String name, String? business, required String phone, required String city}) async =>
      Partner.client(await _api.post('/inventory/clients', body: {'name': name, 'business': ?business, 'phone': phone, 'city': city}, idempotent: true));

  @override
  Future<void> addMaterial({required String name, required String unit, required double cost, required double stock, String? supplierId}) =>
      _api.post('/inventory/materials', body: {'name': name, 'unit': unit, 'costPerUnit': cost, 'stock': stock, 'supplierId': ?supplierId}, idempotent: true);

  @override
  Future<void> addProduct({required String name, required double price, required int stock, required Map<String, double> recipe}) => _api.post(
        '/inventory/products',
        body: {
          'name': name,
          'price': price,
          'stock': stock,
          'recipe': [for (final e in recipe.entries) {'materialId': e.key, 'qtyPerUnit': e.value}],
        },
        idempotent: true,
      );

  @override
  Future<void> stockIn(String materialId, {required double qty, double? rate, String? supplierId}) =>
      _api.postQueueable('/inventory/materials/$materialId/stock-in', body: {'qty': qty, 'rate': ?rate, 'supplierId': ?supplierId});

  @override
  Future<void> produce(String productId, {required int qty, String? workerId}) =>
      _api.postQueueable('/inventory/products/$productId/produce', body: {'qty': qty, 'workerId': ?workerId});

  @override
  Future<SaleResult> sell(String productId, {required int qty, double? rate, String? clientId, String? walkInName, String? walkInCity}) async {
    final j = await _api.post(
      '/inventory/products/$productId/sell',
      body: {
        'qty': qty,
        'rate': ?rate,
        'clientId': ?clientId,
        if (clientId == null) 'walkIn': {'name': walkInName ?? '', 'city': walkInCity ?? ''},
      },
      idempotent: true,
    );
    final inv = j['invoice'] as Map<String, dynamic>;
    return SaleResult(invoiceNumber: inv['number'] as String, total: (inv['total'] as num).toDouble());
  }

  @override
  Future<void> adjustMaterial(String materialId, double actual) => _api.postQueueable('/inventory/materials/$materialId/adjust', body: {'actual': actual});

  @override
  Future<void> adjustProduct(String productId, int actual) => _api.postQueueable('/inventory/products/$productId/adjust', body: {'actual': actual});

  @override
  Future<List<Movement>> movements({String? materialId, String? productId}) async {
    final j = await _api.get('/inventory/movements', query: {'materialId': ?materialId, 'productId': ?productId});
    return (j['movements'] as List).map((e) => Movement.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) => HttpInventoryRepository(ref.watch(apiClientProvider)));

final flowProvider = FutureProvider.autoDispose<FlowSummary>((ref) => ref.watch(inventoryRepositoryProvider).flow());
final suppliersProvider = FutureProvider.autoDispose<List<Partner>>((ref) => ref.watch(inventoryRepositoryProvider).suppliers());
final clientsProvider = FutureProvider.autoDispose<List<Partner>>((ref) => ref.watch(inventoryRepositoryProvider).clients());
