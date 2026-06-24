import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId;
  const UserFormScreen({super.key, this.userId});

  @override
  ConsumerState<UserFormScreen> createState() => _State();
}

class _State extends ConsumerState<UserFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _psCtrl    = TextEditingController();
  UserRole _role   = UserRole.si;
  bool _active     = true;
  bool _loading    = false;
  UserModel? _existing;

  bool get _isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final u = await ref.read(userRepositoryProvider).getById(widget.userId!);
    if (u == null || !mounted) { setState(() => _loading = false); return; }
    _existing = u;
    _nameCtrl.text  = u.name;
    _userCtrl.text  = u.username;
    _emailCtrl.text = u.email ?? '';
    _phoneCtrl.text = u.phone ?? '';
    _psCtrl.text    = u.policeStation ?? '';
    _role   = u.role;
    _active = u.isActive;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _passCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password is required for new users'))); return; }
    setState(() => _loading = true);
    final now = DateTime.now();
    final user = UserModel(
      id:            _existing?.id ?? const Uuid().v4(),
      name:          _nameCtrl.text.trim(),
      username:      _userCtrl.text.trim(),
      passwordHash:  _passCtrl.text.isNotEmpty ? UserRepository.hashPassword(_passCtrl.text) : (_existing?.passwordHash ?? ''),
      role:          _role,
      policeStation: _psCtrl.text.trim().isEmpty ? null : _psCtrl.text.trim(),
      email:         _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone:         _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      isActive:      _active,
      createdAt:     _existing?.createdAt ?? now,
      updatedAt:     now,
    );
    if (_isEdit) { await ref.read(userNotifierProvider.notifier).updateUser(user); }
    else         { await ref.read(userNotifierProvider.notifier).addUser(user); }
    if (mounted) context.go(Routes.users);
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: _isEdit ? 'Edit User' : 'Add New User',
      subtitle: 'Manage system user account',
      scrollable: true,
      actions: [
        OutlinedButton(onPressed: () => context.go(Routes.users), child: const Text('Cancel')),
        const SizedBox(width: 10),
        ElevatedButton.icon(icon: const Icon(Icons.save_outlined, size: 16), label: Text(_isEdit ? 'Update' : 'Save'), onPressed: _loading ? null : _save),
      ],
      child: _loading ? const LoadingState() : Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Username *'), validator: (v) => v?.trim().isEmpty == true ? 'Required' : null)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _passCtrl, obscureText: true, decoration: InputDecoration(labelText: _isEdit ? 'New Password (leave blank to keep)' : 'Password *'))),
              const SizedBox(width: 16),
              Expanded(child: DropdownButtonFormField<UserRole>(
                initialValue: _role, decoration: const InputDecoration(labelText: 'Role *'),
                items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                onChanged: (v) => setState(() => _role = v!),
              )),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _psCtrl, decoration: const InputDecoration(labelText: 'Police Station'))),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'))),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Text('Account Active:', style: TextStyle(fontSize: 13)),
              Switch(value: _active, onChanged: (v) => setState(() => _active = v)),
            ]),
          ]),
        ),
      ),
    );
  }
}
