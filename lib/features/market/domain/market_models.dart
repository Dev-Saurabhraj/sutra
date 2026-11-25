import 'dart:typed_data';

import '../../orders/domain/order_models.dart';

double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

/// "Can Deliver" (B2): pieces ready after the maker's other orders, and pieces per week after days off.
class DeliverBadge {
  const DeliverBadge({required this.ready, required this.perWeek, required this.slowWeek});
  final int ready;
  final int perWeek;

  /// Days off this week (wedding, repair…): fewer pieces than usual.
  final bool slowWeek;

  static DeliverBadge? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    return DeliverBadge(ready: (j['ready'] as num).toInt(), perWeek: (j['perWeek'] as num).toInt(), slowWeek: j['slowWeek'] as bool? ?? false);
  }
}

class CardMaker {
  const CardMaker({required this.slug, required this.businessName, required this.city, required this.cluster, required this.onTimeRate, required this.avatarColor});
  final String slug;
  final String businessName;
  final String city;
  final String? cluster;
  final double onTimeRate;
  final String avatarColor;

  factory CardMaker.fromJson(Map<String, dynamic> j) => CardMaker(
        slug: j['slug'] as String,
        businessName: j['businessName'] as String,
        city: j['city'] as String,
        cluster: j['cluster'] as String?,
        onTimeRate: _num(j['onTimeRate']),
        avatarColor: j['avatarColor'] as String,
      );
}

class MarketCard {
  const MarketCard({required this.id, required this.name, required this.category, required this.price, required this.palette, required this.imageUrl, required this.maker, required this.badge});
  final String id;
  final String name;
  final String category;
  final double price;
  final String palette;
  final String? imageUrl;
  final CardMaker maker;
  final DeliverBadge? badge;

  factory MarketCard.fromJson(Map<String, dynamic> j) => MarketCard(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        price: _num(j['price']),
        palette: j['palette'] as String,
        imageUrl: j['imageUrl'] as String?,
        maker: CardMaker.fromJson(j['maker'] as Map<String, dynamic>),
        badge: DeliverBadge.fromJson(j['badge']),
      );
}

class Facet {
  const Facet(this.key, this.label, {this.labelHi, this.emoji});
  final String key;
  final String label;
  final String? labelHi;
  final String? emoji;
}

class Facets {
  const Facets({required this.industries, required this.clusters, required this.categories});
  final List<Facet> industries;
  final List<Facet> clusters;
  final List<String> categories;

  factory Facets.fromJson(Map<String, dynamic> j) => Facets(
        industries: [
          for (final i in (j['industries'] as List).cast<Map<String, dynamic>>())
            Facet(i['key'] as String, i['name'] as String, labelHi: i['nameHi'] as String?, emoji: i['emoji'] as String?),
        ],
        clusters: [for (final c in (j['clusters'] as List).cast<Map<String, dynamic>>()) Facet(c['slug'] as String, c['name'] as String)],
        categories: (j['categories'] as List).cast<String>(),
      );
}

class BrowseResult {
  const BrowseResult({required this.facets, required this.items});
  final Facets facets;
  final List<MarketCard> items;

  factory BrowseResult.fromJson(Map<String, dynamic> j) => BrowseResult(
        facets: Facets.fromJson(j['facets'] as Map<String, dynamic>),
        items: [for (final i in (j['items'] as List).cast<Map<String, dynamic>>()) MarketCard.fromJson(i)],
      );
}

/// What to filter the bazaar by. Equal filters → same provider instance.
class MarketFilter {
  const MarketFilter({this.q = '', this.industry, this.cluster, this.category});
  final String q;
  final String? industry;
  final String? cluster;
  final String? category;

  Map<String, dynamic> get query => {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        'industry': ?industry,
        'cluster': ?cluster,
        'category': ?category,
      };

  MarketFilter copyWith({String? q, String? industry, String? cluster, String? category, bool clearIndustry = false, bool clearCluster = false, bool clearCategory = false}) =>
      MarketFilter(
        q: q ?? this.q,
        industry: clearIndustry ? null : (industry ?? this.industry),
        cluster: clearCluster ? null : (cluster ?? this.cluster),
        category: clearCategory ? null : (category ?? this.category),
      );

  @override
  bool operator ==(Object other) => other is MarketFilter && other.q == q && other.industry == industry && other.cluster == cluster && other.category == category;

  @override
  int get hashCode => Object.hash(q, industry, cluster, category);
}

/// The trust profile (B7): each fact says how it was checked.
class MakerTrust {
  const MakerTrust({
    required this.slug,
    required this.name,
    required this.businessName,
    required this.city,
    required this.state,
    required this.story,
    required this.avatarColor,
    required this.industry,
    required this.industryEmoji,
    required this.cluster,
    required this.machines,
    required this.since,
    required this.ordersDone,
    required this.onTimeRate,
    required this.gstin,
    required this.gstinFormatOk,
    required this.gstScheme,
    required this.udyamRegistered,
    required this.marks,
  });

  final String slug;
  final String name;
  final String businessName;
  final String city;
  final String state;
  final String story;
  final String avatarColor;
  final String industry;
  final String industryEmoji;
  final String? cluster;
  final int machines;
  final DateTime since;
  final int ordersDone;
  final double onTimeRate;
  final String? gstin;
  final bool gstinFormatOk;
  final String gstScheme;
  final bool udyamRegistered;
  final List<String> marks;

  factory MakerTrust.fromJson(Map<String, dynamic> j) {
    final ind = j['industry'] as Map<String, dynamic>;
    return MakerTrust(
      slug: j['slug'] as String,
      name: j['name'] as String,
      businessName: j['businessName'] as String,
      city: j['city'] as String,
      state: j['state'] as String,
      story: j['story'] as String? ?? '',
      avatarColor: j['avatarColor'] as String,
      industry: ind['name'] as String,
      industryEmoji: ind['emoji'] as String? ?? '',
      cluster: (j['cluster'] as Map<String, dynamic>?)?['name'] as String?,
      machines: (j['machines'] as num).toInt(),
      since: DateTime.parse(j['since'] as String),
      ordersDone: (j['ordersDone'] as num).toInt(),
      onTimeRate: _num(j['onTimeRate']),
      gstin: j['gstin'] as String?,
      gstinFormatOk: j['gstinFormatOk'] as bool? ?? false,
      gstScheme: j['gstScheme'] as String,
      udyamRegistered: j['udyamRegistered'] as bool? ?? false,
      marks: (j['marks'] as List? ?? const []).cast<String>(),
    );
  }
}

class ProductPage {
  const ProductPage({required this.product, required this.story, required this.mrp, required this.gstRate, required this.maker, required this.more});
  final MarketCard product;
  final String story;
  final double mrp;
  final double gstRate;
  final MakerTrust maker;
  final List<MarketCard> more;

  factory ProductPage.fromJson(Map<String, dynamic> j) {
    final p = j['product'] as Map<String, dynamic>;
    return ProductPage(
      product: MarketCard.fromJson(p),
      story: p['story'] as String? ?? '',
      mrp: _num(p['mrp']),
      gstRate: _num(p['gstRate']),
      maker: MakerTrust.fromJson(j['maker'] as Map<String, dynamic>),
      more: [for (final m in (j['more'] as List).cast<Map<String, dynamic>>()) MarketCard.fromJson(m)],
    );
  }
}

class MakerPage {
  const MakerPage({required this.maker, required this.products});
  final MakerTrust maker;
  final List<MarketCard> products;

  factory MakerPage.fromJson(Map<String, dynamic> j) => MakerPage(
        maker: MakerTrust.fromJson(j['maker'] as Map<String, dynamic>),
        products: [for (final m in (j['products'] as List).cast<Map<String, dynamic>>()) MarketCard.fromJson(m)],
      );
}

/// Which document, how much GST, and whether the seller may sell to the buyer's state at all.
class SaleTerms {
  const SaleTerms({required this.allowed, required this.reason, required this.warning, required this.document, required this.taxable, required this.tax, required this.total, required this.interState});
  final bool allowed;
  final String? reason;
  final String? warning;
  final String? document;
  final double taxable;
  final double tax;
  final double total;
  final bool interState;

  factory SaleTerms.fromJson(Map<String, dynamic> j) => SaleTerms(
        allowed: j['allowed'] as bool,
        reason: j['reasonEn'] as String?,
        warning: j['warningEn'] as String?,
        document: j['document'] as String?,
        taxable: _num(j['taxable']),
        tax: _num(j['tax']),
        total: _num(j['total']),
        interState: j['interState'] as bool? ?? false,
      );
}

class SplitRow {
  const SplitRow({required this.assigned, required this.maker, required this.product, required this.value});
  final int assigned;
  final MakerTrust maker;
  final MarketCard product;
  final double value;
}

/// B4: other makers of the cluster make what one maker can't by the date.
class SplitOption {
  const SplitOption({required this.covered, required this.qty, required this.canMeet, required this.rows});
  final int covered;
  final int qty;
  final bool canMeet;
  final List<SplitRow> rows;

  double get value => rows.fold(0, (a, r) => a + r.value);

  static SplitOption? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    return SplitOption(
      covered: (j['covered'] as num).toInt(),
      qty: (j['qty'] as num).toInt(),
      canMeet: j['canMeet'] as bool,
      rows: [
        for (final r in (j['rows'] as List).cast<Map<String, dynamic>>())
          SplitRow(
            assigned: (r['assigned'] as num).toInt(),
            maker: MakerTrust.fromJson(r['maker'] as Map<String, dynamic>),
            product: MarketCard.fromJson(r['product'] as Map<String, dynamic>),
            value: _num(r['value']),
          ),
      ],
    );
  }
}

class QuoteResult {
  const QuoteResult({required this.product, required this.qty, required this.wantedBy, required this.plan, required this.sale, required this.split});
  final MarketCard product;
  final int qty;
  final DateTime wantedBy;
  final DeliveryPlan plan;
  final SaleTerms sale;
  final SplitOption? split;

  factory QuoteResult.fromJson(Map<String, dynamic> j) => QuoteResult(
        product: MarketCard.fromJson(j['product'] as Map<String, dynamic>),
        qty: (j['qty'] as num).toInt(),
        wantedBy: DateTime.parse(j['wantedBy'] as String),
        plan: DeliveryPlan.fromJson(j['plan'] as Map<String, dynamic>),
        sale: SaleTerms.fromJson(j['sale'] as Map<String, dynamic>),
        split: SplitOption.fromJson(j['split']),
      );
}

class RequestedOrder {
  const RequestedOrder({required this.code, required this.maker, required this.qty, required this.proformaId, required this.proformaNumber, required this.total});
  final String code;
  final String maker;
  final int qty;
  final String proformaId;
  final String proformaNumber;
  final double total;
}

class RequestResult {
  const RequestResult({required this.group, required this.orders, required this.total});
  final String? group;
  final List<RequestedOrder> orders;
  final double total;

  factory RequestResult.fromJson(Map<String, dynamic> j) => RequestResult(
        group: j['group'] as String?,
        total: _num(j['total']),
        orders: [
          for (final o in (j['orders'] as List).cast<Map<String, dynamic>>())
            RequestedOrder(
              code: o['code'] as String,
              maker: o['maker'] as String,
              qty: (o['qty'] as num).toInt(),
              proformaId: (o['proforma'] as Map)['id'] as String,
              proformaNumber: (o['proforma'] as Map)['number'] as String,
              total: _num((o['proforma'] as Map)['total']),
            ),
        ],
      );
}

/// A buyer's order as they follow it.
class BuyerOrder {
  const BuyerOrder({
    required this.code,
    required this.stage,
    required this.qty,
    required this.rate,
    required this.productName,
    required this.palette,
    required this.imageUrl,
    required this.maker,
    required this.makerSlug,
    required this.makerColor,
    required this.createdAt,
    this.wantedBy,
    this.promisedQtyByWanted,
    this.fullDate,
    this.dispatchedAt,
    this.deliveredAt,
    this.transporter,
    this.lrNumber,
    this.hasDispatchPhoto = false,
    this.group,
    this.lastMessage,
    this.advance,
  });

  final String code;
  final OrderStage stage;
  final int qty;
  final double rate;
  final String productName;
  final String palette;
  final String? imageUrl;
  final String maker;
  final String makerSlug;
  final String makerColor;
  final DateTime createdAt;
  final DateTime? wantedBy;
  final int? promisedQtyByWanted;
  final DateTime? fullDate;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String? transporter;
  final String? lrNumber;
  final bool hasDispatchPhoto;
  final String? group;
  final String? lastMessage;
  final AdvanceInfo? advance;

  double get value => qty * rate;

  factory BuyerOrder.fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) => j[k] == null ? null : DateTime.parse(j[k] as String);
    final p = j['product'] as Map<String, dynamic>;
    final m = j['maker'] as Map<String, dynamic>;
    return BuyerOrder(
      code: j['code'] as String,
      stage: OrderStage.parse(j['stage'] as String),
      qty: (j['qty'] as num).toInt(),
      rate: _num(j['rate']),
      productName: p['name'] as String,
      palette: p['palette'] as String,
      imageUrl: p['imageUrl'] as String?,
      maker: m['businessName'] as String,
      makerSlug: m['slug'] as String,
      makerColor: m['avatarColor'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      wantedBy: d('wantedBy'),
      promisedQtyByWanted: (j['promisedQtyByWanted'] as num?)?.toInt(),
      fullDate: d('fullDate'),
      dispatchedAt: d('dispatchedAt'),
      deliveredAt: d('deliveredAt'),
      transporter: j['transporter'] as String?,
      lrNumber: j['lrNumber'] as String?,
      hasDispatchPhoto: j['hasDispatchPhoto'] as bool? ?? false,
      group: j['parentCode'] as String?,
      lastMessage: (j['lastMessage'] as Map<String, dynamic>?)?['text'] as String?,
      advance: AdvanceInfo.fromJson(j['advance']),
    );
  }
}

class BuyerLetter {
  const BuyerLetter({required this.id, required this.mine, required this.text, required this.original, required this.translated, required this.at});
  final String id;
  final bool mine;
  final String text;
  final String original;
  final bool translated;
  final DateTime at;

  factory BuyerLetter.fromJson(Map<String, dynamic> j) => BuyerLetter(
        id: j['id'] as String,
        mine: j['mine'] as bool,
        text: j['text'] as String,
        original: j['original'] as String,
        translated: j['translated'] as bool? ?? false,
        at: DateTime.parse(j['createdAt'] as String),
      );
}

class BuyerOrderDetail {
  const BuyerOrderDetail({required this.order, required this.letters, required this.invoices, required this.group});
  final BuyerOrder order;
  final List<BuyerLetter> letters;
  final List<OrderInvoice> invoices;
  final List<GroupPart> group;

  factory BuyerOrderDetail.fromJson(Map<String, dynamic> j) => BuyerOrderDetail(
        order: BuyerOrder.fromJson(j['order'] as Map<String, dynamic>),
        letters: [for (final m in (j['messages'] as List).cast<Map<String, dynamic>>()) BuyerLetter.fromJson(m)],
        invoices: [
          for (final i in (j['invoices'] as List).cast<Map<String, dynamic>>())
            OrderInvoice(id: i['id'] as String, number: i['number'] as String, kind: i['kind'] as String, total: _num(i['total'])),
        ],
        group: [for (final g in (j['group'] as List).cast<Map<String, dynamic>>()) GroupPart.fromJson(g)],
      );
}

class BuyerSignup {
  const BuyerSignup({required this.name, required this.business, required this.city, required this.state, this.gstin});
  final String name;
  final String business;
  final String city;
  final String state;
  final String? gstin;
}

abstract interface class MarketRepository {
  Future<BrowseResult> browse(MarketFilter filter);
  Future<ProductPage> product(String id);
  Future<MakerPage> maker(String slug);
  Future<QuoteResult> quote({required String productId, required int qty, required DateTime wantedBy});
  Future<RequestResult> request({required String productId, required int qty, required DateTime wantedBy, String? note, required bool split});
  Future<List<BuyerOrder>> orders();
  Future<BuyerOrderDetail> order(String code);
  Future<BuyerOrderDetail> message(String code, String text);
  Future<Uint8List> invoicePdf(String id);
  Future<Uint8List> dispatchPhoto(String code);
  Future<void> signUp(BuyerSignup s, {required String language});
  Future<BuyerOrderDetail> claimAdvance(String code, String utr);
}
