import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/auth_provider.dart';
import '../common/pums_header.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final UserRole? minRole; // null = all roles

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.minRole,
  });
}

const _navItems = [
  _NavItem(label: 'Dashboard',  icon: Icons.space_dashboard_outlined,  activeIcon: Icons.space_dashboard,    route: Routes.dashboard),
  _NavItem(label: 'Prisoners',  icon: Icons.people_outlined,            activeIcon: Icons.people,             route: Routes.prisoners),
  _NavItem(label: 'Admitted',   icon: Icons.login_outlined,             activeIcon: Icons.login,              route: Routes.admitted),
  _NavItem(label: 'Released',   icon: Icons.logout_outlined,            activeIcon: Icons.logout,             route: Routes.released),
  _NavItem(label: 'Reports',    icon: Icons.bar_chart_outlined,         activeIcon: Icons.bar_chart,          route: Routes.reports),
  _NavItem(label: 'IPC/BNS',   icon: Icons.gavel_outlined,             activeIcon: Icons.gavel,              route: Routes.ipcLookup),
  _NavItem(label: 'Users',      icon: Icons.manage_accounts_outlined,   activeIcon: Icons.manage_accounts,    route: Routes.users, minRole: UserRole.admin),
  _NavItem(label: 'Settings',   icon: Icons.settings_outlined,          activeIcon: Icons.settings,           route: Routes.settings),
];

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    final currentUser = ref.watch(authProvider);
    final location    = GoRouterState.of(context).matchedLocation;

    if (isDesktop) {
      return Scaffold(
        body: Column(children: [
          const PumsHeader(),
          Expanded(
            child: Row(children: [
              _SidebarNav(location: location, currentRole: currentUser.value?.role),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ]),
          ),
        ]),
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: PumsHeader(compact: true),
      ),
      drawer: Drawer(
        child: _SidebarNav(location: location, currentRole: currentUser.value?.role, inDrawer: true),
      ),
      body: child,
      bottomNavigationBar: _BottomNav(location: location, currentRole: currentUser.value?.role),
    );
  }
}

// ── Sidebar ─────────────────────────────────────────────────────────────────

class _SidebarNav extends ConsumerWidget {
  final String location;
  final UserRole? currentRole;
  final bool inDrawer;

  const _SidebarNav({
    required this.location,
    required this.currentRole,
    this.inDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: inDrawer ? null : 220,
      color: AppTheme.sidebarBg,
      child: Column(children: [
        if (inDrawer) ...[
          const SizedBox(height: 48),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppConstants.appFullName,
              style: TextStyle(
                color: AppTheme.textOnDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const Divider(color: AppTheme.sidebarHover, height: 1),
        ],
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _navItems
                .where((item) =>
                    item.minRole == null ||
                    (currentRole != null &&
                        _roleLevel(currentRole!) >= _roleLevel(item.minRole!)))
                .map((item) {
              final isActive = location.startsWith(item.route);
              return _SidebarItem(item: item, isActive: isActive, inDrawer: inDrawer);
            }).toList(),
          ),
        ),
        const Divider(color: AppTheme.sidebarHover, height: 1),
        _SidebarFooter(ref: ref),
      ]),
    );
  }

  int _roleLevel(UserRole r) {
    return switch (r) {
      UserRole.admin         => 7,
      UserRole.commissioner  => 6,
      UserRole.dcpSp         => 5,
      UserRole.acpDySp       => 4,
      UserRole.inspector     => 3,
      UserRole.si            => 2,
      UserRole.prisonOfficer => 1,
    };
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool inDrawer;

  const _SidebarItem({required this.item, required this.isActive, required this.inDrawer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? AppTheme.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: AppTheme.sidebarHover,
          onTap: () {
            if (inDrawer) Navigator.of(context).pop();
            context.go(item.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 20,
                color: isActive ? AppTheme.sidebarIconActive : AppTheme.sidebarText,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: isActive ? AppTheme.sidebarTextActive : AppTheme.sidebarText,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13.5,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Container(
                  width: 3, height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.sidebarIconActive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final WidgetRef ref;
  const _SidebarFooter({required this.ref});

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).value;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryNavy,
          child: Text(
            (user?.name ?? '').isNotEmpty ? user!.name[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              user?.name ?? 'Unknown',
              style: const TextStyle(color: AppTheme.sidebarTextActive, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            Text(
              user?.role.label ?? '',
              style: const TextStyle(color: AppTheme.sidebarText, fontSize: 11),
            ),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppTheme.sidebarText, size: 18),
          onPressed: () => ref.read(authProvider.notifier).logout(),
          tooltip: 'Logout',
        ),
      ]),
    );
  }
}

// ── Bottom Nav (mobile) ──────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final String location;
  final UserRole? currentRole;

  const _BottomNav({required this.location, required this.currentRole});

  @override
  Widget build(BuildContext context) {
    final visibleItems = _navItems.where((i) =>
        i.minRole == null).take(5).toList();

    final currentIndex = visibleItems.indexWhere(
        (i) => location.startsWith(i.route));

    return BottomNavigationBar(
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.primaryDark,
      selectedItemColor: AppTheme.accent,
      unselectedItemColor: AppTheme.sidebarText,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      onTap: (i) => context.go(visibleItems[i].route),
      items: visibleItems.map((item) {
        final isActive = location.startsWith(item.route);
        return BottomNavigationBarItem(
          icon: Icon(isActive ? item.activeIcon : item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }
}
