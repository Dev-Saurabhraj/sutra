import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/me.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<OtpRequest> requestOtp(String phone) async {
    final j = await _api.post('/auth/otp/request', body: {'phone': phone});
    return OtpRequest(phone: j['phone'] as String, devOtpEnabled: (j['devOtpEnabled'] as bool?) ?? false);
  }

  @override
  Future<void> verifyOtp(String phone, String code) async {
    final j = await _api.post('/auth/otp/verify', body: {'phone': phone, 'code': code});
    await _tokens.write(StoredTokens(accessToken: j['accessToken'] as String, refreshToken: j['refreshToken'] as String));
  }

  @override
  Future<Me?> loadMe() async {
    if (await _tokens.read() == null) return null;
    return Me.fromJson(await _api.get('/me'));
  }

  @override
  Future<void> acceptConsent(String version) => _api.post('/me/consent', body: {'version': version});

  @override
  Future<void> setLanguage(String code) => _api.put('/me/language', body: {'language': code});

  @override
  Future<void> logout() async {
    final t = await _tokens.read();
    if (t != null) {
      try {
        await _api.post('/auth/logout', body: {'refreshToken': t.refreshToken});
      } catch (_) {
        // Logging out locally must work even offline.
      }
    }
    await _tokens.clear();
  }
}
