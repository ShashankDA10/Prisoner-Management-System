import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/prisoner_model.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';

/// Read-only view of prisoners from stations other than the logged-in user's.
/// Admins / higher roles see all stations here; station-locked users see
/// every station except their own.
/// No edit, delete, or transfer actions are available on this screen.
class OtherStationCasesScreen extends ConsumerWidget {
  const OtherStationCasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return isMobile
        ? const _MobileLayout()
        : const _DesktopLayout();
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prisonersAsync = ref.watch(crossStationPrisonersProvider);

    return PageWrapper(
      title:    'Other Station Cases',
      subtitle: 'Read-only view of records from other police stations',
      child: Column(children: [
        _SearchBar(),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: prisonersAsync.when(
            loading: () => const LoadingState(),
            error:   (e, _) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(crossStationPrisonersProvider),
            ),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    title: 'No records found',
                    subtitle: 'Try searching by name, FIR number, or station.',
                    icon: Icons.swap_horiz_outlined,
                  )
                : _PrisonerReadOnlyTable(prisoners: list),
          ),
        ),
      ]),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prisonersAsync = ref.watch(crossStationPrisonersProvider);

    return ColoredBox(
      color: AppTheme.surfaceGrey,
      child: Column(children: [
        // Title bar
        Container(
          width: double.infinity,
          color: AppTheme.surfaceWhite,
          padding: const EdgeInsets.fromLTRB(
              Spacing.md, Spacing.sm, Spacing.md, Spacing.sm),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Other Station Cases',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryNavy,
                ),
              ),
              SizedBox(height: 2),
              Row(children: [
                Icon(Icons.lock_outline, size: 12, color: AppTheme.warning),
                SizedBox(width: 4),
                Text(
                  'Read-only — no edits permitted',
                  style: TextStyle(fontSize: 12, color: AppTheme.warning),
                ),
              ]),
            ],
          ),
        ),
        // Search
        Container(
          color: AppTheme.surfaceWhite,
          padding: const EdgeInsets.fromLTRB(
              Spacing.md, 0, Spacing.md, Spacing.sm),
          child: _SearchBar(),
        ),
        // Results
        Expanded(
          child: prisonersAsync.when(
            loading: () => const LoadingState(),
            error:   (e, _) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(crossStationPrisonersProvider),
            ),
            data: (list) => list.isEmpty
                ? const EmptyState(
                    title: 'No records found',
                    subtitle: 'Try a name, FIR number, or station name.',
                    icon: Icons.swap_horiz_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (ctx, i) =>
                        _ReadOnlyCard(prisoner: list[i]),
                  ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared search bar ─────────────────────────────────────────────────────────

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (v) =>
          ref.read(crossStationSearchQueryProvider.notifier).state = v,
      decoration: InputDecoration(
        hintText: 'Search by name, FIR, crime no., station…',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: ref.watch(crossStationSearchQueryProvider).isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => ref
                    .read(crossStationSearchQueryProvider.notifier)
                    .state = '',
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ── Desktop read-only table ───────────────────────────────────────────────────

class _PrisonerReadOnlyTable extends ConsumerWidget {
  final List<PrisonerModel> prisoners;
  const _PrisonerReadOnlyTable({required this.prisoners});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceGrey,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: AppTheme.warning),
            const SizedBox(width: 6),
            Text(
              '${prisoners.length} records — read-only',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ),
        // Rows
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(0.8),
              },
              children: [
                _tableHeader(),
                ...prisoners.map((p) => _tableRow(context, p)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  TableRow _tableHeader() {
    const style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary);
    return TableRow(
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppTheme.borderLight))),
      children: [
        _th('Prisoner ID', style),
        _th('Name', style),
        _th('Police Station', style),
        _th('Status', style),
        _th('Admitted', style),
        _th('', style),
      ],
    );
  }

  TableRow _tableRow(BuildContext context, PrisonerModel p) {
    final statusColor = switch (p.status) {
      PrisonerStatus.undertrial  => AppTheme.warning,
      PrisonerStatus.convicted   => AppTheme.error,
      PrisonerStatus.released    => AppTheme.success,
      PrisonerStatus.bail        => AppTheme.info,
      PrisonerStatus.transferred => AppTheme.primaryNavy,
      PrisonerStatus.acquitted   => AppTheme.success,
    };

    return TableRow(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
      children: [
        _td(Text(p.prisonerId,
            style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppTheme.textSecondary))),
        _td(Text(p.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        _td(Row(children: [
          const Icon(Icons.local_police_outlined,
              size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(p.policeStation,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ])),
        _td(Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4)),
          child: Text(p.status.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor)),
        )),
        _td(Text(p.admissionDate.displayDate,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary))),
        _td(
          TextButton(
            onPressed: () => context.go('/prisoners/${p.id}'),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 30)),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _th(String label, TextStyle style) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm, vertical: Spacing.sm),
        child: Text(label, style: style),
      );

  Widget _td(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm, vertical: 10),
        child: child,
      );
}

// ── Mobile read-only card ─────────────────────────────────────────────────────

class _ReadOnlyCard extends ConsumerWidget {
  final PrisonerModel prisoner;
  const _ReadOnlyCard({required this.prisoner});

  Color get _statusColor => switch (prisoner.status) {
        PrisonerStatus.undertrial  => AppTheme.warning,
        PrisonerStatus.convicted   => AppTheme.error,
        PrisonerStatus.released    => AppTheme.success,
        PrisonerStatus.bail        => AppTheme.info,
        PrisonerStatus.transferred => AppTheme.primaryNavy,
        PrisonerStatus.acquitted   => AppTheme.success,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      color: AppTheme.surfaceWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => context.go('/prisoners/${prisoner.id}'),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID + READ ONLY badge + status
              Row(children: [
                Text(prisoner.prisonerId,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textSecondary)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.4)),
                  ),
                  child: const Text('READ ONLY',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                          letterSpacing: 0.3)),
                ),
                const Spacer(),
                StatusBadge(
                    label: prisoner.status.label, color: _statusColor),
              ]),
              const SizedBox(height: 6),
              Text(
                prisoner.name,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.local_police_outlined,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    prisoner.policeStation,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // View-only action
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Details',
                      style: TextStyle(fontSize: 12)),
                  onPressed: () => context.go('/prisoners/${prisoner.id}'),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
