import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/constants.dart';
import 'core/theme/theme_provider.dart';
import 'theme/ember_retro_theme.dart';

class LittleEmberApp extends ConsumerWidget {
  const LittleEmberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: EmberRetroTheme.light(),
      darkTheme: EmberRetroTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
