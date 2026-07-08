import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../database/database_service.dart';
import '../models/prisoner_model.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

/// All repository methods that return lists accept an optional [station] param.
/// When [station] is non-null only records for that police station are returned.
/// Pass null (admin path) to get records across all stations.
abstract class PrisonerRepositoryBase {
  Future<List<PrisonerModel>> getAll({String? station});
  Future<PrisonerModel?> getById(String id);
  Future<String> insert(PrisonerModel prisoner);
  Future<void> update(PrisonerModel prisoner);
  Future<void> delete(String id);
  Future<List<PrisonerModel>> search(String query, {String? station});
  Future<List<PrisonerModel>> getByStatus(PrisonerStatus status, {String? station});
  Future<List<PrisonerModel>> getByDateFilter(
    DateFilter filter, {
    DateTime? from,
    DateTime? to,
    String? station,
  });
  Future<Map<String, int>> getDashboardStats({String? station});
  Future<Map<String, int>> bulkImport(
    List<PrisonerModel> prisoners, {
    bool updateExisting,
    bool skipDuplicates,
  });

  /// Cross-station search: returns prisoners matching [query] whose station
  /// differs from [excludeStation]. When [excludeStation] is null all records
  /// are returned (admin path). When [query] is empty returns all matching
  /// the station exclusion.
  Future<List<PrisonerModel>> searchCrossStation(
    String query, {
    String? excludeStation,
  });
}

// ── SQLite implementation ─────────────────────────────────────────────────────

class PrisonerRepository implements PrisonerRepositoryBase {
  final _uuid = const Uuid();
  Database get _db => DatabaseService.instance.db;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Builds a WHERE clause fragment for station scoping.
  /// Returns null components when [station] is null (no filtering).
  ({String? clause, List<dynamic>? args}) _stationClause(String? station) {
    if (station == null) return (clause: null, args: null);
    return (clause: 'police_station = ?', args: [station]);
  }

  /// Combines an optional station clause with additional where conditions.
  ({String? where, List<dynamic>? args}) _combineWhere(
    String? station,
    String? extra,
    List<dynamic>? extraArgs,
  ) {
    final sc = _stationClause(station);
    if (sc.clause == null && extra == null) return (where: null, args: null);
    if (sc.clause == null) return (where: extra, args: extraArgs);
    if (extra == null) return (where: sc.clause, args: sc.args);
    return (
      where: '${sc.clause} AND ($extra)',
      args: [...sc.args!, ...?extraArgs],
    );
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  @override
  Future<List<PrisonerModel>> getAll({String? station}) async {
    final w = _combineWhere(station, null, null);
    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: w.where,
      whereArgs: w.args,
      orderBy: 'created_at DESC',
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }

  @override
  Future<PrisonerModel?> getById(String id) async {
    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : PrisonerModel.fromMap(maps.first);
  }

  @override
  Future<String> insert(PrisonerModel prisoner) async {
    final id = prisoner.id.isEmpty ? _uuid.v4() : prisoner.id;
    final now = DateTime.now();
    final model = prisoner.copyWith(id: id, createdAt: now, updatedAt: now);
    await _db.insert(
      AppConstants.tablePrisoners,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  @override
  Future<void> update(PrisonerModel prisoner) async {
    await _db.update(
      AppConstants.tablePrisoners,
      prisoner.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [prisoner.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      AppConstants.tablePrisoners,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  @override
  Future<List<PrisonerModel>> search(String query, {String? station}) async {
    final q = '%$query%';
    const searchExpr =
        'name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ? OR '
        'crime_number LIKE ? OR police_station LIKE ? OR '
        'ipc_sections LIKE ? OR bns_sections LIKE ?';
    final searchArgs = [q, q, q, q, q, q, q];
    final w = _combineWhere(station, searchExpr, searchArgs);
    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: w.where,
      whereArgs: w.args,
      orderBy: 'name ASC',
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }

  @override
  Future<List<PrisonerModel>> getByStatus(
    PrisonerStatus status, {
    String? station,
  }) async {
    final w = _combineWhere(station, 'status = ?', [status.name]);
    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: w.where,
      whereArgs: w.args,
      orderBy: 'name ASC',
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }

  @override
  Future<List<PrisonerModel>> getByDateFilter(
    DateFilter filter, {
    DateTime? from,
    DateTime? to,
    String? station,
  }) async {
    String? dateExpr;
    List<dynamic>? dateArgs;

    final now = DateTime.now();
    switch (filter) {
      case DateFilter.today:
        final today =
            DateTime(now.year, now.month, now.day).toIso8601String();
        dateExpr = "DATE(admission_date) = DATE('$today')";
        break;
      case DateFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        dateExpr = 'admission_date >= ?';
        dateArgs = [
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)
              .toIso8601String(),
        ];
        break;
      case DateFilter.thisMonth:
        dateExpr =
            "strftime('%Y-%m', admission_date) = '${now.year}-${now.month.toString().padLeft(2, '0')}'";
        break;
      case DateFilter.custom:
        if (from != null && to != null) {
          dateExpr = 'admission_date >= ? AND admission_date <= ?';
          dateArgs = [from.toIso8601String(), to.toIso8601String()];
        }
        break;
    }

    final w = _combineWhere(station, dateExpr, dateArgs);
    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: w.where,
      whereArgs: w.args,
      orderBy: 'admission_date DESC',
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }

  @override
  Future<Map<String, int>> getDashboardStats({String? station}) async {
    final sc = _stationClause(station);

    Future<int> count(String? extra, [List<dynamic>? extraArgs]) async {
      String where;
      List<dynamic>? wArgs;
      if (sc.clause != null && extra != null) {
        where = ' WHERE ${sc.clause} AND ($extra)';
        wArgs = [...sc.args!, ...?extraArgs];
      } else if (sc.clause != null) {
        where = ' WHERE ${sc.clause}';
        wArgs = sc.args;
      } else if (extra != null) {
        where = ' WHERE $extra';
        wArgs = extraArgs;
      } else {
        where = '';
        wArgs = null;
      }
      return Sqflite.firstIntValue(await _db.rawQuery(
            'SELECT COUNT(*) FROM ${AppConstants.tablePrisoners}$where',
            wArgs,
          )) ??
          0;
    }

    final total = await count(null);
    final undertrial = await count("status = 'undertrial'");
    final convicted = await count("status = 'convicted'");
    final admitted = await count("DATE(admission_date) = DATE('now')");
    final released = await count("status = 'released'");
    final bail = await count("status = 'bail'");
    final transferred = await count("status = 'transferred'");

    return {
      'total': total,
      'undertrial': undertrial,
      'convicted': convicted,
      'admitted': admitted,
      'released': released,
      'bail': bail,
      'transferred': transferred,
    };
  }

  @override
  Future<Map<String, int>> bulkImport(
    List<PrisonerModel> prisoners, {
    bool updateExisting = false,
    bool skipDuplicates = true,
  }) async {
    int inserted = 0, updated = 0, skipped = 0;
    final batch = _db.batch();

    for (final p in prisoners) {
      final existing = await _db.query(
        AppConstants.tablePrisoners,
        where: 'prisoner_id = ?',
        whereArgs: [p.prisonerId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        if (updateExisting) {
          batch.update(
            AppConstants.tablePrisoners,
            p.copyWith(updatedAt: DateTime.now()).toMap(),
            where: 'prisoner_id = ?',
            whereArgs: [p.prisonerId],
          );
          updated++;
        } else if (skipDuplicates) {
          skipped++;
        }
      } else {
        final id = _uuid.v4();
        final now = DateTime.now();
        batch.insert(
          AppConstants.tablePrisoners,
          p.copyWith(id: id, createdAt: now, updatedAt: now).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        inserted++;
      }
    }

    await batch.commit(noResult: true);
    return {'inserted': inserted, 'updated': updated, 'skipped': skipped};
  }

  @override
  Future<List<PrisonerModel>> searchCrossStation(
    String query, {
    String? excludeStation,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (query.isNotEmpty && excludeStation != null) {
      final q = '%$query%';
      where = 'police_station != ? AND '
          '(name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ? OR '
          'crime_number LIKE ? OR police_station LIKE ?)';
      whereArgs = [excludeStation, q, q, q, q, q];
    } else if (query.isNotEmpty) {
      final q = '%$query%';
      where = 'name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ? OR '
          'crime_number LIKE ? OR police_station LIKE ?';
      whereArgs = [q, q, q, q, q];
    } else if (excludeStation != null) {
      where = 'police_station != ?';
      whereArgs = [excludeStation];
    }

    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: 200,
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }
}
