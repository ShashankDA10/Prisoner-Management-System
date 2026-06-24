import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(userRepositoryProvider).getAll();
});

class UserNotifier extends AsyncNotifier<void> {
  late UserRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(userRepositoryProvider);
  }

  Future<String> addUser(UserModel user) async {
    state = const AsyncLoading();
    final id = await _repo.insert(user);
    ref.invalidate(allUsersProvider);
    state = const AsyncData(null);
    return id;
  }

  Future<void> updateUser(UserModel user) async {
    state = const AsyncLoading();
    await _repo.update(user);
    ref.invalidate(allUsersProvider);
    state = const AsyncData(null);
  }

  Future<void> deleteUser(String id) async {
    state = const AsyncLoading();
    await _repo.delete(id);
    ref.invalidate(allUsersProvider);
    state = const AsyncData(null);
  }
}

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, void>(UserNotifier.new);
