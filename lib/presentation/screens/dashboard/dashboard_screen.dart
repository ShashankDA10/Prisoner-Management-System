import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authProvider);
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
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    final cards = [
      _CardDef('Total Prisoners',    stats['total'] ?? 0,       Icons.groups,           AppTheme.cardTotal),
      _CardDef('Undertrials',        stats['undertrial'] ?? 0,  Icons.balance,          AppTheme.cardUndertrial),
      _CardDef('Convicted',          stats['convicted'] ?? 0,   Icons.gavel,            AppTheme.cardConvicted),
      _CardDef('Admitted Today',     stats['admitted'] ?? 0,    Icons.login,            AppTheme.cardAdmitted),
      _CardDef('Released',           stats['released'] ?? 0,    Icons.logout,           AppTheme.cardReleased),
      _CardDef('On Bail',            stats['bail'] ?? 0,        Icons.assignment_turned_in, AppTheme.cardBail),
      _CardDef('Transferred',        stats['transferred'] ?? 0, Icons.transfer_within_a_station, AppTheme.cardTransfer),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: Spacing.md,
            mainAxisSpacing: Spacing.md,
            childAspectRatio: isDesktop ? 1.6 : (isTablet ? 1.4 : 1.1),
          ),
          itemCount: cards.length,
          itemBuilder: (ctx, i) {
            final c = cards[i];
            return StatCard(
              label: c.label,
              value: c.value,
              icon: c.icon,
              color: c.color,
            );
          },
        ),
        const SizedBox(height: Spacing.xl),

        // Quick actions
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: Spacing.md),
        Wrap(spacing: Spacing.md, runSpacing: Spacing.md, children: [
          _QuickAction(
            icon: Icons.person_add_outlined,
            label: 'Add Prisoner',
            onTap: () => context.go(Routes.prisonerAdd),
          ),
          _QuickAction(
            icon: Icons.search,
            label: 'Search Records',
            onTap: () => context.go(Routes.prisoners),
          ),
          _QuickAction(
            icon: Icons.upload_file_outlined,
            label: 'Import Excel',
            onTap: () => context.go('${Routes.prisoners}?import=1'),
          ),
          _QuickAction(
            icon: Icons.bar_chart_outlined,
            label: 'View Reports',
            onTap: () => context.go(Routes.reports),
          ),
        ]),

        const SizedBox(height: Spacing.xl),
        // Info bar
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.06),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: AppTheme.info.withOpacity(0.2)),
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

class _CardDef {
  final String label; final int value; final IconData icon; final Color color;
  const _CardDef(this.label, this.value, this.icon, this.color);
}

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: AppTheme.primaryNavy),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ]),
      ),
    );
  }
}
