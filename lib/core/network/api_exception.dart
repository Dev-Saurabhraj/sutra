import 'package:dio/dio.dart';

/// One error type for the UI. Carries the server's `{ error: { code, message, details } }`.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.messageHi, this.status});

  final String code;
  final String message;
  final String? messageHi;
  final int? status;

  bool get isOffline => code == 'OFFLINE';
  bool get isUnauthorized => status == 401;

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        final e = data['error'] as Map;
        final details = e['details'];
        return ApiException(
          code: '${e['code'] ?? 'ERROR'}',
          message: '${e['message'] ?? 'Something went wrong'}',
          messageHi: details is Map ? (details['hi'] ?? details['reasonHi']) as String? : null,
          status: error.response?.statusCode,
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const ApiException(
          code: 'OFFLINE',
          message: 'Cannot reach Sutra. Check the internet and try again.',
          messageHi: 'Sutra से जुड़ नहीं पा रहे। इंटरनेट देखें और फिर कोशिश करें।',
        );
      }
    }
    return ApiException(code: 'UNKNOWN', message: '$error');
  }

  @override
  String toString() => 'ApiException($code, $message)';
}
