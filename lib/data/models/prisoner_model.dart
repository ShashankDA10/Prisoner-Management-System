import '../../core/constants/enums.dart';

class PrisonerModel {
  final String id;
  final String prisonerId;    // e.g. KSP/BLR/2024/001
  final String name;
  final int    age;
  final Gender gender;
  final String firNumber;
  final String crimeNumber;
  final String policeStation;
  final String prisonName;
  final DateTime admissionDate;
  final PrisonerStatus status;
  final List<String> ipcSections;  // e.g. ["302", "420"]
  final List<String> bnsSections;  // e.g. ["103", "318"]
  final DateTime? releaseDate;
  final ReleaseReason? releaseReason;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const PrisonerModel({
    required this.id,
    required this.prisonerId,
    required this.name,
    required this.age,
    required this.gender,
    required this.firNumber,
    required this.crimeNumber,
    required this.policeStation,
    required this.prisonName,
    required this.admissionDate,
    required this.status,
    this.ipcSections = const [],
    this.bnsSections = const [],
    this.releaseDate,
    this.releaseReason,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  // ── API (camelCase JSON) ──────────────────────────────────────────────────

  factory PrisonerModel.fromApiJson(Map<String, dynamic> j) {
    return PrisonerModel(
      id:            j['id']            as String,
      prisonerId:    j['prisonerId']     as String,
      name:          j['name']          as String,
      age:           (j['age'] as num).toInt(),
      gender:        Gender.values.firstWhere(
          (e) => e.name == (j['gender'] as String),
          orElse: () => Gender.male),
      firNumber:     j['firNumber']     as String? ?? '',
      crimeNumber:   j['crimeNumber']   as String? ?? '',
      policeStation: j['policeStation'] as String? ?? '',
      prisonName:    j['prisonName']    as String? ?? '',
      admissionDate: DateTime.parse(j['admissionDate'] as String),
      status:        PrisonerStatus.values.firstWhere(
          (e) => e.name == (j['status'] as String),
          orElse: () => PrisonerStatus.undertrial),
      ipcSections:   (j['ipcSections'] as List?)?.cast<String>() ?? [],
      bnsSections:   (j['bnsSections'] as List?)?.cast<String>() ?? [],
      releaseDate:   j['releaseDate'] != null
          ? DateTime.parse(j['releaseDate'] as String) : null,
      releaseReason: j['releaseReason'] != null
          ? ReleaseReason.values.firstWhere(
              (e) => e.name == (j['releaseReason'] as String),
              orElse: () => ReleaseReason.other)
          : null,
      remarks:   j['remarks']   as String?,
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt: DateTime.parse(j['updatedAt'] as String),
      createdBy: j['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toApiJson() => {
    'id':            id,
    'prisonerId':    prisonerId,
    'name':          name,
    'age':           age,
    'gender':        gender.name,
    'firNumber':     firNumber,
    'crimeNumber':   crimeNumber,
    'policeStation': policeStation,
    'prisonName':    prisonName,
    'admissionDate': admissionDate.toIso8601String(),
    'status':        status.name,
    'ipcSections':   ipcSections,
    'bnsSections':   bnsSections,
    'releaseDate':   releaseDate?.toIso8601String(),
    'releaseReason': releaseReason?.name,
    'remarks':       remarks,
    'createdAt':     createdAt.toIso8601String(),
    'updatedAt':     updatedAt.toIso8601String(),
    'createdBy':     createdBy,
  };

  // ── SQLite (snake_case) ───────────────────────────────────────────────────

  factory PrisonerModel.fromMap(Map<String, dynamic> map) {
    return PrisonerModel(
      id:            map['id'] as String,
      prisonerId:    map['prisoner_id'] as String,
      name:          map['name'] as String,
      age:           map['age'] as int,
      gender:        Gender.values.firstWhere((e) => e.name == (map['gender'] as String), orElse: () => Gender.male),
      firNumber:     map['fir_number'] as String,
      crimeNumber:   map['crime_number'] as String,
      policeStation: map['police_station'] as String,
      prisonName:    map['prison_name'] as String,
      admissionDate: DateTime.parse(map['admission_date'] as String),
      status:        PrisonerStatus.values.firstWhere((e) => e.name == (map['status'] as String), orElse: () => PrisonerStatus.undertrial),
      ipcSections:   (map['ipc_sections'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      bnsSections:   (map['bns_sections'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      releaseDate:   map['release_date'] != null ? DateTime.parse(map['release_date'] as String) : null,
      releaseReason: map['release_reason'] != null
          ? ReleaseReason.values.firstWhere((e) => e.name == (map['release_reason'] as String), orElse: () => ReleaseReason.other)
          : null,
      remarks:       map['remarks'] as String?,
      createdAt:     DateTime.parse(map['created_at'] as String),
      updatedAt:     DateTime.parse(map['updated_at'] as String),
      createdBy:     map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':            id,
      'prisoner_id':   prisonerId,
      'name':          name,
      'age':           age,
      'gender':        gender.name,
      'fir_number':    firNumber,
      'crime_number':  crimeNumber,
      'police_station':policeStation,
      'prison_name':   prisonName,
      'admission_date':admissionDate.toIso8601String(),
      'status':        status.name,
      'ipc_sections':  ipcSections.join(','),
      'bns_sections':  bnsSections.join(','),
      'release_date':  releaseDate?.toIso8601String(),
      'release_reason':releaseReason?.name,
      'remarks':       remarks,
      'created_at':    createdAt.toIso8601String(),
      'updated_at':    updatedAt.toIso8601String(),
      'created_by':    createdBy,
    };
  }

  PrisonerModel copyWith({
    String? id,
    String? prisonerId,
    String? name,
    int? age,
    Gender? gender,
    String? firNumber,
    String? crimeNumber,
    String? policeStation,
    String? prisonName,
    DateTime? admissionDate,
    PrisonerStatus? status,
    List<String>? ipcSections,
    List<String>? bnsSections,
    DateTime? releaseDate,
    ReleaseReason? releaseReason,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PrisonerModel(
      id:            id            ?? this.id,
      prisonerId:    prisonerId    ?? this.prisonerId,
      name:          name          ?? this.name,
      age:           age           ?? this.age,
      gender:        gender        ?? this.gender,
      firNumber:     firNumber     ?? this.firNumber,
      crimeNumber:   crimeNumber   ?? this.crimeNumber,
      policeStation: policeStation ?? this.policeStation,
      prisonName:    prisonName    ?? this.prisonName,
      admissionDate: admissionDate ?? this.admissionDate,
      status:        status        ?? this.status,
      ipcSections:   ipcSections   ?? this.ipcSections,
      bnsSections:   bnsSections   ?? this.bnsSections,
      releaseDate:   releaseDate   ?? this.releaseDate,
      releaseReason: releaseReason ?? this.releaseReason,
      remarks:       remarks       ?? this.remarks,
      createdAt:     createdAt     ?? this.createdAt,
      updatedAt:     updatedAt     ?? this.updatedAt,
      createdBy:     createdBy     ?? this.createdBy,
    );
  }
}
