import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/enums.dart';
import '../datasources/api_client.dart';
import '../models/user_model.dart';

/// Calls the backend auth endpoints and stores the JWT.
/// Drop-in replacement for the local SharedPreferences auth.
class RemoteAuthRepository {
  final _api = ApiClient.instance;

  /// Returns the logged-in [UserModel] or null on bad credentials.
  Future<UserModel?> login(String username, String password) async {
    try {
      final res = await _api.post(ApiConfig.login, data: {
        'username': username,
        'password': password,
      });
      final token = res.data['token'] as String;
      await _api.saveToken(token);
      return _mapUser(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout);
    } catch (_) {
      // Best-effort — always clear local token
    } finally {
      await _api.clearToken();
    }
  }

  /// Restore session from stored JWT (called on app start).
  Future<UserModel?> tryRestoreSession() async {
    final token = await _api.readToken();
    if (token == null) return null;
    try {
      final res = await _api.get(ApiConfig.me);
      return _mapUser(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _api.clearToken();
      return null;
    }
  }

  UserModel _mapUser(Map<String, dynamic> j) => UserModel(
    id:           j['sub']      as String? ?? j['id'] as String,
    username:     j['username'] as String,
    name:         j['name']     as String,
    passwordHash: '',   // hash stays server-side; client never receives it
    role:         UserRole.values.firstWhere(
        (r) => r.name == (j['role'] as String),
        orElse: () => UserRole.si),
    policeStation: j['policeStation'] as String? ?? '',
    isActive:     true,
    createdAt:    DateTime.now(),
    updatedAt:    DateTime.now(),
  );
}
