import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_empty_state.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RetroScaffold(
      top: const RetroTopBar(
        left: 'SUAS',
        right: 'CONEXÕES',
        emblem: Icon(Icons.people_alt_rounded, size: 22, color: EmberColors.tinta),
      ),
      body: RetroEmptyState(
        illustration: const Icon(Icons.diversity_3_rounded, size: 72, color: EmberColors.lavanda),
        title: 'Suas conexões',
        message: 'Amigos, casal, família, trabalho... cada conexão tem uma brasa. Mantenha ela acesa!',
        action: EmberButton(
          label: 'Nova conexão',
          icon: Icons.group_add_rounded,
          onPressed: () {
            // TODO: criar conexão (semana 8)
          },
        ),
      ),
    );
  }
}
