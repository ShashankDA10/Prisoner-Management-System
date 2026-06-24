import '../../core/constants/enums.dart';

class SectionModel {
  final String  id;
  final String  sectionNumber;
  final String  description;
  final LawType lawType;
  final String? category;

  const SectionModel({
    required this.id,
    required this.sectionNumber,
    required this.description,
    required this.lawType,
    this.category,
  });

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    return SectionModel(
      id:            map['id'].toString(),
      sectionNumber: map['section_number'] as String,
      description:   map['description'] as String,
      lawType:       LawType.values.firstWhere(
          (e) => e.name == (map['law_type'] as String),
          orElse: () => LawType.ipc),
      category:      map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':             id,
    'section_number': sectionNumber,
    'description':    description,
    'law_type':       lawType.name,
    'category':       category,
  };

  /// Formatted display: "302 – Murder (IPC)"
  String get displayLabel => '$sectionNumber – $description (${lawType.label})';
}
