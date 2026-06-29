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

class AdmittedScreen extends ConsumerWidget {
  const AdmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return isMobile ? const _AdmittedMobile() : const _AdmittedDesktop();
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _AdmittedDesktop extends ConsumerWidget {
  const _AdmittedDesktop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(admittedDateFilterProvider);
    final prisoners = ref.watch(admittedPrisonersProvider);

    return PageWrapper(
      title: 'Admitted Prisoners',
      subtitle: 'Prisoners admitted by date range',
      actions: [
        _FilterRow(current: filter, onChanged: (f) => ref.read(admittedDateFilterProvider.notifier).state = f),
      ],
      child: prisoners.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No admissions found',
              subtitle: 'No prisoners admitted in this period.',
              icon: Icons.login_outlined,
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
                        DataColumn(label: Text('Prison')),
                        DataColumn(label: Text('Admission Date')),
                        DataColumn(label: Text('Police Station')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: list.map((p) => DataRow(
                        onSelectChanged: (_) => context.go('/prisoners/${p.id}'),
                        cells: [
                          DataCell(Text(p.prisonerId,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                          DataCell(Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(p.prisonName)),
                          DataCell(Row(children: [
                            Icon(Icons.calendar_today,
                                size: 12,
                                color: p.admissionDate.isToday
                                    ? AppTheme.success
                                    : AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(p.admissionDate.displayDate,
                                style: TextStyle(
                                  color: p.admissionDate.isToday ? AppTheme.success : null,
                                  fontWeight: p.admissionDate.isToday
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                )),
                          ])),
                          DataCell(Text(p.policeStation)),
                          DataCell(StatusBadge(
                            label: p.status.label,
                            color: p.status == PrisonerStatus.undertrial
                                ? AppTheme.warning
                                : AppTheme.error,
                          )),
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

class _AdmittedMobile extends ConsumerWidget {
  const _AdmittedMobile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter    = ref.watch(admittedDateFilterProvider);
    final prisoners = ref.watch(admittedPrisonersProvider);

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
                    'Admitted Prisoners',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  // Date-range filter chips
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
                                      .read(admittedDateFilterProvider.notifier)
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

            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: prisoners.when(
                loading: () => const LoadingState(),
                error: (e, _) => ErrorState(message: e.toString()),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      title: 'No admissions found',
                      subtitle: 'No prisoners admitted in this period.',
                      icon: Icons.login_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (ctx, i) =>
                        _AdmittedCard(prisoner: list[i]),
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

class _AdmittedCard extends StatelessWidget {
  final PrisonerModel prisoner;
  const _AdmittedCard({required this.prisoner});

  @override
  Widget build(BuildContext context) {
    final isToday = prisoner.admissionDate.isToday;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: isToday
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.borderLight,
        ),
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
              // ID + status row
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
                  label: prisoner.status.label,
                  color: prisoner.status == PrisonerStatus.undertrial
                      ? AppTheme.warning
                      : AppTheme.error,
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
              const SizedBox(height: 4),
              // Date
              Row(children: [
                Icon(Icons.calendar_today,
                    size: 13,
                    color: isToday ? AppTheme.success : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  isToday
                      ? 'Admitted Today'
                      : prisoner.admissionDate.displayDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? AppTheme.success : AppTheme.textSecondary,
                    fontWeight:
                        isToday ? FontWeight.w600 : FontWeight.w400,
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

// ── Shared filter row (desktop only) ─────────────────────────────────────────

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
