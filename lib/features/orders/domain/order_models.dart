import 'dart:typed_data';

/// Where an order is in its life. The server decides which moves are allowed ([OrderDetail.actions]).
enum OrderStage {
  quoted,
  confirmed,
  making,
  dispatched,
  delivered,
  declined;

  static OrderStage parse(String s) => switch (s) {
        'CONFIRMED' => OrderStage.confirmed,
        'IN_PRODUCTION' => OrderStage.making,
        'DISPATCHED' => OrderStage.dispatched,
        'DELIVERED' => OrderStage.delivered,
        'DECLINED' => OrderStage.declined,
        _ => OrderStage.quoted,
      };

  /// Position on the stage thread (declined sits off the thread).
  int get step => switch (this) {
        OrderStage.quoted => 0,
        OrderStage.confirmed || OrderStage.making => 1,
        OrderStage.dispatched => 2,
        OrderStage.delivered => 3,
        OrderStage.declined => 0,
      };
}

enum OrderTab { fresh, active, done }

extension OrderTabQuery on OrderTab {
  String get query => switch (this) { OrderTab.fresh => 'new', OrderTab.active => 'active', OrderTab.done => 'done' };
}

enum OrderAction { accept, decline, dispatch, deliver }

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

class OrderProduct {
  const OrderProduct({required this.id, required this.name, required this.nameHi, required this.palette, required this.imageUrl, required this.price, required this.stock});
  final String id;
  final String name;
  final String nameHi;
  final String palette;
  final String? imageUrl;
  final double price;
  final int stock;

  factory OrderProduct.fromJson(Map<String, dynamic> j) => OrderProduct(
        id: j['id'] as String,
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        palette: j['palette'] as String,
        imageUrl: j['imageUrl'] as String?,
        price: _num(j['price']),
        stock: (j['stock'] as num).toInt(),
      );
}

class OrderBuyer {
  const OrderBuyer({required this.name, required this.business, required this.city, required this.phone});
  final String name;
  final String business;
  final String city;
  final String? phone;

  factory OrderBuyer.fromJson(Map<String, dynamic> j) =>
      OrderBuyer(name: j['name'] as String, business: j['business'] as String, city: j['city'] as String, phone: j['phone'] as String?);
}

class LastMessage {
  const LastMessage({required this.text, required this.textHi, required this.fromBuyer});
  final String text;
  final String? textHi;
  final bool fromBuyer;
}

class Order {
  const Order({
    required this.code,
    required this.stage,
    required this.qty,
    required this.rate,
    required this.product,
    required this.createdAt,
    this.buyer,
    this.wantedBy,
    this.promisedQtyByWanted,
    this.fullDate,
    this.dispatchedAt,
    this.deliveredAt,
    this.transporter,
    this.lrNumber,
    this.hasDispatchPhoto = false,
    this.lastMessage,
  });

  final String code;
  final OrderStage stage;
  final int qty;
  final double rate;
  final OrderProduct product;
  final OrderBuyer? buyer;
  final DateTime createdAt;
  final DateTime? wantedBy;
  final int? promisedQtyByWanted;
  final DateTime? fullDate;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String? transporter;
  final String? lrNumber;
  final bool hasDispatchPhoto;
  final LastMessage? lastMessage;

  double get value => qty * rate;

  /// Who to show: the buyer's business, or a walk-in / agent sale.
  String get party => buyer == null ? '—' : '${buyer!.business}, ${buyer!.city}';

  factory Order.fromJson(Map<String, dynamic> j) {
    final m = j['lastMessage'] as Map<String, dynamic>?;
    return Order(
      code: j['code'] as String,
      stage: OrderStage.parse(j['status'] as String),
      qty: (j['qty'] as num).toInt(),
      rate: _num(j['rate']),
      product: OrderProduct.fromJson(j['product'] as Map<String, dynamic>),
      buyer: j['buyer'] == null ? null : OrderBuyer.fromJson(j['buyer'] as Map<String, dynamic>),
      createdAt: DateTime.parse(j['createdAt'] as String),
      wantedBy: _date(j['wantedBy']),
      promisedQtyByWanted: (j['promisedQtyByWanted'] as num?)?.toInt(),
      fullDate: _date(j['fullDate']),
      dispatchedAt: _date(j['dispatchedAt']),
      deliveredAt: _date(j['deliveredAt']),
      transporter: j['transporter'] as String?,
      lrNumber: j['lrNumber'] as String?,
      hasDispatchPhoto: j['hasDispatchPhoto'] as bool? ?? false,
      lastMessage: m == null ? null : LastMessage(text: m['text'] as String, textHi: m['textHi'] as String?, fromBuyer: m['sender'] == 'BUYER'),
    );
  }
}

class OrderInbox {
  const OrderInbox({required this.counts, required this.orders});
  final Map<OrderTab, int> counts;
  final List<Order> orders;

  factory OrderInbox.fromJson(Map<String, dynamic> j) {
    final c = j['counts'] as Map<String, dynamic>;
    return OrderInbox(
      counts: {for (final t in OrderTab.values) t: (c[t.query] as num?)?.toInt() ?? 0},
      orders: [for (final o in (j['orders'] as List).cast<Map<String, dynamic>>()) Order.fromJson(o)],
    );
  }
}

/// A material that runs out before the order is done, and when to order it.
class Shortfall {
  const Shortfall({required this.name, required this.nameHi, required this.unit, required this.needQty, required this.supplierName, required this.orderBy, required this.late});
  final String name;
  final String nameHi;
  final String unit;
  final double needQty;
  final String? supplierName;
  final DateTime? orderBy;
  final bool late;

  factory Shortfall.fromJson(Map<String, dynamic> j) => Shortfall(
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        unit: j['unit'] as String,
        needQty: _num(j['needQty']),
        supplierName: j['supplierName'] as String?,
        orderBy: _date(j['orderBy']),
        late: j['late'] as bool? ?? false,
      );
}

class CurvePoint {
  const CurvePoint(this.date, this.units);
  final DateTime date;
  final double units;
}

/// The honest answer to "can I deliver?": how many by the date they want, and when all of it.
class DeliveryPlan {
  const DeliveryPlan({
    required this.qty,
    required this.wantedBy,
    required this.ready,
    required this.perDay,
    required this.qtyByWanted,
    required this.fullDate,
    required this.canMeet,
    required this.shortfalls,
    required this.curve,
  });

  final int qty;
  final DateTime wantedBy;
  final int ready;
  final double perDay;
  final int qtyByWanted;
  final DateTime fullDate;
  final bool canMeet;
  final List<Shortfall> shortfalls;
  final List<CurvePoint> curve;

  /// Share that can be ready by the wanted date (0..1).
  double get onTimeShare => qty == 0 ? 1 : (qtyByWanted / qty).clamp(0, 1).toDouble();

  factory DeliveryPlan.fromJson(Map<String, dynamic> j) => DeliveryPlan(
        qty: (j['qty'] as num).toInt(),
        wantedBy: DateTime.parse(j['wantedBy'] as String),
        ready: (j['ready'] as num).toInt(),
        perDay: _num(j['perDay']),
        qtyByWanted: (j['qtyByWanted'] as num).toInt(),
        fullDate: DateTime.parse(j['fullDate'] as String),
        canMeet: j['canMeet'] as bool,
        shortfalls: [for (final s in (j['shortfalls'] as List).cast<Map<String, dynamic>>()) Shortfall.fromJson(s)],
        curve: [for (final p in (j['curve'] as List).cast<Map<String, dynamic>>()) CurvePoint(DateTime.parse(p['date'] as String), _num(p['units']))],
      );
}

/// What one piece costs to make, and what is left at the asked rate.
class PriceCheck {
  const PriceCheck({required this.rate, required this.materials, required this.labour, required this.cost, required this.perUnit, required this.pct, required this.belowCost, required this.thin, required this.labourKnown});
  final double rate;
  final double materials;
  final double labour;
  final double cost;
  final double perUnit;
  final double pct;
  final bool belowCost;
  final bool thin;
  final bool labourKnown;

  /// Below this share of the price, what you keep is called thin (same rule as the server).
  static const thinMargin = 0.1;

  /// The same cost at another price (live while the maker types a new price).
  PriceCheck at(double newRate) {
    final keep = newRate - cost;
    final share = newRate > 0 ? keep / newRate : 0.0;
    return PriceCheck(
      rate: newRate, materials: materials, labour: labour, cost: cost, perUnit: keep, pct: (share * 1000).round() / 10,
      belowCost: keep < 0, thin: keep >= 0 && share < thinMargin, labourKnown: labourKnown,
    );
  }

  factory PriceCheck.fromJson(Map<String, dynamic> j, {double? rate}) {
    final c = j['cost'] as Map<String, dynamic>;
    final m = j['margin'] as Map<String, dynamic>;
    return PriceCheck(
      rate: rate ?? _num(j['rate']),
      materials: _num(c['materials']),
      labour: _num(c['labour']),
      cost: _num(c['total']),
      perUnit: _num(m['perUnit']),
      pct: _num(m['pct']),
      belowCost: m['belowCost'] as bool,
      thin: m['thin'] as bool,
      labourKnown: j['labourKnown'] as bool? ?? false,
    );
  }
}

class OrderMessage {
  const OrderMessage({required this.id, required this.fromBuyer, required this.text, required this.textHi, required this.textEn, required this.translated, required this.at});
  final String id;
  final bool fromBuyer;
  final String text;
  final String? textHi;
  final String? textEn;
  final bool translated;
  final DateTime at;

  /// The producer reads Hindi (when available); the original is always one tap away.
  String forProducer(bool hindi) => hindi ? (textHi ?? text) : (textEn ?? text);

  factory OrderMessage.fromJson(Map<String, dynamic> j) => OrderMessage(
        id: j['id'] as String,
        fromBuyer: j['sender'] == 'BUYER',
        text: j['text'] as String,
        textHi: j['textHi'] as String?,
        textEn: j['textEn'] as String?,
        translated: j['translated'] as bool? ?? false,
        at: DateTime.parse(j['createdAt'] as String),
      );
}

class OrderInvoice {
  const OrderInvoice({required this.id, required this.number, required this.kind, required this.total});
  final String id;
  final String number;
  final String kind;
  final double total;
}

class OrderDetail {
  const OrderDetail({required this.order, required this.actions, required this.plan, required this.price, required this.messages, required this.invoices});
  final Order order;
  final Set<OrderAction> actions;
  final DeliveryPlan? plan;
  final PriceCheck? price;
  final List<OrderMessage> messages;
  final List<OrderInvoice> invoices;

  factory OrderDetail.fromJson(Map<String, dynamic> j) => OrderDetail(
        order: Order.fromJson(j['order'] as Map<String, dynamic>),
        actions: {
          for (final a in (j['actions'] as List).cast<String>())
            ...OrderAction.values.where((v) => v.name == a),
        },
        plan: j['canDeliver'] == null ? null : DeliveryPlan.fromJson(j['canDeliver'] as Map<String, dynamic>),
        price: j['price'] == null ? null : PriceCheck.fromJson(j['price'] as Map<String, dynamic>),
        messages: [for (final m in (j['messages'] as List).cast<Map<String, dynamic>>()) OrderMessage.fromJson(m)],
        invoices: [
          for (final i in (j['invoices'] as List).cast<Map<String, dynamic>>())
            OrderInvoice(id: i['id'] as String, number: i['number'] as String, kind: i['kind'] as String, total: _num(i['total'])),
        ],
      );
}

class DispatchPhoto {
  const DispatchPhoto({required this.bytes, required this.mediaType});
  final Uint8List bytes;
  final String mediaType;
}

abstract interface class OrderRepository {
  Future<OrderInbox> inbox(OrderTab tab);
  Future<OrderDetail> detail(String code);
  Future<OrderDetail> respond(String code, {required bool accept});
  Future<OrderDetail> dispatch(String code, {String? transporter, String? lrNumber, DispatchPhoto? photo});
  Future<OrderDetail> deliver(String code);
  Future<OrderDetail> message(String code, String text);
  Future<Uint8List> dispatchPhoto(String code);
}
