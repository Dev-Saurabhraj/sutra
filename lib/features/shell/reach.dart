import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/common_text.dart';
import '../../design/tokens.dart';
import '../alerts/data/alert_repository.dart';
import '../alerts/domain/alert_models.dart';
import '../home/data/home_repository.dart';

// ---------------------------------------------------------------- settings kept on the phone

/// X5: read new alerts aloud while the app is open (on by default; a phone setting, not an account one).
class VoiceAlertsController extends Notifier<bool> {
  static const _key = 'sutra.voiceAlerts';
  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key) ?? true;
  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPrefsProvider).setBool(_key, on);
  }
}

final voiceAlertsProvider = NotifierProvider<VoiceAlertsController, bool>(VoiceAlertsController.new);

/// P26 helper ("munim") mode: a family member or helper uses the owner's phone for goods and voice entries;
/// money screens stay hidden until the owner's PIN is entered. A convenience lock on a shared phone,
/// not a security boundary (the PIN never leaves the phone).
class HelperModeController extends Notifier<bool> {
  static const _on = 'sutra.helper.on';
  static const _pin = 'sutra.helper.pin';

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_on) ?? false;

  static String _hash(String pin) => base64Url.encode(utf8.encode('sutra-munim:$pin'.split('').reversed.join()));

  Future<void> start(String pin) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_pin, _hash(pin));
    await prefs.setBool(_on, true);
    state = true;
  }

  /// True when the PIN is right (helper mode ends).
  Future<bool> unlock(String pin) async {
    final prefs = ref.read(sharedPrefsProvider);
    if (prefs.getString(_pin) != _hash(pin)) return false;
    await prefs.setBool(_on, false);
    state = false;
    return true;
  }
}

final helperModeProvider = NotifierProvider<HelperModeController, bool>(HelperModeController.new);

/// Screens a helper may not open.
const helperBlocked = ['/khata', '/labour', '/gst', '/prices', '/profile', '/catalog', '/invoice', '/bill', '/capacity'];
bool blockedForHelper(String at) => helperBlocked.any((p) => at == p || at.startsWith('$p/'));

// ---------------------------------------------------------------- the watcher

/// Runs while the maker's app is open: sends entries that waited on the phone (P27) and reads new alerts aloud (X5).
/// Real push (FCM) needs a Firebase project and server key; until then this covers the app being open.
class ReachWatcher extends ConsumerStatefulWidget {
  const ReachWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ReachWatcher> createState() => _ReachWatcherState();
}

class _ReachWatcherState extends ConsumerState<ReachWatcher> with WidgetsBindingObserver {
  static const _every = Duration(seconds: 45);
  static const _seenKey = 'sutra.seenAlerts';
  Timer? _timer;
  bool _first = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_every, (_) => _tick());
    Future.microtask(_tick);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    if (!mounted) return;
    await _flush(quiet: true);
    await _alerts();
  }

  Future<void> _flush({bool quiet = false}) async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final sent = await ref.read(apiClientProvider).flushOutbox();
    if (sent > 0) {
      ref.invalidate(homeProvider);
      messenger?.showSnackBar(SnackBar(content: Text('$sent ${s.tr(CommonText.sent)}')));
    } else if (!quiet && ref.read(outboxCountProvider) > 0) {
      messenger?.showSnackBar(SnackBar(content: Text(s.tr(CommonText.savedOffline))));
    }
  }

  Future<void> _alerts() async {
    final prefs = ref.read(sharedPrefsProvider);
    List<AlertItem> unread;
    try {
      unread = await ref.read(alertRepositoryProvider).unread();
    } catch (_) {
      return; // offline or signed out: try again next tick
    }
    final seen = (prefs.getStringList(_seenKey) ?? const []).toSet();
    final fresh = unread.where((a) => !seen.contains(a.id)).toList();
    await prefs.setStringList(_seenKey, [...seen, ...fresh.map((a) => a.id)].reversed.take(300).toList());
    // the first look after opening the app only learns what's there; the home screen already shows it
    final first = _first;
    _first = false;
    if (first || fresh.isEmpty || !mounted) return;
    final s = ref.read(stringsProvider);
    final a = fresh.first;
    final title = s.pick(a.titleHi, a.title);
    if (ref.read(voiceAlertsProvider)) ref.read(speakerProvider).say(title, hindi: s.isHindi);
    ref.invalidate(homeProvider);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(fresh.length > 1 ? '$title (+${fresh.length - 1})' : title),
      action: a.route == null ? null : SnackBarAction(label: s.tr(CommonText.open), onPressed: () => context.push(a.route!)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(outboxCountProvider);
    final s = ref.watch(stringsProvider);
    return Stack(
      children: [
        widget.child,
        if (waiting > 0)
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.paddingOf(context).top + 6,
            child: Material(
              color: SutraColors.haldiWash,
              elevation: 2,
              borderRadius: const BorderRadius.all(SutraRadius.md),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, color: SutraColors.haldiDeep, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$waiting ${s.tr(CommonText.waiting)}', style: const TextStyle(fontWeight: FontWeight.w700, color: SutraColors.haldiDeep))),
                    TextButton(onPressed: () => _flush(), child: Text(s.tr(CommonText.sendNow))),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
