import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/section_model.dart';
import '../../../providers/section_provider.dart';
import '../../../widgets/common/page_wrapper.dart';

class SectionPicker extends ConsumerStatefulWidget {
  final List<String> selectedIpc;
  final List<String> selectedBns;
  final void Function(List<String> ipc, List<String> bns) onChanged;

  const SectionPicker({
    super.key,
    required this.selectedIpc,
    required this.selectedBns,
    required this.onChanged,
  });

  @override
  ConsumerState<SectionPicker> createState() => _SectionPickerState();
}

class _SectionPickerState extends ConsumerState<SectionPicker> {
  final _searchCtrl = TextEditingController();
  LawType? _lawType;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _toggle(SectionModel section) {
    final ipc = List<String>.from(widget.selectedIpc);
    final bns = List<String>.from(widget.selectedBns);
    if (section.lawType == LawType.ipc) {
      ipc.contains(section.sectionNumber) ? ipc.remove(section.sectionNumber) : ipc.add(section.sectionNumber);
    } else {
      bns.contains(section.sectionNumber) ? bns.remove(section.sectionNumber) : bns.add(section.sectionNumber);
    }
    widget.onChanged(ipc, bns);
  }

  bool _isSelected(SectionModel s) {
    return s.lawType == LawType.ipc
        ? widget.selectedIpc.contains(s.sectionNumber)
        : widget.selectedBns.contains(s.sectionNumber);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(sectionSearchResultsProvider);
    final allSelected = [...widget.selectedIpc.map((n) => (n, false)), ...widget.selectedBns.map((n) => (n, true))];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Selected chips
      if (allSelected.isNotEmpty) ...[
        Wrap(spacing: 6, runSpacing: 6, children: allSelected.map((s) {
          return Chip(
            label: Text('§${s.$1} ${s.$2 ? "(BNS)" : "(IPC)"}', style: const TextStyle(fontSize: 11)),
            backgroundColor: s.$2 ? AppTheme.info.withOpacity(0.1) : AppTheme.primaryNavy.withOpacity(0.1),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              final ipc = List<String>.from(widget.selectedIpc);
              final bns = List<String>.from(widget.selectedBns);
              if (s.$2) {
                bns.remove(s.$1);
              } else {
                ipc.remove(s.$1);
              }
              widget.onChanged(ipc, bns);
            },
          );
        }).toList()),
        const SizedBox(height: 12),
      ],

      // Search + filter
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _searchCtrl,
            onChanged: (v) {
              ref.read(sectionSearchQueryProvider.notifier).state = v;
              ref.read(sectionLawTypeFilterProvider.notifier).state = _lawType;
            },
            decoration: const InputDecoration(
              hintText: 'Search section number or keyword (e.g. 302, murder, dacoity)',
              prefixIcon: Icon(Icons.search, size: 16),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SegmentedButton<LawType?>(
          segments: const [
            ButtonSegment(value: null, label: Text('All')),
            ButtonSegment(value: LawType.ipc, label: Text('IPC')),
            ButtonSegment(value: LawType.bns, label: Text('BNS')),
          ],
          selected: {_lawType},
          onSelectionChanged: (s) {
            setState(() => _lawType = s.first);
            ref.read(sectionLawTypeFilterProvider.notifier).state = _lawType;
          },
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ]),
      const SizedBox(height: 8),

      // Results
      Container(
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: results.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: e.toString()),
          data: (sections) {
            if (sections.isEmpty) {
              return const Center(child: Text('No sections found', style: TextStyle(color: AppTheme.textDisabled, fontSize: 13)));
            }
            return ListView.builder(
              itemCount: sections.length,
              itemExtent: 44,
              itemBuilder: (_, i) {
                final s = sections[i];
                final selected = _isSelected(s);
                return InkWell(
                  onTap: () => _toggle(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(children: [
                      Checkbox(value: selected, onChanged: (_) => _toggle(s), visualDensity: VisualDensity.compact),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.lawType == LawType.bns ? AppTheme.info.withOpacity(0.1) : AppTheme.primaryNavy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '§${s.sectionNumber} ${s.lawType.label}',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: s.lawType == LawType.bns ? AppTheme.info : AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.description, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
