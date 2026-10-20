import 'package:flutter/material.dart';
import '../../theme/ember_retro_theme.dart';

/// Mantido por compatibilidade: hoje é só um RetroCard.
class EmberCard extends StatelessWidget {
  const EmberCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RetroCard(padding: padding, onTap: onTap, child: child);
  }
}
