import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/audit_log_repository.dart';

/// The currently logged-in user (null = not logged in).
class AuthNotifier extends StreamNotifier<UserModel?> {
  final _controller = StreamController<UserModel?>.broadcast();
  final _userRepo   = UserRepository();
  final _auditRepo  = AuditLogRepository();

  UserModel? _current;
  UserModel? get current => _current;

  @override
  Stream<UserModel?> build() => _controller.stream;

  Future<bool> login(String username, String password) async {
    final user = await _userRepo.authenticate(username, password);
    if (user == null) return false;

    _current = user;
    _controller.add(user);

    // Persist session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCurrentUser, user.id);

    // Audit
    await _auditRepo.log(
      userId: user.id, userName: user.name,
      action: AuditAction.login,
      description: 'User logged in',
    );
    return true;
  }

  Future<void> logout() async {
    if (_current != null) {
      await _auditRepo.log(
        userId: _current!.id, userName: _current!.name,
        action: AuditAction.logout,
        description: 'User logged out',
      );
    }
    _current = null;
    _controller.add(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefCurrentUser);
  }

  /// Restore session on app restart.
  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.prefCurrentUser);
    if (id == null) return;
    final user = await _userRepo.getById(id);
    if (user != null && user.isActive) {
      _current = user;
      _controller.add(user);
    }
  }

  Stream<UserModel?> get stream => _controller.stream;
}

final authProvider = StreamNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
