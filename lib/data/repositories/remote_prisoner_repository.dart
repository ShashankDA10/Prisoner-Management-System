import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/enums.dart';
import '../datasources/api_client.dart';
import '../models/prisoner_model.dart';
import 'prisoner_repository.dart';

/// Remote (REST API) implementation of [PrisonerRepositoryBase].
///
/// Every list-returning method passes the user's [station] as a query param
/// so the server enforces station-scoped filtering server-side.
/// Passing null means "no station restriction" (admin path).
class RemotePrisonerRepository implements PrisonerRepositoryBase {
  final _api = ApiClient.instance;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _stationParam(String? station) =>
      station != null ? {'station': station} : null;

  Map<String, dynamic> _merge(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) => {...?a, ...?b};

  // ── CRUD ────────────────────────────────────────────────────────────────────

  @override
  Future<List<PrisonerModel>> getAll({String? station}) async {
    final res = await _api.get(
      ApiConfig.prisoners,
      params: _stationParam(station),
    );
    return _parseList(res.data['data']);
  }

  @override
  Future<PrisonerModel?> getById(String id) async {
    try {
      final res = await _api.get(ApiConfig.prisonerById(id));
      return PrisonerModel.fromApiJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<String> insert(PrisonerModel prisoner) async {
    final res = await _api.post(
      ApiConfig.prisoners,
      data: prisoner.toApiJson(),
    );
    return res.data['id'] as String;
  }

  @override
  Future<void> update(PrisonerModel prisoner) async {
    await _api.put(
      ApiConfig.prisonerById(prisoner.id),
      data: prisoner.toApiJson(),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _api.delete(ApiConfig.prisonerById(id));
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  @override
  Future<List<PrisonerModel>> search(
    String query, {
    String? station,
  }) async {
    final res = await _api.get(
      ApiConfig.prisoners,
      params: _merge({'q': query}, _stationParam(station)),
    );
    return _parseList(res.data['data']);
  }

  @override
  Future<List<PrisonerModel>> getByStatus(
    PrisonerStatus status, {
    String? station,
  }) async {
    final res = await _api.get(
      ApiConfig.prisoners,
      params: _merge({'status': status.name}, _stationParam(station)),
    );
    return _parseList(res.data['data']);
  }

  @override
  Future<List<PrisonerModel>> getByDateFilter(
    DateFilter filter, {
    DateTime? from,
    DateTime? to,
    String? station,
  }) async {
    final params = <String, dynamic>{'filter': filter.name};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    if (station != null) params['station'] = station;
    final res = await _api.get(ApiConfig.prisonerByDate, params: params);
    return _parseList(res.data['data']);
  }

  @override
  Future<Map<String, int>> getDashboardStats({String? station}) async {
    final res = await _api.get(
      ApiConfig.prisonerStats,
      params: _stationParam(station),
    );
    return Map<String, int>.from(res.data as Map);
  }

  @override
  Future<Map<String, int>> bulkImport(
    List<PrisonerModel> prisoners, {
    bool updateExisting = false,
    bool skipDuplicates = true,
  }) async {
    final res = await _api.post(
      '${ApiConfig.prisoners}/bulk',
      data: {
        'prisoners': prisoners.map((p) => p.toApiJson()).toList(),
        'updateExisting': updateExisting,
        'skipDuplicates': skipDuplicates,
      },
    );
    return {
      'inserted': res.data['inserted'] as int? ?? 0,
      'updated': res.data['updated'] as int? ?? 0,
      'skipped': res.data['skipped'] as int? ?? 0,
    };
  }

  /// Cross-station read-only search.
  /// The backend [ApiConfig.prisonersCrossStation] endpoint returns all
  /// records visible to the authenticated user regardless of their station,
  /// optionally excluding [excludeStation].
  @override
  Future<List<PrisonerModel>> searchCrossStation(
    String query, {
    String? excludeStation,
  }) async {
    final params = <String, dynamic>{};
    if (query.isNotEmpty) params['q'] = query;
    if (excludeStation != null) params['excludeStation'] = excludeStation;
    final res = await _api.get(
      ApiConfig.prisonersCrossStation,
      params: params.isEmpty ? null : params,
    );
    return _parseList(res.data['data']);
  }

  // ── Helper ───────────────────────────────────────────────────────────────────

  List<PrisonerModel> _parseList(dynamic data) {
    if (data == null) return [];
    return (data as List)
        .map((e) => PrisonerModel.fromApiJson(e as Map<String, dynamic>))
        .toList();
  }
}
