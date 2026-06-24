import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../data/models/prisoner_model.dart';
import '../../data/repositories/prisoner_repository.dart';
import 'auth_provider.dart';

final prisonerRepositoryProvider = Provider<PrisonerRepository>((ref) => PrisonerRepository());

/// All prisoners (unfiltered).
final allPrisonersProvider = FutureProvider<List<PrisonerModel>>((ref) async {
  final repo = ref.watch(prisonerRepositoryProvider);
  return repo.getAll();
});

/// Dashboard stats.
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(prisonerRepositoryProvider);
  return repo.getDashboardStats();
});

/// Search query state.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered prisoner list based on search.
final filteredPrisonersProvider = FutureProvider<List<PrisonerModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final repo  = ref.watch(prisonerRepositoryProvider);
  if (query.trim().isEmpty) return repo.getAll();
  return repo.search(query.trim());
});

/// Status filter for prisoner list.
final statusFilterProvider = StateProvider<PrisonerStatus?>((ref) => null);

/// Date filter for admitted screen.
final admittedDateFilterProvider = StateProvider<DateFilter>((ref) => DateFilter.thisMonth);

/// Admitted prisoners by date filter.
final admittedPrisonersProvider = FutureProvider<List<PrisonerModel>>((ref) async {
  final repo   = ref.watch(prisonerRepositoryProvider);
  final filter = ref.watch(admittedDateFilterProvider);
  return repo.getByDateFilter(filter);
});

/// Date filter for released screen.
final releasedDateFilterProvider = StateProvider<DateFilter>((ref) => DateFilter.thisMonth);

/// Released prisoners.
final releasedPrisonersProvider = FutureProvider<List<PrisonerModel>>((ref) async {
  final repo   = ref.watch(prisonerRepositoryProvider);
  final filter = ref.watch(releasedDateFilterProvider);
  final all    = await repo.getByStatus(PrisonerStatus.released);
  final bail   = await repo.getByStatus(PrisonerStatus.bail);
  return [...all, ...bail];
});

/// Notifier for CRUD operations.
class PrisonerNotifier extends AsyncNotifier<void> {
  late PrisonerRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(prisonerRepositoryProvider);
  }

  Future<String> addPrisoner(PrisonerModel prisoner) async {
    state = const AsyncLoading();
    final id = await _repo.insert(prisoner);
    _invalidate();
    return id;
  }

  Future<void> updatePrisoner(PrisonerModel prisoner) async {
    state = const AsyncLoading();
    await _repo.update(prisoner);
    _invalidate();
  }

  Future<void> deletePrisoner(String id) async {
    state = const AsyncLoading();
    await _repo.delete(id);
    _invalidate();
  }

  Future<Map<String, int>> bulkImport(List<PrisonerModel> prisoners, {
    bool updateExisting = false,
    bool skipDuplicates = true,
  }) async {
    final result = await _repo.bulkImport(
      prisoners,
      updateExisting: updateExisting,
      skipDuplicates: skipDuplicates,
    );
    _invalidate();
    return result;
  }

  void _invalidate() {
    ref.invalidate(allPrisonersProvider);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(filteredPrisonersProvider);
    ref.invalidate(admittedPrisonersProvider);
    ref.invalidate(releasedPrisonersProvider);
    state = const AsyncData(null);
  }
}

final prisonerNotifierProvider =
    AsyncNotifierProvider<PrisonerNotifier, void>(PrisonerNotifier.new);
