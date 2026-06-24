import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../database/database_service.dart';
import '../models/audit_log_model.dart';

class AuditLogRepository {
  final _uuid = const Uuid();
  Database get _db => DatabaseService.instance.db;

  Future<List<AuditLogModel>> getAll({int limit = 200}) async {
    final maps = await _db.query(
      AppConstants.tableAuditLogs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map(AuditLogModel.fromMap).toList();
  }

  Future<void> log({
    required String userId,
    required String userName,
    required AuditAction action,
    String? targetId,
    String? description,
  }) async {
    final log = AuditLogModel(
      id:          _uuid.v4(),
      userId:      userId,
      userName:    userName,
      action:      action,
      targetId:    targetId,
      description: description,
      timestamp:   DateTime.now(),
    );
    await _db.insert(
      AppConstants.tableAuditLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
