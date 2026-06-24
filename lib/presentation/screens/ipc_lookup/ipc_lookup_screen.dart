import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/section_model.dart';
import '../../providers/section_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class IpcLookupScreen extends ConsumerWidget {
  const IpcLookupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(sectionSearchResultsProvider);
    final query   = ref.watch(sectionSearchQueryProvider);
    final lawType = ref.watch(sectionLawTypeFilterProvider);

    return PageWrapper(
      title: 'IPC / BNS Section Lookup',
      subtitle: 'Search and reference criminal law sections',
      child: Column(children: [
        // Search bar
        Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => ref.read(sectionSearchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Enter section number(s) or keyword — e.g. 302 420 376 or "murder"',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
                suffixIcon: query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => ref.read(sectionSearchQueryProvider.notifier).state = '') : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<LawType?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All'), icon: Icon(Icons.gavel, size: 14)),
              ButtonSegment(value: LawType.ipc, label: Text('IPC')),
              ButtonSegment(value: LawType.bns, label: Text('BNS')),
            ],
            selected: {lawType},
            onSelectionChanged: (s) => ref.read(sectionLawTypeFilterProvider.notifier).state = s.first,
          ),
        ]),
        const SizedBox(height: Spacing.md),

        // Legend
        Row(children: [
          _legend('IPC — Indian Penal Code 1860 (legacy, applies to pre-July 2024 FIRs)', AppTheme.primaryNavy),
          const SizedBox(width: 16),
          _legend('BNS — Bharatiya Nyaya Sanhita 2023 (applicable from 1 July 2024)', AppTheme.info),
        ]),
        const SizedBox(height: Spacing.md),

        // Results
        Expanded(
          child: results.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(message: e.toString()),
            data: (sections) {
              if (sections.isEmpty) return const EmptyState(title: 'No sections found', subtitle: 'Try a different search term.', icon: Icons.gavel_outlined);
              return Container(
                decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
                child: ListView.separated(
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _SectionRow(section: sections[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _legend(String text, Color color) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(2), border: Border.all(color: color.withOpacity(0.5)))),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
  ]);
}

class _SectionRow extends StatelessWidget {
  final SectionModel section;
  const _SectionRow({required this.section});

  @override
  Widget build(BuildContext context) {
    final isBns = section.lawType == LawType.bns;
    final color = isBns ? AppTheme.info : AppTheme.primaryNavy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section badge
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(children: [
            Text(section.sectionNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            Text(section.lawType.label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ]),
        ),
        const SizedBox(width: Spacing.md),
        // Description
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${section.sectionNumber} – ${section.description}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
          ),
          if (section.category != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.surfaceGrey, borderRadius: BorderRadius.circular(3)),
              child: Text(section.category!, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            ),
          ],
        ])),
      ]),
    );
  }
}
