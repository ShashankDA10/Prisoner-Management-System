import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/extensions/date_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class AdmittedScreen extends ConsumerWidget {
  const AdmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter   = ref.watch(admittedDateFilterProvider);
    final prisoners = ref.watch(admittedPrisonersProvider);

    return PageWrapper(
      title: 'Admitted Prisoners',
      subtitle: 'Prisoners admitted by date range',
      actions: [
        _FilterButtons(current: filter, onChanged: (f) => ref.read(admittedDateFilterProvider.notifier).state = f),
      ],
      child: prisoners.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(title: 'No admissions found', subtitle: 'No prisoners admitted in this period.', icon: Icons.login_outlined);
          }
          return Container(
            decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
            child: SingleChildScrollView(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Prisoner ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Prison')),
                  DataColumn(label: Text('Admission Date')),
                  DataColumn(label: Text('Police Station')),
                  DataColumn(label: Text('Status')),
                ],
                rows: list.map((p) => DataRow(
                  onSelectChanged: (_) => context.go('/prisoners/${p.id}'),
                  cells: [
                    DataCell(Text(p.prisonerId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(p.prisonName)),
                    DataCell(Row(children: [
                      Icon(Icons.calendar_today, size: 12, color: p.admissionDate.isToday ? AppTheme.success : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(p.admissionDate.displayDate, style: TextStyle(color: p.admissionDate.isToday ? AppTheme.success : null, fontWeight: p.admissionDate.isToday ? FontWeight.w600 : FontWeight.w400)),
                    ])),
                    DataCell(Text(p.policeStation)),
                    DataCell(StatusBadge(label: p.status.label, color: p.status == PrisonerStatus.undertrial ? AppTheme.warning : AppTheme.error)),
                  ],
                )).toList(),
              ),
            )),
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
