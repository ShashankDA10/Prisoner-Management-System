import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/prisoner_provider.dart';

/// Top header bar with tri-logo branding and global search.
class PumsHeader extends ConsumerStatefulWidget {
  final bool compact;
  const PumsHeader({super.key, this.compact = false});

  @override
  ConsumerState<PumsHeader> createState() => _PumsHeaderState();
}

class _PumsHeaderState extends ConsumerState<PumsHeader> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.compact ? 56 : 72,
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          // Left logo / menu button
          if (widget.compact) ...[
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
          ] else ...[
            _LogoSlot(label: AppConstants.orgName),
            const SizedBox(width: 16),
          ],

          // Center logo (govt emblem)
          if (!widget.compact) ...[
            const Spacer(),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _GovtEmblem(),
              const SizedBox(height: 2),
              Text(
                AppConstants.govtName,
                style: const TextStyle(
                  color: AppTheme.accentLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
            const Spacer(),
          ],

          // Global search
          SizedBox(
            width: widget.compact ? double.infinity : 280,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search prisoners, FIR, sections...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.5), size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppTheme.accent),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),

          if (!widget.compact) ...[
            const SizedBox(width: 16),
            _LogoSlot(label: AppConstants.cityPolice),
          ],
        ]),
      ),
    );
  }
}

class _LogoSlot extends StatelessWidget {
  final String label;
  const _LogoSlot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Icon(Icons.shield_outlined, color: Colors.white70, size: 24),
      ),
      const SizedBox(height: 2),
      SizedBox(
        width: 100,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ]);
  }
}

class _GovtEmblem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: AppTheme.accent.withOpacity(0.5), width: 1.5),
      ),
      child: const Icon(Icons.account_balance, color: AppTheme.accentLight, size: 26),
    );
  }
}
