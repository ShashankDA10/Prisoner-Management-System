import '../../core/constants/enums.dart';

class UserModel {
  final String   id;
  final String   name;
  final String   username;
  final String   passwordHash;
  final UserRole role;
  final String?  policeStation;
  final String?  email;
  final String?  phone;
  final bool     isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.policeStation,
    this.email,
    this.phone,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id:            map['id'] as String,
      name:          map['name'] as String,
      username:      map['username'] as String,
      passwordHash:  map['password_hash'] as String,
      role:          UserRole.values.firstWhere(
          (e) => e.name == (map['role'] as String),
          orElse: () => UserRole.si),
      policeStation: map['police_station'] as String?,
      email:         map['email'] as String?,
      phone:         map['phone'] as String?,
      isActive:      (map['is_active'] as int? ?? 1) == 1,
      createdAt:     DateTime.parse(map['created_at'] as String),
      updatedAt:     DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':            id,
      'name':          name,
      'username':      username,
      'password_hash': passwordHash,
      'role':          role.name,
      'police_station':policeStation,
      'email':         email,
      'phone':         phone,
      'is_active':     isActive ? 1 : 0,
      'created_at':    createdAt.toIso8601String(),
      'updated_at':    updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? username,
    String? passwordHash,
    UserRole? role,
    String? policeStation,
    String? email,
    String? phone,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id:            id,
      name:          name          ?? this.name,
      username:      username      ?? this.username,
      passwordHash:  passwordHash  ?? this.passwordHash,
      role:          role          ?? this.role,
      policeStation: policeStation ?? this.policeStation,
      email:         email         ?? this.email,
      phone:         phone         ?? this.phone,
      isActive:      isActive      ?? this.isActive,
      createdAt:     createdAt,
      updatedAt:     updatedAt     ?? this.updatedAt,
    );
  }
}
