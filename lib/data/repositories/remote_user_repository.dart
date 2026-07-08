import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../datasources/api_client.dart';
import '../models/user_model.dart';

/// Remote (REST API) implementation of user CRUD.
/// All endpoints require admin role — the backend enforces this via JWT.
class RemoteUserRepository {
  final _api = ApiClient.instance;

  Future<List<UserModel>> getAll() async {
    final res = await _api.get(ApiConfig.users);
    final list = res.data['data'] as List;
    return list.map((e) => UserModel.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel?> getById(String id) async {
    try {
      final res = await _api.get(ApiConfig.userById(id));
      return UserModel.fromMap(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Creates a user. [plainPassword] is sent as-is; the backend does bcrypt hashing.
  Future<String> insert(UserModel user, {String plainPassword = ''}) async {
    final res = await _api.post(ApiConfig.users, data: {
      'username':      user.username,
      'password':      plainPassword,
      'name':          user.name,
      'role':          user.role.name,
      'policeStation': user.policeStation ?? '',
      'email':         user.email,
      'phone':         user.phone,
    });
    return res.data['id'] as String;
  }

  /// Updates a user. If [plainPassword] is non-empty, the password is changed too.
  Future<void> update(UserModel user, {String plainPassword = ''}) async {
    await _api.put(ApiConfig.userById(user.id), data: {
      'name':          user.name,
      'role':          user.role.name,
      'policeStation': user.policeStation ?? '',
      'email':         user.email,
      'phone':         user.phone,
      'isActive':      user.isActive,
      if (plainPassword.isNotEmpty) 'password': plainPassword,
    });
  }

  Future<void> delete(String id) async {
    await _api.delete(ApiConfig.userById(id));
  }

  Future<UserModel?> authenticate(String username, String password) async =>
      throw UnimplementedError('Use RemoteAuthRepository for authentication');
}
