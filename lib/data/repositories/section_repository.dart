import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../database/database_service.dart';
import '../models/section_model.dart';

class SectionRepository {
  Database get _db => DatabaseService.instance.db;

  Future<List<SectionModel>> getAll(LawType lawType) async {
    final table = lawType == LawType.ipc
        ? AppConstants.tableIpcSections
        : AppConstants.tableBnsSections;
    final maps = await _db.query(table, orderBy: 'section_number ASC');
    return maps.map((m) => SectionModel.fromMap({...m, 'law_type': lawType.name})).toList();
  }

  Future<List<SectionModel>> search(String query, {LawType? lawType}) async {
    final q = '%$query%';

    Future<List<SectionModel>> searchTable(String table, LawType type) async {
      final maps = await _db.query(
        table,
        where: 'section_number LIKE ? OR description LIKE ?',
        whereArgs: [q, q],
        orderBy: 'section_number ASC',
        limit: 50,
      );
      return maps.map((m) => SectionModel.fromMap({...m, 'law_type': type.name})).toList();
    }

    if (lawType == LawType.ipc) {
      return searchTable(AppConstants.tableIpcSections, LawType.ipc);
    } else if (lawType == LawType.bns) {
      return searchTable(AppConstants.tableBnsSections, LawType.bns);
    }

    final ipcResults = await searchTable(AppConstants.tableIpcSections, LawType.ipc);
    final bnsResults = await searchTable(AppConstants.tableBnsSections, LawType.bns);
    return [...ipcResults, ...bnsResults];
  }

  /// Look up sections by their numbers. Returns map: sectionNumber → SectionModel.
  Future<Map<String, SectionModel>> getByNumbers(
      List<String> ipcNumbers, List<String> bnsNumbers) async {
    final result = <String, SectionModel>{};
    if (ipcNumbers.isNotEmpty) {
      final placeholders = ipcNumbers.map((_) => '?').join(',');
      final maps = await _db.rawQuery(
        'SELECT * FROM ${AppConstants.tableIpcSections} WHERE section_number IN ($placeholders)',
        ipcNumbers,
      );
      for (final m in maps) {
        result[m['section_number'] as String] = SectionModel.fromMap({...m, 'law_type': 'ipc'});
      }
    }
    if (bnsNumbers.isNotEmpty) {
      final placeholders = bnsNumbers.map((_) => '?').join(',');
      final maps = await _db.rawQuery(
        'SELECT * FROM ${AppConstants.tableBnsSections} WHERE section_number IN ($placeholders)',
        bnsNumbers,
      );
      for (final m in maps) {
        result[m['section_number'] as String] = SectionModel.fromMap({...m, 'law_type': 'bns'});
      }
    }
    return result;
  }
}
