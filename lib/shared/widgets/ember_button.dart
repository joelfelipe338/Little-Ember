import 'package:flutter/material.dart';
import '../../theme/ember_retro_theme.dart';
import 'retro_top_bar.dart';

enum EmberButtonVariant { primary, outlined }

/// Atalho para o RetroButton com rótulo + ícone + loading.
/// primary = amarelo (sol); outlined = branco.
class EmberButton extends StatelessWidget {
  const EmberButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = EmberButtonVariant.primary,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EmberButtonVariant variant;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return RetroButton(
      onPressed: isLoading ? () {} : onPressed,
      expand: expand,
      height: 50,
      color: variant == EmberButtonVariant.primary ? EmberColors.sol : EmberColors.branco,
      semanticLabel: isLoading ? 'Carregando' : null,
      child: isLoading
          ? const RetroButtonSpinner()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}
