import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../models/prisoner_model.dart';
import '../repositories/prisoner_repository.dart';

/// Seeds demo prisoner records so the app is not empty on first run.
class SampleDataSeeder {
  SampleDataSeeder._();

  static final _uuid = const Uuid();

  static Future<void> seed(PrisonerRepository repo) async {
    final existing = await repo.getAll();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();

    final samples = [
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2024/001',
        name: 'Raju Kumar', age: 32, gender: Gender.male,
        firNumber: 'CR No. 45/2024', crimeNumber: 'SC No. 112/2024',
        policeStation: 'Cubbon Park PS', prisonName: 'Parappana Agrahara Central Prison',
        admissionDate: now.subtract(const Duration(days: 30)),
        status: PrisonerStatus.undertrial,
        ipcSections: ['302', '34'], bnsSections: [],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2024/002',
        name: 'Suresh Gowda', age: 45, gender: Gender.male,
        firNumber: 'CR No. 78/2024', crimeNumber: 'SC No. 198/2024',
        policeStation: 'Whitefield PS', prisonName: 'Parappana Agrahara Central Prison',
        admissionDate: now.subtract(const Duration(days: 15)),
        status: PrisonerStatus.undertrial,
        ipcSections: ['420', '406', '34'], bnsSections: [],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2024/003',
        name: 'Meena Devi', age: 28, gender: Gender.female,
        firNumber: 'CR No. 122/2024', crimeNumber: 'SC No. 305/2024',
        policeStation: 'Indiranagar PS', prisonName: 'Bangalore Women Prison',
        admissionDate: now.subtract(const Duration(days: 60)),
        status: PrisonerStatus.convicted,
        ipcSections: ['304B', '498A'], bnsSections: [],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2024/004',
        name: 'Mohammed Ismail', age: 38, gender: Gender.male,
        firNumber: 'CR No. 201/2024', crimeNumber: 'SC No. 489/2024',
        policeStation: 'Shivajinagar PS', prisonName: 'Parappana Agrahara Central Prison',
        admissionDate: now.subtract(const Duration(days: 10)),
        status: PrisonerStatus.undertrial,
        ipcSections: ['392', '395', '397'], bnsSections: [],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2024/005',
        name: 'Priya S', age: 24, gender: Gender.female,
        firNumber: 'CR No. 355/2024', crimeNumber: 'SC No. 701/2024',
        policeStation: 'KR Puram PS', prisonName: 'Bangalore Women Prison',
        admissionDate: now.subtract(const Duration(days: 90)),
        status: PrisonerStatus.bail,
        ipcSections: ['380', '411'], bnsSections: [],
        releaseDate: now.subtract(const Duration(days: 20)),
        releaseReason: ReleaseReason.bail,
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/MYS/2024/001',
        name: 'Venkataramaiah P', age: 55, gender: Gender.male,
        firNumber: 'CR No. 88/2024', crimeNumber: 'SC No. 201/2024',
        policeStation: 'Vijayanagar PS, Mysore', prisonName: 'Mysore Central Prison',
        admissionDate: now.subtract(const Duration(days: 120)),
        status: PrisonerStatus.convicted,
        ipcSections: ['302', '307', '34'], bnsSections: [],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2024/006',
        name: 'Arjun Reddy', age: 29, gender: Gender.male,
        firNumber: 'CR No. 412/2024', crimeNumber: 'SC No. 888/2024',
        policeStation: 'Electronic City PS', prisonName: 'Parappana Agrahara Central Prison',
        admissionDate: now.subtract(const Duration(days: 5)),
        status: PrisonerStatus.undertrial,
        ipcSections: [], bnsSections: ['103', '49'],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2023/099',
        name: 'Ramesh Naidu', age: 42, gender: Gender.male,
        firNumber: 'CR No. 912/2023', crimeNumber: 'SC No. 1099/2023',
        policeStation: 'Koramangala PS', prisonName: 'Parappana Agrahara Central Prison',
        admissionDate: now.subtract(const Duration(days: 365)),
        status: PrisonerStatus.released,
        ipcSections: ['379', '411'], bnsSections: [],
        releaseDate: now.subtract(const Duration(days: 2)),
        releaseReason: ReleaseReason.sentenceCompletion,
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/BLR/2024/007',
        name: 'Kavitha R', age: 33, gender: Gender.female,
        firNumber: 'CR No. 501/2024', crimeNumber: 'SC No. 999/2024',
        policeStation: 'Yelahanka PS', prisonName: 'Bangalore Women Prison',
        admissionDate: now.subtract(const Duration(days: 1)),
        status: PrisonerStatus.undertrial,
        ipcSections: ['376', '354'], bnsSections: [],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
        remarks: 'High-profile case — media attention expected',
      ),
      PrisonerModel(
        id: _uuid.v4(), prisonerId: 'KSP/HUB/2024/001',
        name: 'Santosh Patil', age: 36, gender: Gender.male,
        firNumber: 'CR No. 33/2024', crimeNumber: 'SC No. 55/2024',
        policeStation: 'Hubli Town PS', prisonName: 'Hubli District Prison',
        admissionDate: now.subtract(const Duration(days: 45)),
        status: PrisonerStatus.transferred,
        ipcSections: ['395', '397', '399'], bnsSections: [],
        createdAt: now, updatedAt: now, createdBy: 'admin-default',
      ),
    ];

    for (final p in samples) {
      await repo.insert(p);
    }
  }
}
