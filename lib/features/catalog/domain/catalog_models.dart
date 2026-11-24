import 'dart:typed_data';

import '../../orders/domain/order_models.dart';

/// One product as buyers will see it, with what it costs you to make.
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.category,
    required this.price,
    required this.mrp,
    required this.stock,
    required this.palette,
    required this.imageUrl,
    required this.story,
    required this.published,
    required this.ready,
    required this.price0,
  });

  final String id;
  final String name;
  final String nameHi;
  final String category;
  final double price;
  final double mrp;
  final int stock;
  final String palette;
  final String? imageUrl;
  final String story;
  final bool published;

  /// Has a photo and a story: good enough to show buyers.
  final bool ready;

  /// Cost and margin at the current list price.
  final PriceCheck price0;

  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
        id: j['id'] as String,
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        category: j['category'] as String,
        price: (j['price'] as num).toDouble(),
        mrp: (j['mrp'] as num).toDouble(),
        stock: (j['stock'] as num).toInt(),
        palette: j['palette'] as String,
        imageUrl: j['imageUrl'] as String?,
        story: j['story'] as String? ?? '',
        published: j['published'] as bool,
        ready: j['ready'] as bool,
        price0: PriceCheck.fromJson(j, rate: (j['price'] as num).toDouble()),
      );
}

class CatalogList {
  const CatalogList({required this.published, required this.total, required this.items});
  final int published;
  final int total;
  final List<CatalogItem> items;

  factory CatalogList.fromJson(Map<String, dynamic> j) => CatalogList(
        published: (j['published'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        items: [for (final i in (j['items'] as List).cast<Map<String, dynamic>>()) CatalogItem.fromJson(i)],
      );
}

/// A story written from the maker's note and photo; nothing is public until it is saved and published.
class StoryDraft {
  const StoryDraft({required this.imageUrl, required this.title, required this.story, required this.tags, required this.writer});
  final String? imageUrl;
  final String title;
  final String story;
  final List<String> tags;

  /// "claude" or "template": the app says which, so nobody mistakes a template for a written story.
  final String writer;

  factory StoryDraft.fromJson(Map<String, dynamic> j) => StoryDraft(
        imageUrl: j['imageUrl'] as String?,
        title: j['title'] as String,
        story: j['story'] as String,
        tags: (j['tags'] as List).cast<String>(),
        writer: j['writer'] as String,
      );
}

class CatalogPhoto {
  const CatalogPhoto({required this.bytes, required this.mediaType});
  final Uint8List bytes;
  final String mediaType;
}

abstract interface class CatalogRepository {
  Future<CatalogList> list();
  Future<StoryDraft> draft(String productId, {required String note, CatalogPhoto? photo});
  Future<CatalogItem> update(String productId, {String? name, String? story, double? price, bool? published, bool acceptBelowCost = false});
}
