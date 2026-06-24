import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/sample_data_seeder.dart';
import '../../../data/repositories/prisoner_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prisoner_provider.dart';
import '../../widgets/common/page_wrapper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _State();
}

class _State extends ConsumerState<SettingsScreen> {
  bool _seeding = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return PageWrapper(
      title: 'Settings',
      subtitle: 'Application configuration and data management',
      scrollable: true,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: [
          _card('Logo Branding', [
            _logoRow('Left Logo (Karnataka State Police)', AppConstants.prefLeftLogoPath),
            const Divider(height: 20),
            _logoRow('Center Logo (Government of Karnataka)', AppConstants.prefCenterLogoPath),
            const Divider(height: 20),
            _logoRow('Right Logo (Bangalore City Police)', AppConstants.prefRightLogoPath),
          ]),
          const SizedBox(height: 16),
          _card('System Information', [
            _infoRow('Application', AppConstants.appFullName),
            _infoRow('Version', AppConstants.appVersion),
            _infoRow('Organisation', AppConstants.orgName),
            _infoRow('Default Database', AppConstants.dbName),
            _infoRow('Logged In As', '${user.value?.name ?? "—"} (${user.value?.role.label ?? "—"})'),
          ]),
        ])),
        const SizedBox(width: 16),
        SizedBox(width: 300, child: Column(children: [
          _card('Data Management', [
            _actionBtn('Load Sample Data', Icons.dataset_outlined, AppTheme.info, _seedSampleData),
            const SizedBox(height: 8),
            _actionBtn('Backup Database', Icons.backup_outlined, AppTheme.success, _backup),
            const SizedBox(height: 8),
            _actionBtn('Restore Database', Icons.restore_outlined, AppTheme.warning, _restore),
          ]),
          const SizedBox(height: 16),
          _card('Session', [
            _actionBtn('Sign Out', Icons.logout_outlined, AppTheme.error, () => ref.read(authProvider.notifier).logout()),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.info.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.info.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Row(children: [Icon(Icons.info_outline, size: 14, color: AppTheme.info), SizedBox(width: 6), Text('Migration Ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.info))]),
              SizedBox(height: 8),
              Text('This system uses a database abstraction layer. Future migration to PostgreSQL, MySQL, or a REST API requires only replacing the repository implementations — all screens and providers remain unchanged.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.5)),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(color: AppTheme.surfaceWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy)),
        const Divider(height: 16),
        ...children,
      ]),
    );
  }

  Widget _logoRow(String label, String prefKey) {
    return Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceGrey, border: Border.all(color: AppTheme.borderLight)), child: const Icon(Icons.shield_outlined, color: AppTheme.textDisabled, size: 28)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const Text('Placeholder — tap Replace to upload', style: TextStyle(fontSize: 11, color: AppTheme.textDisabled)),
      ])),
      TextButton(onPressed: () => _showLogoNotice(), child: const Text('Replace')),
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]));
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color)),
      onPressed: _seeding ? null : onTap,
      style: OutlinedButton.styleFrom(side: BorderSide(color: color.withOpacity(0.4)), minimumSize: const Size.fromHeight(40)),
    );
  }

  Future<void> _seedSampleData() async {
    setState(() => _seeding = true);
    await SampleDataSeeder.seed(PrisonerRepository());
    ref.invalidate(allPrisonersProvider);
    ref.invalidate(dashboardStatsProvider);
    if (mounted) {
      setState(() => _seeding = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample data loaded successfully')));
    }
  }

  void _backup() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup: copy the pums.db file from app data directory')));
  void _restore() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore: replace pums.db in app data directory and restart')));
  void _showLogoNotice() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo upload: place image files in assets/logos/ and rebuild')));
}
