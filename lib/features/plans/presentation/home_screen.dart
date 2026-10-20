import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/ember_flame.dart';
import '../../../shared/widgets/retro_empty_state.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RetroScaffold(
      top: const RetroTopBar(left: 'SEUS', right: 'ROLÊS'),
      body: RetroEmptyState(
        illustration: const Brasinha(size: 92),
        title: 'Nenhuma brasa acesa ainda',
        message: '${AppConstants.slogan}\nCrie o primeiro rolê e chame a galera.',
        action: EmberButton(
          label: 'Novo rolê',
          icon: Icons.add_rounded,
          onPressed: () => context.push('/create-plan'),
        ),
      ),
    );
  }
}
