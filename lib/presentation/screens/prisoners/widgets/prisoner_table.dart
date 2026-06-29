import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/date_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/prisoner_model.dart';
import '../../../providers/prisoner_provider.dart';
import '../../../widgets/common/page_wrapper.dart';

Color _statusColor(PrisonerStatus s) => switch (s) {
  PrisonerStatus.undertrial  => AppTheme.warning,
  PrisonerStatus.convicted   => AppTheme.error,
  PrisonerStatus.released    => AppTheme.success,
  PrisonerStatus.bail        => AppTheme.info,
  PrisonerStatus.transferred => AppTheme.primaryNavy,
  PrisonerStatus.acquitted   => AppTheme.success,
};

class PrisonerTable extends ConsumerStatefulWidget {
  final List<PrisonerModel> prisoners;
  const PrisonerTable({super.key, required this.prisoners});

  @override
  ConsumerState<PrisonerTable> createState() => _PrisonerTableState();
}

class _PrisonerTableState extends ConsumerState<PrisonerTable> {
  int _sortCol = 0;
  bool _sortAsc = true;
  int _page = 0;
  static const _pageSize = 25;

  @override
  void didUpdateWidget(PrisonerTable old) {
    super.didUpdateWidget(old);
    // Reset to first page whenever the list is swapped (e.g. filter change).
    if (old.prisoners != widget.prisoners) _page = 0;
  }

  List<PrisonerModel> get _sorted {
    final list = [...widget.prisoners];
    list.sort((a, b) {
      final cmp = switch (_sortCol) {
        0 => a.prisonerId.compareTo(b.prisonerId),
        1 => a.name.compareTo(b.name),
        2 => a.policeStation.compareTo(b.policeStation),
        3 => a.admissionDate.compareTo(b.admissionDate),
        4 => a.status.name.compareTo(b.status.name),
        _ => 0,
      };
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  List<PrisonerModel> get _paged {
    final s = _sorted;
    final start = _page * _pageSize;
    if (start >= s.length) return [];
    return s.sublist(start, (start + _pageSize).clamp(0, s.length));
  }

  void _sort(int col) {
    setState(() {
      if (_sortCol == col) { _sortAsc = !_sortAsc; } else { _sortCol = col; _sortAsc = true; }
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.prisoners.length;
    final pages = (total / _pageSize).ceil();

    return Column(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortCol,
                sortAscending: _sortAsc,
                columns: [
                  DataColumn(label: const Text('Prisoner ID'), onSort: (i, _) => _sort(0)),
                  DataColumn(label: const Text('Name'),        onSort: (i, _) => _sort(1)),
                  DataColumn(label: const Text('Police Station'), onSort: (i, _) => _sort(2)),
                  const DataColumn(label: Text('Prison')),
                  DataColumn(label: const Text('Admitted'),    onSort: (i, _) => _sort(3)),
                  const DataColumn(label: Text('Sections')),
                  DataColumn(label: const Text('Status'),      onSort: (i, _) => _sort(4)),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: _paged.map((p) => DataRow(
                  onSelectChanged: (_) => context.go('/prisoners/${p.id}'),
                  cells: [
                    DataCell(Text(p.prisonerId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(p.policeStation)),
                    DataCell(Text(p.prisonName, overflow: TextOverflow.ellipsis)),
                    DataCell(Text(p.admissionDate.displayDate)),
                    DataCell(_SectionsCell(ipc: p.ipcSections, bns: p.bnsSections)),
                    DataCell(StatusBadge(label: p.status.label, color: _statusColor(p.status))),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        onPressed: () => context.go('/prisoners/${p.id}'),
                        tooltip: 'View',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => context.go('/prisoners/${p.id}/edit'),
                        tooltip: 'Edit',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                        onPressed: () => _confirmDelete(context, ref, p),
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ])),
                  ],
                )).toList(),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Text(
          'Showing ${(_page * _pageSize + 1).clamp(1, total)}–${((_page + 1) * _pageSize).clamp(0, total)} of $total records',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 0 ? () => setState(() => _page--) : null),
        Text('${_page + 1} / $pages', style: Theme.of(context).textTheme.bodySmall),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < pages - 1 ? () => setState(() => _page++) : null),
      ]),
    ]);
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, PrisonerModel p) {
    showDialog(context: ctx, builder: (dlgCtx) => AlertDialog(
      title: const Text('Delete Record'),
      content: Text('Delete "${p.name}" (${p.prisonerId})? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          onPressed: () {
            Navigator.pop(dlgCtx);
            ref.read(prisonerNotifierProvider.notifier).deletePrisoner(p.id);
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}

class _SectionsCell extends StatelessWidget {
  final List<String> ipc;
  final List<String> bns;
  const _SectionsCell({required this.ipc, required this.bns});

  @override
  Widget build(BuildContext context) {
    final all = [
      ...ipc.map((s) => SectionChip(sectionNumber: s, description: '', isBns: false)),
      ...bns.map((s) => SectionChip(sectionNumber: s, description: '', isBns: true)),
    ];
    if (all.isEmpty) return const Text('—', style: TextStyle(color: AppTheme.textDisabled));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...all.take(3),
        if (all.length > 3) Text(' +${all.length - 3}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
