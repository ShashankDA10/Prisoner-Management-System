import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../data/models/section_model.dart';
import '../../data/repositories/section_repository.dart';

final sectionRepositoryProvider = Provider<SectionRepository>((ref) => SectionRepository());

final ipcSectionsProvider = FutureProvider<List<SectionModel>>((ref) async {
  return ref.read(sectionRepositoryProvider).getAll(LawType.ipc);
});

final bnsSectionsProvider = FutureProvider<List<SectionModel>>((ref) async {
  return ref.read(sectionRepositoryProvider).getAll(LawType.bns);
});

final sectionSearchQueryProvider = StateProvider<String>((ref) => '');
final sectionLawTypeFilterProvider = StateProvider<LawType?>((ref) => null);

final sectionSearchResultsProvider = FutureProvider<List<SectionModel>>((ref) async {
  final query   = ref.watch(sectionSearchQueryProvider);
  final lawType = ref.watch(sectionLawTypeFilterProvider);
  final repo    = ref.read(sectionRepositoryProvider);
  if (query.trim().isEmpty) {
    if (lawType != null) return repo.getAll(lawType);
    final ipc = await repo.getAll(LawType.ipc);
    final bns = await repo.getAll(LawType.bns);
    return [...ipc, ...bns];
  }
  return repo.search(query.trim(), lawType: lawType);
});
