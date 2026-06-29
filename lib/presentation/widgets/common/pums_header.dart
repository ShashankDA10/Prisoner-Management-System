import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          // Left logo — Karnataka State Police (SVG)
          if (widget.compact) ...[
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
          ] else ...[
            _LogoSlot(
              imagePath: 'assets/logos/logo_left.svg',
              isSvg: true,
              label: AppConstants.orgName,
            ),
            const SizedBox(width: 16),
          ],

          // Centre logo — Government of Karnataka (webp)
          if (!widget.compact) ...[
            const Spacer(),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _roundImage('assets/logos/logo_center.webp', 48),
              const SizedBox(height: 2),
              const Text(
                AppConstants.govtName,
                style: TextStyle(
                  color: AppTheme.accentLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
            const Spacer(),
          ],

          // Search bar — Expanded on mobile, fixed width on desktop
          Builder(builder: (_) {
            final field = Padding(
              padding: EdgeInsets.fromLTRB(widget.compact ? 8 : 0, 12, 0, 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search prisoners, FIR...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.5), size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppTheme.accent),
                  ),
                  isDense: true,
                ),
              ),
            );
            return widget.compact
                ? Expanded(child: field)
                : SizedBox(width: 280, child: field);
          }),

          // Right logo — Bangalore City Police (webp)
          if (!widget.compact) ...[
            const SizedBox(width: 16),
            _LogoSlot(
              imagePath: 'assets/logos/logo_right.webp',
              isSvg: false,
              label: AppConstants.cityPolice,
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Circular logo slot with label below.
class _LogoSlot extends StatelessWidget {
  final String imagePath;
  final bool isSvg;
  final String label;

  const _LogoSlot({required this.imagePath, required this.isSvg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _roundImage(imagePath, 44, isSvg: isSvg),
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

/// Renders an asset image (SVG or raster) clipped to a circle.
Widget _roundImage(String path, double size, {bool isSvg = false}) {
  Widget image;
  if (isSvg) {
    image = SvgPicture.asset(
      path,
      width: size, height: size,
      fit: BoxFit.contain,
      // Falls back to placeholder on error
      placeholderBuilder: (_) => _placeholder(size),
    );
  } else {
    image = Image.asset(
      path,
      width: size, height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _placeholder(size),
    );
  }

  return ClipOval(
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: image,
    ),
  );
}

Widget _placeholder(double size) => SizedBox(
  width: size, height: size,
  child: const Icon(Icons.shield_outlined, color: Colors.white54, size: 24),
);
