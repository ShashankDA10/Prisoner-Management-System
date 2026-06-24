import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../database/database_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final _uuid = const Uuid();
  Database get _db => DatabaseService.instance.db;

  Future<List<UserModel>> getAll() async {
    final maps = await _db.query(
      AppConstants.tableUsers,
      orderBy: 'name ASC',
    );
    return maps.map(UserModel.fromMap).toList();
  }

  Future<UserModel?> getById(String id) async {
    final maps = await _db.query(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : UserModel.fromMap(maps.first);
  }

  Future<UserModel?> authenticate(String username, String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    final maps = await _db.query(
      AppConstants.tableUsers,
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, hash],
      limit: 1,
    );
    return maps.isEmpty ? null : UserModel.fromMap(maps.first);
  }

  Future<String> insert(UserModel user) async {
    final id = user.id.isEmpty ? _uuid.v4() : user.id;
    final now = DateTime.now();
    await _db.insert(
      AppConstants.tableUsers,
      user.copyWith(updatedAt: now).toMap()..['id'] = id,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<void> update(UserModel user) async {
    await _db.update(
      AppConstants.tableUsers,
      user.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();
}
