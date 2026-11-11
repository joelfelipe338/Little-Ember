import 'package:flutter/material.dart';
import '../../theme/ember_retro_theme.dart';

enum VoteType { posso, talvez, naoPosso }

/// Chip de voto no estilo retrô: tom claro quando livre,
/// cor cheia + contorno + sombra sólida quando escolhido.
class VoteChip extends StatelessWidget {
  const VoteChip({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final VoteType type;
  final bool selected;
  final VoidCallback onTap;

  /// Quantos votos essa opção já tem (opcional).
  final int? count;

  (String label, IconData icon, Color color) get _config => switch (type) {
        VoteType.posso => ('Posso', Icons.check_rounded, EmberColors.menta),
        VoteType.talvez => ('Talvez', Icons.question_mark_rounded, EmberColors.lavanda),
        VoteType.naoPosso => ('Não posso', Icons.close_rounded, EmberColors.neblina),
      };

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _config;
    final p = RetroPalette.of(context);
    final fg = selected ? EmberColors.tinta : p.texto;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color : color.withAlpha(46),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? p.contorno : Colors.transparent,
              width: EmberRetro.borda,
            ),
            boxShadow: selected
                ? [BoxShadow(color: p.contorno, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
              Text(label, style: EmberText.body(13, color: fg, weight: FontWeight.w800)),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text('$count', style: EmberText.body(13, color: selected ? EmberColors.tinta : p.textoSecundario, weight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
