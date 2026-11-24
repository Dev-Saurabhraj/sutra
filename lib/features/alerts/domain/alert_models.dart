class AlertItem {
  const AlertItem({required this.id, required this.kind, required this.title, required this.titleHi, required this.body, required this.bodyHi, required this.route, required this.createdAt});

  final String id;
  final String kind;
  final String title;
  final String titleHi;
  final String body;
  final String bodyHi;
  final String? route;
  final DateTime createdAt;

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: j['id'] as String,
        kind: j['kind'] as String,
        title: j['title'] as String,
        titleHi: j['titleHi'] as String,
        body: j['body'] as String,
        bodyHi: j['bodyHi'] as String,
        route: j['route'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

abstract interface class AlertRepository {
  Future<void> markRead(String id);
}
