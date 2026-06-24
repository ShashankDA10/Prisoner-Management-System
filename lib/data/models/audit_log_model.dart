import '../../core/constants/enums.dart';

class AuditLogModel {
  final String      id;
  final String      userId;
  final String      userName;
  final AuditAction action;
  final String?     targetId;
  final String?     description;
  final String?     ipAddress;
  final DateTime    timestamp;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    this.targetId,
    this.description,
    this.ipAddress,
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id:          map['id'] as String,
      userId:      map['user_id'] as String,
      userName:    map['user_name'] as String,
      action:      AuditAction.values.firstWhere(
          (e) => e.name == (map['action'] as String),
          orElse: () => AuditAction.login),
      targetId:    map['target_id'] as String?,
      description: map['description'] as String?,
      ipAddress:   map['ip_address'] as String?,
      timestamp:   DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':          id,
    'user_id':     userId,
    'user_name':   userName,
    'action':      action.name,
    'target_id':   targetId,
    'description': description,
    'ip_address':  ipAddress,
    'timestamp':   timestamp.toIso8601String(),
  };
}
