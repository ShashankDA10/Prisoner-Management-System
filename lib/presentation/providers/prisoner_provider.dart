import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_mode.dart';
import '../../core/constants/enums.dart';
import '../../data/models/prisoner_model.dart';
import '../../data/repositories/prisoner_repository.dart';
import '../../data/repositories/remote_prisoner_repository.dart';
import 'auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final prisonerRepositoryProvider = Provider<PrisonerRepositoryBase>((ref) =>
    kUseRemoteBackend ? RemotePrisonerRepository() : PrisonerRepository());

// ── Station scope ─────────────────────────────────────────────────────────────

/// Derives the station filter that must be applied to every data query.
///
/// Returns null when the logged-in user can see all stations (admin / higher
/// roles). Returns the user's assigned [policeStation] for station-locked roles
/// (Inspector, SI, Prison Officer).
final stationScopeProvider = Provider<String?>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return null;
  if (user.role.canSeeAllStations) return null;
  return user.policeStation; // may be null if user is mis-configured
});

// ── All prisoners (scoped) ────────────────────────────────────────────────────

/// All prisoners visible to the current user (station-scoped automatically).
final allPrisonersProvider = FutureProvider<List<PrisonerModel>>((ref) async {
  final repo    = ref.watch(prisonerRepositoryProvider);
  final station = ref.watch(stationScopeProvider);
  return repo.getAll(station: station);
});

// ── Dashboard stats (scoped) ──────────────────────────────────────────────────

/// Dashboard statistics scoped to the current user's station.
/// Admins see statewide totals; station users see only their station.
final dashboardStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repo    = ref.watch(prisonerRepositoryProvider);
  final station = ref.watch(stationScopeProvider);
  return repo.getDashboardStats(station: station);
});

// ── UI filter state ───────────────────────────────────────────────────────────

/// Search query typed into the prisoner list search bar.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Optional status filter chip selection (null = show all statuses).
final statusFilterProvider = StateProvider<PrisonerStatus?>((ref) => null);

/// Optional police-station drill-down filter set from the Reports screen.
/// Only meaningful for admin users; station-locked users' data is already
/// scoped at the provider level.
final stationFilterProvider = StateProvider<String?>((ref) => null);

// ── Filtered prisoner list ────────────────────────────────────────────────────

/// Prisoner list filtered by search query, status chip, and optional station
/// drill-down (Reports → Prisoners). Station scope is applied automatically
/// via the repository layer.
final filteredPrisonersProvider =
    FutureProvider<List<PrisonerModel>>((ref) async {
  final query   = ref.watch(searchQueryProvider);
  final status  = ref.watch(statusFilterProvider);
  final station = ref.watch(stationScopeProvider);
  final repo    = ref.watch(prisonerRepositoryProvider);

  List<PrisonerModel> list = query.trim().isEmpty
      ? await repo.getAll(station: station)
      : await repo.search(query.trim(), station: station);

  if (status != null) {
    list = list.where((p) => p.status == status).toList();
  }
  return list;
});

// ── Admitted screen ───────────────────────────────────────────────────────────

/// Date filter for the Admitted screen.
final admittedDateFilterProvider =
    StateProvider<DateFilter>((ref) => DateFilter.thisMonth);

/// Admitted prisoners scoped to the current user's station.
final admittedPrisonersProvider =
    FutureProvider<List<PrisonerModel>>((ref) async {
  final repo    = ref.watch(prisonerRepositoryProvider);
  final filter  = ref.watch(admittedDateFilterProvider);
  final station = ref.watch(stationScopeProvider);
  return repo.getByDateFilter(filter, station: station);
});

// ── Released screen ───────────────────────────────────────────────────────────

/// Date filter for the Released screen.
final releasedDateFilterProvider =
    StateProvider<DateFilter>((ref) => DateFilter.thisMonth);

/// Released + bail prisoners scoped to the current user's station.
final releasedPrisonersProvider =
    FutureProvider<List<PrisonerModel>>((ref) async {
  final repo    = ref.watch(prisonerRepositoryProvider);
  final station = ref.watch(stationScopeProvider);
  ref.watch(releasedDateFilterProvider); // rebuild when filter changes
  final all  = await repo.getByStatus(PrisonerStatus.released, station: station);
  final bail = await repo.getByStatus(PrisonerStatus.bail, station: station);
  return [...all, ...bail];
});

// ── Cross-station (Other Station Cases) ───────────────────────────────────────

/// Search query for the Other Station Cases screen.
final crossStationSearchQueryProvider = StateProvider<String>((ref) => '');

/// Prisoners from stations OTHER than the current user's station.
/// For admin/higher roles who have no station restriction this returns all
/// prisoners (station exclusion is skipped).
final crossStationPrisonersProvider =
    FutureProvider<List<PrisonerModel>>((ref) async {
  final query          = ref.watch(crossStationSearchQueryProvider);
  final repo           = ref.watch(prisonerRepositoryProvider);
  final user           = ref.watch(authProvider).value;
  final excludeStation = (user != null && !user.role.canSeeAllStations)
      ? user.policeStation
      : null;
  return repo.searchCrossStation(query.trim(), excludeStation: excludeStation);
});

// ── CRUD notifier ─────────────────────────────────────────────────────────────

/// Notifier for create / update / delete / bulk-import operations.
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

  Future<Map<String, int>> bulkImport(
    List<PrisonerModel> prisoners, {
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
    ref.invalidate(crossStationPrisonersProvider);
    state = const AsyncData(null);
  }
}

final prisonerNotifierProvider =
    AsyncNotifierProvider<PrisonerNotifier, void>(PrisonerNotifier.new);
