import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_mode.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/remote_auth_repository.dart';

/// The currently logged-in user (null = not logged in).
class AuthNotifier extends StreamNotifier<UserModel?> {
  final _controller  = StreamController<UserModel?>.broadcast();
  final _userRepo    = UserRepository();
  final _auditRepo   = AuditLogRepository();
  final _remoteAuth  = RemoteAuthRepository();

  UserModel? _current;
  UserModel? get current => _current;

  @override
  Stream<UserModel?> build() {
    Future.microtask(tryRestoreSession);
    return _controller.stream;
  }

  Future<bool> login(String username, String password) async {
    UserModel? user;

    if (kUseRemoteBackend) {
      user = await _remoteAuth.login(username, password);
    } else {
      user = await _userRepo.authenticate(username, password);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.prefCurrentUser, user.id);
        await _auditRepo.log(
          userId: user.id, userName: user.name,
          action: AuditAction.login, description: 'User logged in',
        );
      }
    }

    if (user == null) return false;
    _current = user;
    _controller.add(user);
    return true;
  }

  Future<void> logout() async {
    if (kUseRemoteBackend) {
      await _remoteAuth.logout();
    } else {
      if (_current != null) {
        await _auditRepo.log(
          userId: _current!.id, userName: _current!.name,
          action: AuditAction.logout, description: 'User logged out',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefCurrentUser);
    }
    _current = null;
    _controller.add(null);
  }

  /// Restore session on app restart.
  Future<void> tryRestoreSession() async {
    UserModel? user;

    if (kUseRemoteBackend) {
      user = await _remoteAuth.tryRestoreSession();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(AppConstants.prefCurrentUser);
      if (id != null) {
        final found = await _userRepo.getById(id);
        if (found != null && found.isActive) user = found;
      }
    }

    if (user != null) {
      _current = user;
      _controller.add(user);
    }
  }

  Stream<UserModel?> get stream => _controller.stream;
}

final authProvider = StreamNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
