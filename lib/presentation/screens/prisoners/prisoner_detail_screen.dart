import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/prisoner_model.dart';
import '../../../data/models/section_model.dart';
import '../../../data/repositories/section_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';
import '../../../core/constants/enums.dart';

Color _statusColor(PrisonerStatus s) => switch (s) {
  PrisonerStatus.undertrial  => AppTheme.warning,
  PrisonerStatus.convicted   => AppTheme.error,
  PrisonerStatus.released    => AppTheme.success,
  PrisonerStatus.bail        => AppTheme.info,
  PrisonerStatus.transferred => AppTheme.primaryNavy,
  PrisonerStatus.acquitted   => AppTheme.success,
};

class PrisonerDetailScreen extends ConsumerStatefulWidget {
  final String prisonerId;
  const PrisonerDetailScreen({super.key, required this.prisonerId});

  @override
  ConsumerState<PrisonerDetailScreen> createState() => _State();
}

class _State extends ConsumerState<PrisonerDetailScreen> {
  PrisonerModel? _prisoner;
  Map<String, SectionModel> _sections = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pRepo = ref.read(prisonerRepositoryProvider);
    final sRepo = SectionRepository();
    final p = await pRepo.getById(widget.prisonerId);
    if (p == null || !mounted) {
      setState(() => _loading = false);
      return;
    }
    final sections = await sRepo.getByNumbers(p.ipcSections, p.bnsSections);
    setState(() { _prisoner = p; _sections = sections; _loading = false; });
  }

  /// True when the current user CANNOT edit this record:
  /// either they are a station-locked user viewing another station's record,
  /// or their role doesn't grant delete/edit rights.
  bool _isReadOnly(PrisonerModel p) {
    final user = ref.read(authProvider).value;
    if (user == null) return true;
    if (user.role.canSeeAllStations) return false; // admin/higher can always edit
    // Station-scoped user can only edit records from their own station.
    final myStation = user.policeStation ?? '';
    return myStation.isEmpty || p.policeStation != myStation;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());
    if (_prisoner == null) {
      return Scaffold(
        body: ErrorState(
          message: 'Prisoner not found',
          onRetry: () => context.go(Routes.prisoners),
        ),
      );
    }
    final p        = _prisoner!;
    final readOnly = _isReadOnly(p);

    return PageWrapper(
      title:    p.name,
      subtitle: p.prisonerId,
      actions: [
        // READ ONLY badge — shown when viewing another station's record
        if (readOnly) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, size: 14, color: AppTheme.warning),
              SizedBox(width: 5),
              Text(
                'READ ONLY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warning,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
        ],
        if (!readOnly) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            onPressed: () => context.go('/prisoners/${p.id}/edit'),
          ),
          const SizedBox(width: 10),
        ],
        OutlinedButton(
          onPressed: () => context.go(Routes.prisoners),
          child: const Text('Back'),
        ),
      ],
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station banner for cross-station records
          if (readOnly) _crossStationBanner(p),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left column
            Expanded(flex: 2, child: Column(children: [
              _card('Personal Information', [
                _row2('Prisoner ID', p.prisonerId),
                _row2('Full Name', p.name),
                _row2('Age', '${p.age} years'),
                _row2('Gender', p.gender.label),
              ]),
              const SizedBox(height: 16),
              _card('Case Information', [
                _row2('FIR Number', p.firNumber),
                _row2('Crime Number', p.crimeNumber),
                // Station row with visual indicator
                _row2Widget(
                  'Police Station',
                  Row(children: [
                    const Icon(Icons.local_police_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.policeStation,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
                _row2('Prison', p.prisonName),
              ]),
              const SizedBox(height: 16),
              _card('Admission & Status', [
                _row2('Admission Date', p.admissionDate.displayDate),
                _row2Widget(
                  'Status',
                  StatusBadge(
                      label: p.status.label,
                      color: _statusColor(p.status)),
                ),
                if (p.releaseDate != null)
                  _row2('Release Date', p.releaseDate!.displayDate),
                if (p.releaseReason != null)
                  _row2('Release Reason', p.releaseReason!.label),
              ]),
            ])),
            const SizedBox(width: 16),

            // Right column
            Expanded(child: Column(children: [
              _card('Sections Applied', [
                if (p.ipcSections.isEmpty && p.bnsSections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No sections applied',
                        style: TextStyle(color: AppTheme.textDisabled)),
                  ),
                ...p.ipcSections.map((n) {
                  final s = _sections[n];
                  return _sectionRow(
                      n, s?.description ?? 'IPC Section $n', false);
                }),
                ...p.bnsSections.map((n) {
                  final s = _sections[n];
                  return _sectionRow(
                      n, s?.description ?? 'BNS Section $n', true);
                }),
              ]),
              const SizedBox(height: 16),
              if (p.remarks?.isNotEmpty == true) ...[
                _card('Remarks', [
                  Text(p.remarks!,
                      style: const TextStyle(fontSize: 13, height: 1.6)),
                ]),
                const SizedBox(height: 16),
              ],
              _card('Record Metadata', [
                _row2('Created', p.createdAt.displayDateTime),
                _row2('Last Updated', p.updatedAt.displayDateTime),
                if (p.createdBy != null) _row2('Created By', p.createdBy!),
              ]),
            ])),
          ]),
        ],
      ),
    );
  }

  // ── Cross-station banner ──────────────────────────────────────────────────────

  Widget _crossStationBanner(PrisonerModel p) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'This record belongs to ${p.policeStation}. '
            'You can view it but cannot make any changes.',
            style: const TextStyle(fontSize: 13, color: AppTheme.warning),
          ),
        ),
      ]),
    );
  }

  // ── Card builder ─────────────────────────────────────────────────────────────

  Widget _card(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryNavy)),
        const Divider(height: 16),
        ...rows,
      ]),
    );
  }

  Widget _row2(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  Widget _row2Widget(String label, Widget widget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ),
        Expanded(child: widget),
      ]),
    );
  }

  Widget _sectionRow(String number, String description, bool isBns) {
    final color = isBns ? AppTheme.info : AppTheme.primaryNavy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '§$number',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(description,
              style: const TextStyle(fontSize: 12, height: 1.4)),
        ),
      ]),
    );
  }
}
