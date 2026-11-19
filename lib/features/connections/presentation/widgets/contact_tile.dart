import 'package:flutter/material.dart';

import '../../../../theme/ember_retro_theme.dart';
import '../../domain/brasa.dart';
import '../../domain/contact.dart';
import 'connection_ui.dart';

/// Linha de uma conexão: avatar, nome, tipo, último rolê e ação.
///
/// Com [selected] diferente de null, vira linha de seleção (caixinha à esquerda).
/// Com [onCall], mostra o botão "Chamar" com a chama da brasa.
class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contact,
    this.lastPlan,
    this.onTap,
    this.onLongPress,
    this.onCall,
    this.selected,
  });

  final Contact contact;
  final LastPlan? lastPlan;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onCall;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final level = brasaOf(lastPlan);
    final isSelected = selected == true;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${contact.nome}, ${contact.tipo.label}. ${brasaSubtitle(lastPlan)}',
      excludeSemantics: onCall == null,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: isSelected ? EmberColors.menta.withAlpha(40) : p.superficie,
            border: p.contornoBorda,
            borderRadius: BorderRadius.circular(EmberRetro.raioCard),
            boxShadow: [p.sombraDeCard],
          ),
          child: Row(
            children: [
              if (selected != null) ...[
                _CheckBox(checked: isSelected),
                const SizedBox(width: 10),
              ],
              ContactAvatar(contact: contact),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: EmberText.body(15, weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        RetroTag(contact.tipo.label.toUpperCase(), color: contact.tipo.color),
                        if (contact.isLinked) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Tem o CHAMMA: os rolês chegam direto no app',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: EmberColors.menta,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: p.contorno, width: 2),
                              ),
                              child: const Icon(Icons.phone_iphone_rounded, size: 12, color: EmberColors.tinta),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        BrasaFlame(level: level, size: 13),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            brasaSubtitle(lastPlan),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: EmberText.body(12.5, color: p.textoSecundario),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onCall != null) ...[
                const SizedBox(width: 8),
                RetroButton(
                  onPressed: onCall,
                  height: 36,
                  shape: RetroButtonShape.pill,
                  color: p.botaoSecundario,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  semanticLabel: 'Chamar ${contact.nome} pro rolê',
                  child: Text('Chamar', style: EmberText.body(13, weight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? EmberColors.menta : p.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.contorno, width: 2.5),
      ),
      child: checked ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
    );
  }
}
