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

class ReleasedScreen extends ConsumerWidget {
  const ReleasedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return isMobile ? const _ReleasedMobile() : const _ReleasedDesktop();
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _ReleasedDesktop extends ConsumerWidget {
  const _ReleasedDesktop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(releasedDateFilterProvider);
    final prisoners = ref.watch(releasedPrisonersProvider);

    return PageWrapper(
      title: 'Released Prisoners',
      subtitle: 'Records of released and bailed prisoners',
      actions: [
        _FilterRow(
          current: filter,
          onChanged: (f) =>
              ref.read(releasedDateFilterProvider.notifier).state = f,
        ),
      ],
      child: prisoners.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No releases found',
              subtitle: 'No prisoners released in this period.',
              icon: Icons.logout_outlined,
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
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
                          DataCell(Text(p.prisonerId,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12))),
                          DataCell(Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(p.releaseDate?.displayDate ?? '—')),
                          DataCell(Text(p.releaseReason?.label ?? '—')),
                          DataCell(StatusBadge(
                            label: p.status == PrisonerStatus.bail
                                ? 'On Bail'
                                : 'Released',
                            color: p.status == PrisonerStatus.bail
                                ? AppTheme.info
                                : AppTheme.success,
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

// ── Mobile ────────────────────────────────────────────────────────────────────

class _ReleasedMobile extends ConsumerWidget {
  const _ReleasedMobile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(releasedDateFilterProvider);
    final prisoners = ref.watch(releasedPrisonersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title bar ─────────────────────────────────────────────────────
            Container(
              color: AppTheme.surfaceWhite,
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.md, Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Released Prisoners',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: DateFilter.values
                          .where((f) => f != DateFilter.custom)
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(f.label,
                                      style: const TextStyle(fontSize: 12)),
                                  selected: filter == f,
                                  onSelected: (_) => ref
                                      .read(releasedDateFilterProvider.notifier)
                                      .state = f,
                                  selectedColor: AppTheme.primaryNavy,
                                  labelStyle: TextStyle(
                                    color: filter == f
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────────────────
            Expanded(
              child: prisoners.when(
                loading: () => const LoadingState(),
                error: (e, _) => ErrorState(message: e.toString()),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      title: 'No releases found',
                      subtitle: 'No prisoners released in this period.',
                      icon: Icons.logout_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (ctx, i) =>
                        _ReleasedCard(prisoner: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleasedCard extends StatelessWidget {
  final PrisonerModel prisoner;
  const _ReleasedCard({required this.prisoner});

  @override
  Widget build(BuildContext context) {
    final onBail = prisoner.status == PrisonerStatus.bail;
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
              // ID + badge
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
                  label: onBail ? 'On Bail' : 'Released',
                  color: onBail ? AppTheme.info : AppTheme.success,
                ),
              ]),
              const SizedBox(height: 6),
              // Name
              Text(
                prisoner.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              // Release date + reason
              Row(children: [
                const Icon(Icons.event_available_outlined,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  prisoner.releaseDate?.displayDate ?? 'Date not recorded',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (prisoner.releaseReason != null) ...[
                  const SizedBox(width: 8),
                  const Text('·',
                      style: TextStyle(color: AppTheme.textDisabled)),
                  const SizedBox(width: 8),
                  Text(
                    prisoner.releaseReason!.label,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              // Prison
              Row(children: [
                const Icon(Icons.home_work_outlined,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    prisoner.prisonName,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared filter row (desktop) ───────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final DateFilter current;
  final void Function(DateFilter) onChanged;
  const _FilterRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DateFilter.values
          .where((f) => f != DateFilter.custom)
          .map((f) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: current == f
                    ? ElevatedButton(
                        onPressed: () {},
                        child: Text(f.label,
                            style: const TextStyle(fontSize: 12)))
                    : OutlinedButton(
                        onPressed: () => onChanged(f),
                        child: Text(f.label,
                            style: const TextStyle(fontSize: 12))),
              ))
          .toList(),
    );
  }
}
