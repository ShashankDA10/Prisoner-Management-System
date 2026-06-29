import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/api_config.dart';

/// Singleton Dio client.
///
/// Automatically attaches the JWT token to every request and handles
/// 401 → clears the stored token.
///
/// MIGRATION: To switch from JWT to OAuth/session cookies, change only
/// this file. Everything above (repositories, providers, UI) stays the same.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'pums_jwt_token';
  final _storage = const FlutterSecureStorage();

  late final Dio _dio = Dio(BaseOptions(
    baseUrl:        ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (opts, handler) async {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) opts.headers['Authorization'] = 'Bearer $token';
      handler.next(opts);
    },
    onError: (err, handler) async {
      if (err.response?.statusCode == 401) await clearToken();
      handler.next(err);
    },
  ));

  Dio get dio => _dio;

  // ── Token helpers ────────────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // ── Convenience wrappers ─────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postForm(String path, FormData form) =>
      _dio.post(path, data: form);
}
