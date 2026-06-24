import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../datasources/section_seed_data.dart';

/// SQLite database service for mobile + desktop.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  Database get db {
    assert(_db != null, 'DatabaseService not initialised — call init() first.');
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = join(await getDatabasesPath(), AppConstants.dbName);
    _db = await openDatabase(
      dbPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _seedSectionsIfNeeded();
    await _createDefaultAdmin();
  }

  // ── Schema ──────────────────────────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_prisonersTable);
    await db.execute(_usersTable);
    await db.execute(_auditLogsTable);
    await db.execute(_ipcSectionsTable);
    await db.execute(_bnsSectionsTable);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migration scripts go here.
  }

  static const _prisonersTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tablePrisoners} (
      id             TEXT PRIMARY KEY,
      prisoner_id    TEXT NOT NULL UNIQUE,
      name           TEXT NOT NULL,
      age            INTEGER NOT NULL,
      gender         TEXT NOT NULL,
      fir_number     TEXT NOT NULL,
      crime_number   TEXT NOT NULL,
      police_station TEXT NOT NULL,
      prison_name    TEXT NOT NULL,
      admission_date TEXT NOT NULL,
      status         TEXT NOT NULL,
      ipc_sections   TEXT DEFAULT '',
      bns_sections   TEXT DEFAULT '',
      release_date   TEXT,
      release_reason TEXT,
      remarks        TEXT,
      created_at     TEXT NOT NULL,
      updated_at     TEXT NOT NULL,
      created_by     TEXT
    )
  ''';

  static const _usersTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableUsers} (
      id             TEXT PRIMARY KEY,
      name           TEXT NOT NULL,
      username       TEXT NOT NULL UNIQUE,
      password_hash  TEXT NOT NULL,
      role           TEXT NOT NULL,
      police_station TEXT,
      email          TEXT,
      phone          TEXT,
      is_active      INTEGER DEFAULT 1,
      created_at     TEXT NOT NULL,
      updated_at     TEXT NOT NULL
    )
  ''';

  static const _auditLogsTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableAuditLogs} (
      id          TEXT PRIMARY KEY,
      user_id     TEXT NOT NULL,
      user_name   TEXT NOT NULL,
      action      TEXT NOT NULL,
      target_id   TEXT,
      description TEXT,
      ip_address  TEXT,
      timestamp   TEXT NOT NULL
    )
  ''';

  static const _ipcSectionsTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableIpcSections} (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      section_number TEXT NOT NULL UNIQUE,
      description    TEXT NOT NULL,
      law_type       TEXT DEFAULT 'ipc',
      category       TEXT
    )
  ''';

  static const _bnsSectionsTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableBnsSections} (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      section_number TEXT NOT NULL UNIQUE,
      description    TEXT NOT NULL,
      law_type       TEXT DEFAULT 'bns',
      category       TEXT
    )
  ''';

  // ── Seed ────────────────────────────────────────────────────────────────────
  Future<void> _seedSectionsIfNeeded() async {
    final count = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableIpcSections}'));
    if ((count ?? 0) > 0) return;

    final batch = _db!.batch();
    for (final s in SectionSeedData.ipcSections) {
      batch.insert(AppConstants.tableIpcSections, s,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final s in SectionSeedData.bnsSections) {
      batch.insert(AppConstants.tableBnsSections, s,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    if (kDebugMode) debugPrint('Section seed data inserted.');
  }

  Future<void> _createDefaultAdmin() async {
    final count = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableUsers}'));
    if ((count ?? 0) > 0) return;

    final now = DateTime.now().toIso8601String();
    await _db!.insert(AppConstants.tableUsers, {
      'id':           'admin-default',
      'name':         'System Administrator',
      'username':     'admin',
      'password_hash': 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', // sha256 of 'admin@123'
      'role':         'admin',
      'police_station': null,
      'email':        'admin@ksp.gov.in',
      'phone':        null,
      'is_active':    1,
      'created_at':   now,
      'updated_at':   now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
