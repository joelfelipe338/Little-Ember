import 'package:flutter/material.dart';

import '../../../../theme/ember_retro_theme.dart';

/// Primeira letra maiúscula ("sábado" -> "Sábado").
String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Barrinhas de progresso + "PASSO 2 DE 4 · QUANDO".
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total, required this.name});

  final int step;
  final int total;
  final String name;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Semantics(
      label: 'Passo ${step + 1} de $total: $name',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 9,
                    decoration: BoxDecoration(
                      color: i <= step ? EmberColors.sol : p.superficie,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: p.contorno, width: 2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PASSO ${step + 1} DE $total · ${name.toUpperCase()}',
            style: EmberText.mono(10.5, color: p.textoSecundario),
          ),
        ],
      ),
    );
  }
}

/// Pergunta grande do topo de cada passo.
class StepQuestion extends StatelessWidget {
  const StepQuestion(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: EmberText.display(30).copyWith(height: 1.05)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: EmberText.body(14, color: p.textoSecundario)),
        ],
      ],
    );
  }
}

/// Interruptor no estilo retrô.
class RetroToggle extends StatelessWidget {
  const RetroToggle({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Semantics(
      toggled: value,
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? EmberColors.menta : p.linhaSuave,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.contorno, width: 2.5),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: p.superficie,
              shape: BoxShape.circle,
              border: Border.all(color: p.contorno, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha de ajuste: ícone, título, descrição e um controle à direita.
class RuleRow extends StatelessWidget {
  const RuleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: p.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: EmberText.body(14, weight: FontWeight.w700)),
                Text(description, style: EmberText.body(12, color: p.textoSecundario)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Seletor − valor + (quórum, limite de "Posso", lembrete).
class RetroStepper extends StatelessWidget {
  const RetroStepper({
    super.key,
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallButton(icon: Icons.remove_rounded, label: 'Diminuir', onTap: onMinus),
        SizedBox(
          width: 46,
          child: Text(label, textAlign: TextAlign.center, style: EmberText.display(16)),
        ),
        _SmallButton(icon: Icons.add_rounded, label: 'Aumentar', onTap: onPlus),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: enabled ? p.botaoSecundario : p.linhaSuave,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.contorno, width: 2.5),
            boxShadow: enabled ? [BoxShadow(color: p.contorno, offset: const Offset(0, 3))] : null,
          ),
          child: Icon(icon, size: 18, color: enabled ? p.texto : p.textoSecundario),
        ),
      ),
    );
  }
}

/// Link sublinhado em mono ("EDITAR", "VER MÊS").
class MonoLink extends StatelessWidget {
  const MonoLink(this.text, {super.key, required this.onTap, this.icon});

  final String text;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: p.texto),
                  const SizedBox(width: 4),
                ],
                Text(
                  text.toUpperCase(),
                  style: EmberText.mono(10.5, color: p.texto).copyWith(decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
