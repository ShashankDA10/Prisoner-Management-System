import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_mode.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/remote_user_repository.dart';
import '../../data/repositories/user_repository.dart';

// ── Repository selector ──────────────────────────────────────────────────────

final _remoteUserRepoProvider = Provider<RemoteUserRepository>(
    (_) => RemoteUserRepository());

final userRepositoryProvider = Provider<UserRepository>(
    (_) => UserRepository());

// ── List provider ────────────────────────────────────────────────────────────

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  if (kUseRemoteBackend) {
    return ref.read(_remoteUserRepoProvider).getAll();
  }
  return ref.read(userRepositoryProvider).getAll();
});

// ── Notifier ─────────────────────────────────────────────────────────────────

class UserNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> addUser(UserModel user, {String plainPassword = ''}) async {
    state = const AsyncLoading();
    try {
      final String id;
      if (kUseRemoteBackend) {
        id = await ref.read(_remoteUserRepoProvider)
            .insert(user, plainPassword: plainPassword);
      } else {
        id = await ref.read(userRepositoryProvider).insert(user);
      }
      ref.invalidate(allUsersProvider);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user, {String plainPassword = ''}) async {
    state = const AsyncLoading();
    try {
      if (kUseRemoteBackend) {
        await ref.read(_remoteUserRepoProvider)
            .update(user, plainPassword: plainPassword);
      } else {
        await ref.read(userRepositoryProvider).update(user);
      }
      ref.invalidate(allUsersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    state = const AsyncLoading();
    try {
      if (kUseRemoteBackend) {
        await ref.read(_remoteUserRepoProvider).delete(id);
      } else {
        await ref.read(userRepositoryProvider).delete(id);
      }
      ref.invalidate(allUsersProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final userNotifierProvider =
    AsyncNotifierProvider<UserNotifier, void>(UserNotifier.new);
