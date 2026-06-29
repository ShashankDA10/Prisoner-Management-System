import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class ReleasedScreen extends ConsumerWidget {
  const ReleasedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(releasedDateFilterProvider);
    final prisoners = ref.watch(releasedPrisonersProvider);

    return PageWrapper(
      title: 'Released Prisoners',
      subtitle: 'Records of released and bailed prisoners',
      actions: [
        _FilterButtons(current: filter, onChanged: (f) => ref.read(releasedDateFilterProvider.notifier).state = f),
      ],
      child: prisoners.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (list) {
          if (list.isEmpty) return const EmptyState(title: 'No releases found', subtitle: 'No prisoners released in this period.', icon: Icons.logout_outlined);
          return Container(
            decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Prisoner ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Release Date')),
                        DataColumn(label: Text('Release Reason')),
                        DataColumn(label: Text('Bail Status')),
                        DataColumn(label: Text('Prison')),
                      ],
                      rows: list.map((p) => DataRow(
                        onSelectChanged: (_) => context.go('/prisoners/${p.id}'),
                        cells: [
                          DataCell(Text(p.prisonerId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                          DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(p.releaseDate?.displayDate ?? '—')),
                          DataCell(Text(p.releaseReason?.label ?? '—')),
                          DataCell(StatusBadge(
                            label: p.status == PrisonerStatus.bail ? 'On Bail' : 'Released',
                            color: p.status == PrisonerStatus.bail ? AppTheme.info : AppTheme.success,
                          )),
                          DataCell(Text(p.prisonName)),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterButtons extends StatelessWidget {
  final DateFilter current;
  final void Function(DateFilter) onChanged;
  const _FilterButtons({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: DateFilter.values.where((f) => f != DateFilter.custom).map((f) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: current == f
          ? ElevatedButton(onPressed: () {}, child: Text(f.label, style: const TextStyle(fontSize: 12)))
          : OutlinedButton(onPressed: () => onChanged(f), child: Text(f.label, style: const TextStyle(fontSize: 12))),
    )).toList());
  }
}
