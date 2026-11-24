import 'package:flutter/foundation.dart';

/// Build-time configuration. Override with `--dart-define=API_BASE_URL=...`.
abstract final class AppConfig {
  static const _apiOverride = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) return _apiOverride;
    // The Android emulator reaches the host machine through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://192.168.1.21:4000';
    return 'http://localhost:4000';
  }
}
