import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_exception.dart';

/// Thin HTTP client: adds the access token, refreshes it once on 401, and maps errors to [ApiException].
class ApiClient {
  ApiClient({required String baseUrl, required TokenStore tokens, required void Function() onSessionExpired})
      : _tokens = tokens,
        _onSessionExpired = onSessionExpired,
        _dio = Dio(BaseOptions(
          baseUrl: '$baseUrl/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          contentType: Headers.jsonContentType,
        )) {
    _dio.interceptors.add(QueuedInterceptorsWrapper(onRequest: _attachToken, onError: _refreshOn401));
  }

  final Dio _dio;
  final TokenStore _tokens;
  final void Function() _onSessionExpired;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, {Object? body, bool idempotent = false}) => _send(
        () => _dio.post<dynamic>(path,
            data: body, options: idempotent ? Options(headers: {'Idempotency-Key': newIdempotencyKey()}) : null),
      );

  Future<Map<String, dynamic>> put(String path, {Object? body}) => _send(() => _dio.put<dynamic>(path, data: body));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) => _send(() => _dio.patch<dynamic>(path, data: body));

  /// Downloads a file (PDF, CSV…) as raw bytes.
  Future<Uint8List> getBytes(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get<List<int>>(path, queryParameters: query, options: Options(responseType: ResponseType.bytes));
      return Uint8List.fromList(res.data ?? const []);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final res = await request();
      final data = res.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> _attachToken(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!options.path.startsWith('/auth/')) {
      final t = await _tokens.read();
      if (t != null) options.headers['Authorization'] = 'Bearer ${t.accessToken}';
    }
    handler.next(options);
  }

  /// Access tokens live 15 minutes. On 401, rotate the refresh token once and replay the request.
  Future<void> _refreshOn401(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    if (err.response?.statusCode != 401 || path.startsWith('/auth/') || err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }
    final stored = await _tokens.read();
    if (stored == null) return handler.next(err);
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl, contentType: Headers.jsonContentType));
      final res = await refreshDio.post<Map<String, dynamic>>('/auth/refresh', data: {'refreshToken': stored.refreshToken});
      final body = res.data!;
      await _tokens.write(StoredTokens(accessToken: body['accessToken'] as String, refreshToken: body['refreshToken'] as String));
      final retry = err.requestOptions
        ..headers['Authorization'] = 'Bearer ${body['accessToken']}'
        ..extra['retried'] = true;
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } catch (_) {
      await _tokens.clear();
      _onSessionExpired();
      handler.next(err);
    }
  }
}

final _rand = Random.secure();

/// A random key so a retried save is recorded only once on the server.
String newIdempotencyKey() =>
    List.generate(24, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[_rand.nextInt(36)]).join();
