import 'package:intl/intl.dart';

/// Money and quantity formatting in Indian style (RULES B6).
abstract final class Fmt {
  static final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _qty = NumberFormat.decimalPatternDigits(locale: 'en_IN', decimalDigits: 1);

  /// ₹1,23,456
  static String inr(num value) => _inr.format(value.round());

  /// 1,234.5 (trailing .0 dropped)
  static String qty(num value) {
    final s = _qty.format(value);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// "24 Nov" in the chosen language.
  static String shortDate(DateTime d, {required bool hindi}) =>
      DateFormat('d MMM', hindi ? 'hi' : 'en_IN').format(d.toLocal());

  /// "3 दिन पहले" / "3d ago"
  static String ago(DateTime d, {required bool hindi, DateTime? now}) {
    final mins = (now ?? DateTime.now()).difference(d).inMinutes;
    if (mins < 60) return hindi ? '${mins.clamp(1, 59)} मिनट पहले' : '${mins.clamp(1, 59)} min ago';
    final hrs = mins ~/ 60;
    if (hrs < 24) return hindi ? '$hrs घंटे पहले' : '${hrs}h ago';
    final days = hrs ~/ 24;
    return hindi ? '$days दिन पहले' : '${days}d ago';
  }

  /// Initials for an avatar: "Mohd. Salim" → "S", "Rohit Kushwaha" → "RK".
  static String initials(String name) {
    final parts = name.replaceFirst(RegExp(r'^(Mohd\.|Md\.)\s*'), '').split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
