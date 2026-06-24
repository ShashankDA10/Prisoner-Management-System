import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return PageWrapper(
      title: 'User Management',
      subtitle: 'Manage system users and role-based access',
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add_outlined, size: 16),
          label: const Text('Add User'),
          onPressed: () => context.go(Routes.userAdd),
        ),
      ],
      child: usersAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (users) => users.isEmpty
            ? const EmptyState(title: 'No users found', icon: Icons.manage_accounts_outlined)
            : Container(
                decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
                child: SingleChildScrollView(child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Police Station')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: users.map((u) => _userRow(context, ref, u)).toList(),
                )),
              ),
      ),
    );
  }

  DataRow _userRow(BuildContext context, WidgetRef ref, UserModel u) {
    return DataRow(cells: [
      DataCell(Row(children: [
        CircleAvatar(radius: 14, backgroundColor: AppTheme.primaryNavy, child: Text(u.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11))),
        const SizedBox(width: 10),
        Text(u.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      ])),
      DataCell(Text(u.username, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppTheme.primaryNavy.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(u.role.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy)),
      )),
      DataCell(Text(u.policeStation ?? '—')),
      DataCell(StatusBadge(label: u.isActive ? 'Active' : 'Inactive', color: u.isActive ? AppTheme.success : AppTheme.error)),
      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => context.go('/users/${u.id}/edit'), tooltip: 'Edit', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
        if (u.id != 'admin-default') IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.error), onPressed: () => _delete(context, ref, u), tooltip: 'Delete', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
      ])),
    ]);
  }

  void _delete(BuildContext ctx, WidgetRef ref, UserModel u) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Delete User'),
      content: Text('Delete user "${u.name}"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () { Navigator.pop(_); ref.read(userNotifierProvider.notifier).deleteUser(u.id); }, child: const Text('Delete')),
      ],
    ));
  }
}
