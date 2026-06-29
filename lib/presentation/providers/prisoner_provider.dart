import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_mode.dart';
import '../../core/constants/enums.dart';
import '../../data/models/prisoner_model.dart';
import '../../data/repositories/prisoner_repository.dart';
import '../../data/repositories/remote_prisoner_repository.dart';

final prisonerRepositoryProvider = Provider<PrisonerRepositoryBase>((ref) =>
    kUseRemoteBackend ? RemotePrisonerRepository() : PrisonerRepository());

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

/// Status filter for prisoner list.
final statusFilterProvider = StateProvider<PrisonerStatus?>((ref) => null);

/// Police station filter (set from Reports screen drill-down).
final stationFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered prisoner list based on search + status + station filters.
final filteredPrisonersProvider = FutureProvider<List<PrisonerModel>>((ref) async {
  final query   = ref.watch(searchQueryProvider);
  final status  = ref.watch(statusFilterProvider);
  final station = ref.watch(stationFilterProvider);
  final repo    = ref.watch(prisonerRepositoryProvider);

  List<PrisonerModel> list = query.trim().isEmpty
      ? await repo.getAll()
      : await repo.search(query.trim());

  if (status  != null) list = list.where((p) => p.status == status).toList();
  if (station != null) list = list.where((p) => p.policeStation == station).toList();
  return list;
});

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
  final repo = ref.watch(prisonerRepositoryProvider);
  ref.watch(releasedDateFilterProvider); // watched so screen rebuilds on filter change
  final all  = await repo.getByStatus(PrisonerStatus.released);
  final bail = await repo.getByStatus(PrisonerStatus.bail);
  return [...all, ...bail];
});

/// Notifier for CRUD operations.
class PrisonerNotifier extends AsyncNotifier<void> {
  late PrisonerRepositoryBase _repo;

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
