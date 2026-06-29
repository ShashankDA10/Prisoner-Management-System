import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';
import 'widgets/prisoner_table.dart';
import 'excel_import_dialog.dart';

class PrisonersScreen extends ConsumerWidget {
  const PrisonersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prisonersAsync  = ref.watch(filteredPrisonersProvider);
    final stationFilter   = ref.watch(stationFilterProvider);

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
        _FilterBar(),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: prisonersAsync.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(message: e.toString()),
            data: (all) {
              // Apply station filter synchronously so it takes effect immediately
              // even if the FutureProvider hasn't re-run yet after navigation.
              final prisoners = stationFilter != null
                  ? all.where((p) =>
                      p.policeStation.trim().toLowerCase() ==
                      stationFilter.trim().toLowerCase()).toList()
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
                              onPressed: () => ref.read(stationFilterProvider.notifier).state = null,
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

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query        = ref.watch(searchQueryProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final stationFilter = ref.watch(stationFilterProvider);

    return Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.filter_list, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          const Text('Status:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          ...PrisonerStatus.values.map((s) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilterChip(
              label: Text(s.label),
              selected: statusFilter == s,
              onSelected: (v) => ref.read(statusFilterProvider.notifier).state = v ? s : null,
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(fontSize: 11, color: statusFilter == s ? Colors.white : AppTheme.textPrimary),
              selectedColor: AppTheme.primaryNavy,
            ),
          )),
        ]),
      ),
      if (stationFilter != null)
        Chip(
          avatar: const Icon(Icons.local_police_outlined, size: 14),
          label: Text('PS: $stationFilter', style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => ref.read(stationFilterProvider.notifier).state = null,
          backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
        ),
      if (query.isNotEmpty)
        Chip(
          label: Text('Search: "$query"', style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => ref.read(searchQueryProvider.notifier).state = '',
        ),
    ]);
  }
}
