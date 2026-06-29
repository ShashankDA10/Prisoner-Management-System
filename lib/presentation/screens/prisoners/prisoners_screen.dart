import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/prisoner_model.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';
import 'excel_import_dialog.dart';
import 'widgets/prisoner_table.dart';

class PrisonersScreen extends ConsumerWidget {
  const PrisonersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return isMobile ? const _PrisonersMobile() : const _PrisonersDesktop();
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _PrisonersDesktop extends ConsumerWidget {
  const _PrisonersDesktop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prisonersAsync = ref.watch(filteredPrisonersProvider);
    final stationFilter  = ref.watch(stationFilterProvider);

    return PageWrapper(
      title: 'Prisoner Records',
      subtitle: 'Manage and view all prisoner entries',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file_outlined, size: 16),
          label: const Text('Import Excel'),
          onPressed: () => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const ExcelImportDialog(),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Prisoner'),
          onPressed: () => context.go(Routes.prisonerAdd),
        ),
      ],
      child: Column(children: [
        _DesktopFilterBar(),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: prisonersAsync.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(message: e.toString()),
            data: (all) {
              final prisoners = stationFilter != null
                  ? all
                      .where((p) =>
                          p.policeStation.trim().toLowerCase() ==
                          stationFilter.trim().toLowerCase())
                      .toList()
                  : all;
              return prisoners.isEmpty
                  ? EmptyState(
                      title: 'No records found',
                      subtitle: stationFilter != null
                          ? 'No prisoners from $stationFilter.'
                          : 'Add a prisoner or import from Excel.',
                      icon: Icons.people_outline,
                      action: stationFilter != null
                          ? TextButton.icon(
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text('Clear station filter'),
                              onPressed: () => ref
                                  .read(stationFilterProvider.notifier)
                                  .state = null,
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Prisoner'),
                              onPressed: () => context.go(Routes.prisonerAdd),
                            ),
                    )
                  : PrisonerTable(prisoners: prisoners);
            },
          ),
        ),
      ]),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

class _PrisonersMobile extends ConsumerWidget {
  const _PrisonersMobile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prisonersAsync = ref.watch(filteredPrisonersProvider);
    final stationFilter  = ref.watch(stationFilterProvider);
    final statusFilter   = ref.watch(statusFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      // FAB for the primary action so screen real estate is not wasted.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.prisonerAdd),
        backgroundColor: AppTheme.primaryNavy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title bar ─────────────────────────────────────────────────────
            Container(
              color: AppTheme.surfaceWhite,
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.sm, Spacing.sm),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Prisoner Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file_outlined,
                        color: AppTheme.primaryNavy),
                    tooltip: 'Import Excel',
                    onPressed: () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const ExcelImportDialog(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Status filter chips ───────────────────────────────────────────
            Container(
              color: AppTheme.surfaceWhite,
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, 0, Spacing.md, Spacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: statusFilter == null,
                      onTap: () => ref
                          .read(statusFilterProvider.notifier)
                          .state = null,
                    ),
                    const SizedBox(width: 6),
                    ...PrisonerStatus.values.map((s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterChip(
                            label: s.label,
                            selected: statusFilter == s,
                            onTap: () => ref
                                .read(statusFilterProvider.notifier)
                                .state = statusFilter == s ? null : s,
                          ),
                        )),
                  ],
                ),
              ),
            ),

            // Station filter banner (if active)
            if (stationFilter != null)
              Container(
                color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md, vertical: Spacing.xs),
                child: Row(children: [
                  const Icon(Icons.local_police_outlined,
                      size: 14, color: AppTheme.primaryNavy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Filtered: $stationFilter',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.primaryNavy),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(stationFilterProvider.notifier).state = null,
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ]),
              ),

            // ── Card list ─────────────────────────────────────────────────────
            Expanded(
              child: prisonersAsync.when(
                loading: () => const LoadingState(),
                error: (e, _) => ErrorState(message: e.toString()),
                data: (all) {
                  final prisoners = stationFilter != null
                      ? all
                          .where((p) =>
                              p.policeStation.trim().toLowerCase() ==
                              stationFilter.trim().toLowerCase())
                          .toList()
                      : all;
                  if (prisoners.isEmpty) {
                    return EmptyState(
                      title: 'No records found',
                      subtitle: stationFilter != null
                          ? 'No prisoners from $stationFilter.'
                          : 'Add a prisoner to get started.',
                      icon: Icons.people_outline,
                    );
                  }
                  return _PrisonerCardList(prisoners: prisoners);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile card list ─────────────────────────────────────────────────────────

class _PrisonerCardList extends ConsumerStatefulWidget {
  final List<PrisonerModel> prisoners;
  const _PrisonerCardList({required this.prisoners});

  @override
  ConsumerState<_PrisonerCardList> createState() => _PrisonerCardListState();
}

class _PrisonerCardListState extends ConsumerState<_PrisonerCardList> {
  static const _pageSize = 20;
  int _page = 0;

  @override
  void didUpdateWidget(_PrisonerCardList old) {
    super.didUpdateWidget(old);
    if (old.prisoners != widget.prisoners) _page = 0;
  }

  List<PrisonerModel> get _paged {
    final start = _page * _pageSize;
    if (start >= widget.prisoners.length) return [];
    return widget.prisoners.sublist(
        start, (start + _pageSize).clamp(0, widget.prisoners.length));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.prisoners.length;
    final pages = (total / _pageSize).ceil();

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 80),
            itemCount: _paged.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
            itemBuilder: (ctx, i) => _PrisonerCard(prisoner: _paged[i]),
          ),
        ),
        // Pagination strip
        if (pages > 1)
          Container(
            color: AppTheme.surfaceWhite,
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm),
            child: Row(children: [
              Text(
                '${(_page * _pageSize + 1).clamp(1, total)}–'
                '${((_page + 1) * _pageSize).clamp(0, total)} of $total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    _page > 0 ? () => setState(() => _page--) : null,
              ),
              Text('${_page + 1}/$pages',
                  style: Theme.of(context).textTheme.bodySmall),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _page < pages - 1
                    ? () => setState(() => _page++)
                    : null,
              ),
            ]),
          ),
      ],
    );
  }
}

class _PrisonerCard extends ConsumerWidget {
  final PrisonerModel prisoner;
  const _PrisonerCard({required this.prisoner});

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
              // ── Header row: ID + status badge ─────────────────────────────
              Row(children: [
                Text(
                  prisoner.prisonerId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                StatusBadge(
                    label: prisoner.status.label, color: _statusColor),
              ]),
              const SizedBox(height: 6),

              // ── Name ───────────────────────────────────────────────────────
              Text(
                prisoner.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // ── Meta row: station + admitted date ─────────────────────────
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
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  prisoner.admissionDate.displayDate,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ]),
              const SizedBox(height: 10),

              // ── Action buttons ────────────────────────────────────────────
              Row(children: [
                _ActionBtn(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  onTap: () => context.go('/prisoners/${prisoner.id}'),
                ),
                const SizedBox(width: Spacing.sm),
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => context.go('/prisoners/${prisoner.id}/edit'),
                ),
                const SizedBox(width: Spacing.sm),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppTheme.error,
                  onTap: () => _confirmDelete(context, ref),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
            'Delete "${prisoner.name}" (${prisoner.prisonerId})? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(dlgCtx);
              ref
                  .read(prisonerNotifierProvider.notifier)
                  .deletePrisoner(prisoner.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.primaryNavy,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Shared filter chip (mobile) ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? AppTheme.primaryNavy : AppTheme.surfaceGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryNavy
                : AppTheme.borderMedium,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Desktop filter bar (unchanged from original) ──────────────────────────────

class _DesktopFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query         = ref.watch(searchQueryProvider);
    final statusFilter  = ref.watch(statusFilterProvider);
    final stationFilter = ref.watch(stationFilterProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.filter_list,
                size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            const Text('Status:',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(width: 8),
            ...PrisonerStatus.values.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilterChip(
                    label: Text(s.label),
                    selected: statusFilter == s,
                    onSelected: (v) => ref
                        .read(statusFilterProvider.notifier)
                        .state = v ? s : null,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: statusFilter == s
                          ? Colors.white
                          : AppTheme.textPrimary,
                    ),
                    selectedColor: AppTheme.primaryNavy,
                  ),
                )),
          ]),
        ),
        if (stationFilter != null)
          Chip(
            avatar: const Icon(Icons.local_police_outlined, size: 14),
            label: Text('PS: $stationFilter',
                style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () =>
                ref.read(stationFilterProvider.notifier).state = null,
            backgroundColor:
                AppTheme.primaryNavy.withValues(alpha: 0.08),
          ),
        if (query.isNotEmpty)
          Chip(
            label: Text('Search: "$query"',
                style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () =>
                ref.read(searchQueryProvider.notifier).state = '',
          ),
      ],
    );
  }
}
