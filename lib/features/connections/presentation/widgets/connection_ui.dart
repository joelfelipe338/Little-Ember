import 'package:flutter/material.dart';

import '../../../../shared/widgets/ember_flame.dart';
import '../../../../theme/ember_retro_theme.dart';
import '../../domain/brasa.dart';
import '../../domain/contact.dart';
import '../../domain/contact_group.dart';

/// Rótulo, cor e ícone de cada tipo de relação.
extension ConnectionTypeUi on ConnectionType {
  String get label => switch (this) {
        ConnectionType.amigos => 'Amigo',
        ConnectionType.casal => 'Casal',
        ConnectionType.familia => 'Família',
        ConnectionType.trabalho => 'Trabalho',
        ConnectionType.outro => 'Outro',
      };

  /// Plural para os filtros.
  String get labelPlural => switch (this) {
        ConnectionType.amigos => 'Amigos',
        ConnectionType.casal => 'Casal',
        ConnectionType.familia => 'Família',
        ConnectionType.trabalho => 'Trabalho',
        ConnectionType.outro => 'Outros',
      };

  Color get color => switch (this) {
        ConnectionType.amigos => EmberColors.lavanda,
        ConnectionType.casal => EmberColors.brasa,
        ConnectionType.familia => EmberColors.menta,
        ConnectionType.trabalho => EmberColors.sol,
        ConnectionType.outro => EmberColors.neblina,
      };

  IconData get icon => switch (this) {
        ConnectionType.amigos => Icons.people_alt_rounded,
        ConnectionType.casal => Icons.favorite_rounded,
        ConnectionType.familia => Icons.home_rounded,
        ConnectionType.trabalho => Icons.work_rounded,
        ConnectionType.outro => Icons.person_rounded,
      };
}

extension GroupColorUi on GroupColor {
  Color get color => switch (this) {
        GroupColor.lavanda => EmberColors.lavanda,
        GroupColor.brasa => EmberColors.brasa,
        GroupColor.menta => EmberColors.menta,
        GroupColor.sol => EmberColors.sol,
        GroupColor.neblina => EmberColors.neblina,
      };
}

/// Chama pequena que mostra a temperatura da brasa com a pessoa.
class BrasaFlame extends StatelessWidget {
  const BrasaFlame({super.key, required this.level, this.size = 16});

  final BrasaLevel level;
  final double size;

  static const _fria = Color(0xFFC9D3E6);
  static const _friaMiolo = Color(0xFFE7ECF5);
  static const _morna = Color(0xFFFF9A6B);
  static const _mornaMiolo = Color(0xFFFFE3A3);

  @override
  Widget build(BuildContext context) {
    final (outer, inner) = switch (level) {
      BrasaLevel.quente => (EmberColors.brasa, EmberColors.sol),
      BrasaLevel.morna => (_morna, _mornaMiolo),
      BrasaLevel.fria => (_fria, _friaMiolo),
    };
    return EmberFlame(size: size, color: outer, innerColor: inner);
  }
}

/// Bolinha com a inicial da pessoa, na cor do tipo de relação.
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({super.key, required this.contact, this.size = 38});

  final Contact contact;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final nome = contact.nome.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: contact.tipo.color,
        shape: BoxShape.circle,
        border: Border.all(color: p.contorno, width: 2.5),
      ),
      child: Text(
        nome.isEmpty ? '?' : nome.characters.first.toUpperCase(),
        style: EmberText.body(size * 0.4, color: EmberColors.tinta, weight: FontWeight.w800),
      ),
    );
  }
}

/// Pílula selecionável (filtros, tipos, grupos).
class RetroChoiceChip extends StatelessWidget {
  const RetroChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
    this.dotColor,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Fundo quando selecionado. Sem cor: fundo invertido (tinta / creme).
  final Color? color;
  final IconData? icon;
  final Color? dotColor;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final bg = selected ? (color ?? p.invertido) : p.superficie;
    final fg = selected ? (color != null ? EmberColors.tinta : p.noInvertido) : p.texto;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.contorno, width: 2.5),
            boxShadow: selected ? null : [BoxShadow(color: p.contorno, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.contorno, width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: EmberText.body(13, color: fg, weight: FontWeight.w700)),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                Text(trailing!, style: EmberText.mono(10, color: fg.withAlpha(200))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rótulo de seção em mono, caixa alta.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Row(
      children: [
        Expanded(child: Text(text.toUpperCase(), style: EmberText.mono(10.5, color: p.textoSecundario))),
        if (trailing != null) trailing!,
      ],
    );
  }
}
