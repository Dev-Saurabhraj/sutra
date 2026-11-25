import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/catalog_models.dart';

class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._api);
  final ApiClient _api;

  @override
  Future<CatalogList> list() async => CatalogList.fromJson(await _api.get('/catalog'));

  @override
  Future<StoryDraft> draft(String productId, {required String note, CatalogPhoto? photo}) async => StoryDraft.fromJson(
        await _api.post('/catalog/$productId/draft', body: {
          'note': note,
          if (photo != null) 'photo': {'base64': base64Encode(photo.bytes), 'mediaType': photo.mediaType},
        }),
      );

  @override
  Future<CatalogItem> update(String productId, {String? name, String? story, double? price, bool? published, bool acceptBelowCost = false}) async =>
      CatalogItem.fromJson(await _api.patch('/catalog/$productId', body: {
        'name': ?name,
        'story': ?story,
        'price': ?price,
        'published': ?published,
        if (acceptBelowCost) 'acceptBelowCost': true,
      }));
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => HttpCatalogRepository(ref.watch(apiClientProvider)));
final catalogProvider = FutureProvider.autoDispose((ref) => ref.watch(catalogRepositoryProvider).list());
