import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final now = DateTime.now();

    return PageWrapper(
      title: 'Dashboard',
      subtitle: 'Overview — ${DateFormat('EEEE, d MMMM yyyy').format(now)}',
      scrollable: true,
      child: statsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(dashboardStatsProvider)),
        data: (stats) => _DashboardContent(stats: stats),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, int> stats;
  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isTablet  = width >= 600;
    final isMobile  = !isTablet;

    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    // Mobile: landscape-ish cards (1.5) so the icon + value + label all fit comfortably.
    final childAspectRatio = isDesktop ? 1.6 : (isTablet ? 1.4 : 1.5);
    final gridSpacing = isMobile ? Spacing.sm : Spacing.md;

    final cards = [
      _CardDef('Total Prisoners',    stats['total'] ?? 0,       Icons.groups,                    AppTheme.cardTotal),
      _CardDef('Undertrials',        stats['undertrial'] ?? 0,  Icons.balance,                   AppTheme.cardUndertrial),
      _CardDef('Convicted',          stats['convicted'] ?? 0,   Icons.gavel,                     AppTheme.cardConvicted),
      _CardDef('Admitted Today',     stats['admitted'] ?? 0,    Icons.login,                     AppTheme.cardAdmitted),
      _CardDef('Released',           stats['released'] ?? 0,    Icons.logout,                    AppTheme.cardReleased),
      _CardDef('On Bail',            stats['bail'] ?? 0,        Icons.assignment_turned_in,      AppTheme.cardBail),
      _CardDef('Transferred',        stats['transferred'] ?? 0, Icons.transfer_within_a_station, AppTheme.cardTransfer),
    ];

    final quickActions = [
      _ActionDef(Icons.person_add_outlined,  'Add Prisoner',    () => context.go(Routes.prisonerAdd)),
      _ActionDef(Icons.search,               'Search Records',  () => context.go(Routes.prisoners)),
      _ActionDef(Icons.upload_file_outlined, 'Import Excel',    () => context.go('${Routes.prisoners}?import=1')),
      _ActionDef(Icons.bar_chart_outlined,   'View Reports',    () => context.go(Routes.reports)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats grid ────────────────────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: cards.length,
          itemBuilder: (ctx, i) {
            final c = cards[i];
            return StatCard(label: c.label, value: c.value, icon: c.icon, color: c.color);
          },
        ),

        SizedBox(height: isMobile ? Spacing.lg : Spacing.xl),

        // ── Quick actions ─────────────────────────────────────────────────────
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: Spacing.md),

        if (isMobile)
          // 2-column grid so each action card stretches to fill its cell.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: Spacing.sm,
            mainAxisSpacing: Spacing.sm,
            childAspectRatio: 3.0,
            children: quickActions
                .map((a) => _QuickAction(icon: a.icon, label: a.label, onTap: a.onTap))
                .toList(),
          )
        else
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: quickActions
                .map((a) => _QuickAction(icon: a.icon, label: a.label, onTap: a.onTap))
                .toList(),
          ),

        SizedBox(height: isMobile ? Spacing.lg : Spacing.xl),

        // ── Info banner ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: AppTheme.info.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 16, color: AppTheme.info),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'System connected to cloud backend. Data is shared across all devices in real time.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.info),
            )),
          ]),
        ),
      ],
    );
  }
}

// ── Data helpers ──────────────────────────────────────────────────────────────

class _CardDef {
  final String label; final int value; final IconData icon; final Color color;
  const _CardDef(this.label, this.value, this.icon, this.color);
}

class _ActionDef {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ActionDef(this.icon, this.label, this.onTap);
}

// ── Quick-action tile ─────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryNavy),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
