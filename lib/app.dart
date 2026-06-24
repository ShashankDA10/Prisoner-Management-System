import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';

class PumsApp extends ConsumerWidget {
  const PumsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PUMS — Prisoner & Undertrial Monitoring System',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      routerConfig: router,
    );
  }
}
