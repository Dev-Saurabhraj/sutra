import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/device/link_launcher.dart';
import '../core/device/speaker.dart';
import '../core/device/voice_input.dart';
import '../core/l10n/app_strings.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../features/auth/presentation/session_controller.dart';

// Composition root for the app: every concrete dependency is chosen here and can be overridden in tests.

final sharedPrefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('overridden in main()'));

final tokenStoreProvider = Provider<TokenStore>((_) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokens: ref.watch(tokenStoreProvider),
    onSessionExpired: () => ref.read(sessionControllerProvider.notifier).expired(),
  );
});

final voiceInputProvider = Provider<VoiceInput>((_) => DeviceVoiceInput());
final speakerProvider = Provider<Speaker>((_) => DeviceSpeaker());
final linkLauncherProvider = Provider<LinkLauncher>((_) => DeviceLinkLauncher());

/// UI language, remembered on the device. Hindi by default (RULES B1).
class LangController extends Notifier<AppLang> {
  static const _key = 'sutra.lang';

  @override
  AppLang build() => AppLang.fromCode(ref.watch(sharedPrefsProvider).getString(_key));

  Future<void> set(AppLang lang) async {
    state = lang;
    await ref.read(sharedPrefsProvider).setString(_key, lang.code);
  }
}

final langProvider = NotifierProvider<LangController, AppLang>(LangController.new);

final stringsProvider = Provider<AppStrings>((ref) => AppStrings.of(ref.watch(langProvider)));
