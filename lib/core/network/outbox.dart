import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thrown when an entry could not reach the server and was kept on the phone to send later.
class SavedOffline implements Exception {
  const SavedOffline();
}

/// One entry waiting on the phone. The idempotency key goes with it, so sending twice still saves once.
class OutboxItem {
  const OutboxItem({required this.path, required this.body, required this.key, required this.at});
  final String path;
  final Object? body;
  final String key;
  final DateTime at;

  Map<String, dynamic> toJson() => {'path': path, 'body': body, 'key': key, 'at': at.toIso8601String()};

  factory OutboxItem.fromJson(Map<String, dynamic> j) =>
      OutboxItem(path: j['path'] as String, body: j['body'], key: j['key'] as String, at: DateTime.parse(j['at'] as String));
}

/// P27: entries made without a network wait here (on the phone, append-only) and go out in order once it's back.
class Outbox {
  Outbox(this._prefs, {this.onChanged});
  final SharedPreferences _prefs;
  final void Function(int count)? onChanged;
  static const _key = 'sutra.outbox';

  List<OutboxItem> get items {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return [for (final e in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) OutboxItem.fromJson(e)];
    } catch (_) {
      return const [];
    }
  }

  int get count => items.length;

  Future<void> add(OutboxItem item) => _save([...items, item]);

  Future<void> remove(String key) => _save(items.where((i) => i.key != key).toList());

  Future<void> _save(List<OutboxItem> list) async {
    await _prefs.setString(_key, jsonEncode([for (final i in list) i.toJson()]));
    onChanged?.call(list.length);
  }
}
