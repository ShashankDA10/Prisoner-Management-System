import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/enums.dart';
import '../datasources/api_client.dart';
import '../models/prisoner_model.dart';
import 'prisoner_repository.dart';

/// Remote (REST API) implementation of PrisonerRepositoryBase.
///
/// Mirrors the SQLite implementation exactly — the Riverpod providers
/// never need to know which implementation is active.
///
/// MIGRATION: This class is the only thing that changes when you swap
/// the backend database/provider.
class RemotePrisonerRepository implements PrisonerRepositoryBase {
  final _api = ApiClient.instance;

  @override
  Future<List<PrisonerModel>> getAll() async {
    final res = await _api.get(ApiConfig.prisoners);
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

  @override
  Future<List<PrisonerModel>> search(String query) async {
    final res = await _api.get(ApiConfig.prisoners, params: {'q': query});
    return _parseList(res.data['data']);
  }

  @override
  Future<List<PrisonerModel>> getByStatus(PrisonerStatus status) async {
    final res = await _api.get(ApiConfig.prisoners, params: {'status': status.name});
    return _parseList(res.data['data']);
  }

  @override
  Future<List<PrisonerModel>> getByDateFilter(
    DateFilter filter, {
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, dynamic>{'filter': filter.name};
    if (from != null) params['from'] = from.toIso8601String();
    if (to   != null) params['to']   = to.toIso8601String();
    final res = await _api.get(ApiConfig.prisonerByDate, params: params);
    return _parseList(res.data['data']);
  }

  @override
  Future<Map<String, int>> getDashboardStats() async {
    final res = await _api.get(ApiConfig.prisonerStats);
    return Map<String, int>.from(res.data as Map);
  }

  /// Bulk import pre-parsed models as JSON — called from ExcelImportDialog.
  @override
  Future<Map<String, int>> bulkImport(
    List<PrisonerModel> prisoners, {
    bool updateExisting = false,
    bool skipDuplicates = true,
  }) async {
    final res = await _api.post(
      '${ApiConfig.prisoners}/bulk',
      data: {
        'prisoners':     prisoners.map((p) => p.toApiJson()).toList(),
        'updateExisting': updateExisting,
        'skipDuplicates': skipDuplicates,
      },
    );
    return {
      'inserted': res.data['inserted'] as int? ?? 0,
      'updated':  res.data['updated']  as int? ?? 0,
      'skipped':  res.data['skipped']  as int? ?? 0,
    };
  }

  /// Bulk import via raw Excel file bytes (alternative path).
  Future<Map<String, int>> bulkImportExcel(
    List<int> fileBytes,
    String fileName, {
    bool updateExisting = false,
    bool skipDuplicates = true,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'updateExisting': updateExisting.toString(),
      'skipDuplicates': skipDuplicates.toString(),
    });
    final res = await _api.postForm(ApiConfig.prisonerImport, form);
    return {
      'inserted': res.data['inserted'] as int? ?? 0,
      'updated':  res.data['updated']  as int? ?? 0,
      'skipped':  res.data['skipped']  as int? ?? 0,
    };
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  List<PrisonerModel> _parseList(dynamic data) {
    if (data == null) return [];
    return (data as List)
        .map((e) => PrisonerModel.fromApiJson(e as Map<String, dynamic>))
        .toList();
  }
}
