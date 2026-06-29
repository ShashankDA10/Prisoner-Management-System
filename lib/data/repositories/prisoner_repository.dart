import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../database/database_service.dart';
import '../models/prisoner_model.dart';

/// Abstract interface — swap impl for REST/PostgreSQL without touching callers.
abstract class PrisonerRepositoryBase {
  Future<List<PrisonerModel>> getAll();
  Future<PrisonerModel?> getById(String id);
  Future<String> insert(PrisonerModel prisoner);
  Future<void> update(PrisonerModel prisoner);
  Future<void> delete(String id);
  Future<List<PrisonerModel>> search(String query);
  Future<List<PrisonerModel>> getByStatus(PrisonerStatus status);
  Future<List<PrisonerModel>> getByDateFilter(DateFilter filter, {DateTime? from, DateTime? to});
  Future<Map<String, int>> getDashboardStats();
  Future<Map<String, int>> bulkImport(
    List<PrisonerModel> prisoners, {
    bool updateExisting,
    bool skipDuplicates,
  });
}

/// SQLite implementation.
class PrisonerRepository implements PrisonerRepositoryBase {
  final _uuid = const Uuid();
  Database get _db => DatabaseService.instance.db;

  @override
  Future<List<PrisonerModel>> getAll() async {
    final maps = await _db.query(
      AppConstants.tablePrisoners,
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

  @override
  Future<List<PrisonerModel>> search(String query) async {
    final q = '%$query%';
    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: 'name LIKE ? OR prisoner_id LIKE ? OR fir_number LIKE ? OR crime_number LIKE ? OR police_station LIKE ? OR ipc_sections LIKE ? OR bns_sections LIKE ?',
      whereArgs: [q, q, q, q, q, q, q],
      orderBy: 'name ASC',
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }

  @override
  Future<List<PrisonerModel>> getByStatus(PrisonerStatus status) async {
    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'name ASC',
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }

  @override
  Future<List<PrisonerModel>> getByDateFilter(DateFilter filter, {DateTime? from, DateTime? to}) async {
    String? where;
    List<dynamic>? whereArgs;

    final now = DateTime.now();
    switch (filter) {
      case DateFilter.today:
        final today = DateTime(now.year, now.month, now.day).toIso8601String();
        where = "DATE(admission_date) = DATE('$today')";
        break;
      case DateFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        where = "admission_date >= ?";
        whereArgs = [DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toIso8601String()];
        break;
      case DateFilter.thisMonth:
        where = "strftime('%Y-%m', admission_date) = '${now.year}-${now.month.toString().padLeft(2, '0')}'";
        break;
      case DateFilter.custom:
        if (from != null && to != null) {
          where = "admission_date >= ? AND admission_date <= ?";
          whereArgs = [from.toIso8601String(), to.toIso8601String()];
        }
        break;
    }

    final maps = await _db.query(
      AppConstants.tablePrisoners,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'admission_date DESC',
    );
    return maps.map(PrisonerModel.fromMap).toList();
  }

  @override
  Future<Map<String, int>> getDashboardStats() async {
    Future<int> count(String? where, [List<dynamic>? args]) async =>
        Sqflite.firstIntValue(await _db.rawQuery(
          'SELECT COUNT(*) FROM ${AppConstants.tablePrisoners}${where != null ? ' WHERE $where' : ''}',
          args,
        )) ?? 0;

    final total       = await count(null);
    final undertrial  = await count("status = 'undertrial'");
    final convicted   = await count("status = 'convicted'");
    final admitted    = await count("DATE(admission_date) = DATE('now')");
    final released    = await count("status = 'released'");
    final bail        = await count("status = 'bail'");
    final transferred = await count("status = 'transferred'");

    return {
      'total':       total,
      'undertrial':  undertrial,
      'convicted':   convicted,
      'admitted':    admitted,
      'released':    released,
      'bail':        bail,
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
}
