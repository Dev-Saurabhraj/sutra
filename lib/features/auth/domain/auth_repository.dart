import 'me.dart';

class OtpRequest {
  const OtpRequest({required this.phone, required this.devOtpEnabled});
  final String phone;
  final bool devOtpEnabled;
}

/// What the app needs from the auth backend. The UI depends on this, never on HTTP.
abstract interface class AuthRepository {
  Future<OtpRequest> requestOtp(String phone);

  /// Verifies the code and stores the session tokens.
  Future<void> verifyOtp(String phone, String code);

  /// null when there is no stored session.
  Future<Me?> loadMe();
  Future<void> acceptConsent(String version);
  Future<void> setLanguage(String code);
  Future<void> logout();
}
