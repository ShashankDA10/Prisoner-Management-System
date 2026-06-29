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
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return isMobile ? const _DashboardMobile() : const _DashboardDesktop();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Desktop layout
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardDesktop extends ConsumerWidget {
  const _DashboardDesktop();

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
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(dashboardStatsProvider),
        ),
        data: (stats) => _DesktopContent(stats: stats),
      ),
    );
  }
}

class _DesktopContent extends StatelessWidget {
  final Map<String, int> stats;
  const _DesktopContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final crossAxisCount = isDesktop ? 4 : 3;

    final cards = _buildCards(stats);

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
            childAspectRatio: isDesktop ? 1.6 : 1.4,
          ),
          itemCount: cards.length,
          itemBuilder: (ctx, i) => StatCard(
            label: cards[i].label, value: cards[i].value,
            icon: cards[i].icon, color: cards[i].color,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        Text('Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.md,
          runSpacing: Spacing.md,
          children: _quickActions(context),
        ),
        const SizedBox(height: Spacing.xl),
        _infoBar(context),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile layout — native-feeling card-per-row design
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardMobile extends ConsumerWidget {
  const _DashboardMobile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: SafeArea(
        child: Column(children: [
          // ── Title bar ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppTheme.surfaceWhite,
            padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.sm, Spacing.md, Spacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryNavy,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(now),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ]),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          Expanded(
            child: statsAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
              data: (stats) => _MobileContent(stats: stats),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MobileContent extends StatelessWidget {
  final Map<String, int> stats;
  const _MobileContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = _buildCards(stats);

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        // ── Stat cards — 2 per row grid ────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: Spacing.sm,
            mainAxisSpacing: Spacing.sm,
            childAspectRatio: 1.6,
          ),
          itemCount: cards.length,
          itemBuilder: (ctx, i) => _MobileStatCard(def: cards[i]),
        ),
        const SizedBox(height: Spacing.lg),

        // ── Quick actions heading ──────────────────────────────────────────
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.sm),

        // ── 2-column action grid ───────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: Spacing.sm,
          mainAxisSpacing: Spacing.sm,
          childAspectRatio: 2.6,
          children: _quickActions(context),
        ),
        const SizedBox(height: Spacing.lg),

        // ── Info banner ───────────────────────────────────────────────────
        _infoBar(context),
        const SizedBox(height: Spacing.xxl),
      ],
    );
  }
}

/// Full-size stat card used on mobile — larger text, fills its cell.
class _MobileStatCard extends StatelessWidget {
  final _CardDef def;
  const _MobileStatCard({required this.def});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: def.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(def.icon, color: def.color, size: 16),
            ),
            const Spacer(),
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                  color: def.color, borderRadius: BorderRadius.circular(2)),
            ),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${def.value}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: def.color,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                def.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _CardDef {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _CardDef(this.label, this.value, this.icon, this.color);
}

List<_CardDef> _buildCards(Map<String, int> stats) => [
  _CardDef('Total Prisoners',    stats['total'] ?? 0,       Icons.groups,                    AppTheme.cardTotal),
  _CardDef('Undertrials',        stats['undertrial'] ?? 0,  Icons.balance,                   AppTheme.cardUndertrial),
  _CardDef('Convicted',          stats['convicted'] ?? 0,   Icons.gavel,                     AppTheme.cardConvicted),
  _CardDef('Admitted Today',     stats['admitted'] ?? 0,    Icons.login,                     AppTheme.cardAdmitted),
  _CardDef('Released',           stats['released'] ?? 0,    Icons.logout,                    AppTheme.cardReleased),
  _CardDef('On Bail',            stats['bail'] ?? 0,        Icons.assignment_turned_in,      AppTheme.cardBail),
  _CardDef('Transferred',        stats['transferred'] ?? 0, Icons.transfer_within_a_station, AppTheme.cardTransfer),
];

List<Widget> _quickActions(BuildContext context) => [
  _QuickActionTile(
    icon: Icons.person_add_outlined,
    label: 'Add Prisoner',
    onTap: () => context.go(Routes.prisonerAdd),
  ),
  _QuickActionTile(
    icon: Icons.search,
    label: 'Search Records',
    onTap: () => context.go(Routes.prisoners),
  ),
  _QuickActionTile(
    icon: Icons.upload_file_outlined,
    label: 'Import Excel',
    onTap: () => context.go('${Routes.prisoners}?import=1'),
  ),
  _QuickActionTile(
    icon: Icons.bar_chart_outlined,
    label: 'View Reports',
    onTap: () => context.go(Routes.reports),
  ),
];

Widget _infoBar(BuildContext context) => Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 16, color: AppTheme.info),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'System connected to cloud backend. Data is shared across all devices in real time.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.info),
          ),
        ),
      ]),
    );

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile(
      {required this.icon, required this.label, required this.onTap});

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
