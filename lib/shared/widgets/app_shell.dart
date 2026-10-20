import 'package:flutter/material.dart';
import '../../theme/ember_retro_theme.dart';

/// Moldura das abas principais: a tela atual em cima e a navegação retrô embaixo.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final Widget child;

  static const _items = [
    (icon: Icons.local_fire_department_rounded, label: 'Rolês'),
    (icon: Icons.people_alt_rounded, label: 'Conexões'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmberColors.brasa,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EmberRetro.margemMoldura, 6, EmberRetro.margemMoldura, 8,
              ),
              child: RetroNavBar(
                items: _items,
                currentIndex: currentIndex,
                onSelect: onTabChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
