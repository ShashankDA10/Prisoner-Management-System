import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed storage for web platform.
class HiveDatabaseService {
  HiveDatabaseService._();
  static final HiveDatabaseService instance = HiveDatabaseService._();

  static const _prisonerBox   = 'prisoners';
  static const _userBox       = 'users';
  static const _auditBox      = 'audit_logs';
  static const _ipcBox        = 'ipc_sections';
  static const _bnsBox        = 'bns_sections';
  static const _settingsBox   = 'settings';

  Future<void> init() async {
    await Hive.openBox<Map>(_prisonerBox);
    await Hive.openBox<Map>(_userBox);
    await Hive.openBox<Map>(_auditBox);
    await Hive.openBox<Map>(_ipcBox);
    await Hive.openBox<Map>(_bnsBox);
    await Hive.openBox<dynamic>(_settingsBox);
  }

  Box<Map> get prisoners  => Hive.box<Map>(_prisonerBox);
  Box<Map> get users      => Hive.box<Map>(_userBox);
  Box<Map> get auditLogs  => Hive.box<Map>(_auditBox);
  Box<Map> get ipcSections=> Hive.box<Map>(_ipcBox);
  Box<Map> get bnsSections=> Hive.box<Map>(_bnsBox);
  Box<dynamic> get settings => Hive.box<dynamic>(_settingsBox);
}
