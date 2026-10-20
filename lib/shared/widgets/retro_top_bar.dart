import 'package:flutter/material.dart';

import '../../theme/ember_retro_theme.dart';
import 'ember_flame.dart';

/// Topo padrão das telas: [ação esquerda] — placa central — [ação direita].
/// Os lados vazios ganham um espaço do mesmo tamanho para a placa ficar centralizada.
class RetroTopBar extends StatelessWidget {
  const RetroTopBar({
    super.key,
    required this.left,
    required this.right,
    this.emblem,
    this.leading,
    this.trailing,
  });

  final String left;
  final String right;

  /// Conteúdo do círculo central da placa. Padrão: a chama do app.
  final Widget? emblem;
  final Widget? leading;
  final Widget? trailing;

  static const _slot = 52.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _slot, child: leading),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RetroPlaque(
                left: left,
                right: right,
                emblem: emblem ?? const EmberFlame(size: 25),
              ),
            ),
          ),
        ),
        SizedBox(width: _slot, child: trailing),
      ],
    );
  }
}

/// Rótulo de campo no estilo do tema (mono, caixa alta), sempre acima do input.
class RetroFieldLabel extends StatelessWidget {
  const RetroFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(), style: EmberText.mono(12)),
    );
  }
}

/// Caixa de erro com contorno, usada em formulários.
class RetroErrorBox extends StatelessWidget {
  const RetroErrorBox(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EmberColors.erroFundo,
          borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
          border: Border.all(color: EmberColors.brasaForte, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: EmberColors.brasaTexto),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: EmberText.body(14, color: EmberColors.brasaTexto, weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de carregamento para dentro de botões.
class RetroButtonSpinner extends StatelessWidget {
  const RetroButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 3, color: EmberColors.tinta),
    );
  }
}
