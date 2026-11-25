import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';
import '../domain/market_models.dart';

String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HttpMarketRepository implements MarketRepository {
  HttpMarketRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<BrowseResult> browse(MarketFilter filter) async => BrowseResult.fromJson(await _api.get('/market/products', query: filter.query));

  @override
  Future<ProductPage> product(String id) async => ProductPage.fromJson(await _api.get('/market/products/$id'));

  @override
  Future<MakerPage> maker(String slug) async => MakerPage.fromJson(await _api.get('/market/makers/$slug'));

  @override
  Future<QuoteResult> quote({required String productId, required int qty, required DateTime wantedBy}) async =>
      QuoteResult.fromJson(await _api.post('/market/quote', body: {'productId': productId, 'qty': qty, 'wantedBy': _day(wantedBy)}));

  @override
  Future<RequestResult> request({required String productId, required int qty, required DateTime wantedBy, String? note, required bool split}) async =>
      RequestResult.fromJson(await _api.post('/market/requests', idempotent: true, body: {
        'productId': productId,
        'qty': qty,
        'wantedBy': _day(wantedBy),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        'split': split,
      }));

  @override
  Future<List<BuyerOrder>> orders() async {
    final j = await _api.get('/market/orders');
    return [for (final o in (j['orders'] as List).cast<Map<String, dynamic>>()) BuyerOrder.fromJson(o)];
  }

  @override
  Future<BuyerOrderDetail> order(String code) async => BuyerOrderDetail.fromJson(await _api.get('/market/orders/$code'));

  @override
  Future<BuyerOrderDetail> message(String code, String text) async =>
      BuyerOrderDetail.fromJson(await _api.post('/market/orders/$code/messages', body: {'text': text}, idempotent: true));

  @override
  Future<BuyerOrderDetail> claimAdvance(String code, String utr) async =>
      BuyerOrderDetail.fromJson(await _api.post('/market/orders/$code/advance-paid', body: {'utr': utr}, idempotent: true));

  @override
  Future<Uint8List> invoicePdf(String id) => _api.getBytes('/market/invoices/$id/pdf');

  @override
  Future<Uint8List> dispatchPhoto(String code) => _api.getBytes('/market/orders/$code/dispatch-photo');

  @override
  Future<void> signUp(BuyerSignup s, {required String language}) async {
    final j = await _api.post('/onboarding/buyer', idempotent: true, body: {
      'name': s.name,
      'business': s.business,
      'city': s.city,
      'state': s.state,
      if (s.gstin != null && s.gstin!.trim().isNotEmpty) 'gstin': s.gstin!.trim().toUpperCase(),
      'language': language,
    });
    await _tokens.write(StoredTokens(accessToken: j['accessToken'] as String, refreshToken: j['refreshToken'] as String));
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) => HttpMarketRepository(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider)));

final marketFilterProvider = StateProvider<MarketFilter>((_) => const MarketFilter());
final browseProvider = FutureProvider.autoDispose((ref) => ref.watch(marketRepositoryProvider).browse(ref.watch(marketFilterProvider)));
final productPageProvider = FutureProvider.autoDispose.family<ProductPage, String>((ref, id) => ref.watch(marketRepositoryProvider).product(id));
final makerPageProvider = FutureProvider.autoDispose.family<MakerPage, String>((ref, slug) => ref.watch(marketRepositoryProvider).maker(slug));
final buyerOrdersProvider = FutureProvider.autoDispose((ref) => ref.watch(marketRepositoryProvider).orders());
final buyerDispatchPhotoProvider = FutureProvider.autoDispose.family<Uint8List, String>((ref, code) => ref.watch(marketRepositoryProvider).dispatchPhoto(code));

/// One order as the buyer follows it; sending a letter returns the fresh detail.
class BuyerOrderController extends AutoDisposeFamilyAsyncNotifier<BuyerOrderDetail, String> {
  @override
  Future<BuyerOrderDetail> build(String code) => ref.watch(marketRepositoryProvider).order(code);

  Future<void> send(String text) async {
    state = AsyncData(await ref.read(marketRepositoryProvider).message(arg, text));
    ref.invalidate(buyerOrdersProvider);
  }

  Future<void> claimAdvance(String utr) async {
    state = AsyncData(await ref.read(marketRepositoryProvider).claimAdvance(arg, utr));
    ref.invalidate(buyerOrdersProvider);
  }
}

final buyerOrderProvider = AsyncNotifierProvider.autoDispose.family<BuyerOrderController, BuyerOrderDetail, String>(BuyerOrderController.new);
