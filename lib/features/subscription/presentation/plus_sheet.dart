import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/ember_retro_theme.dart';
import '../../connections/presentation/widgets/connection_sheets.dart';

/// Selinho "PLUS" ao lado de recursos da assinatura.
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 5 : 7, vertical: 1),
      decoration: BoxDecoration(
        color: EmberColors.lavanda,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.contorno, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: small ? 9 : 11, color: EmberColors.tinta),
          const SizedBox(width: 2),
          Text('PLUS', style: EmberText.mono(small ? 8 : 9.5, color: EmberColors.tinta)),
        ],
      ),
    );
  }
}

/// Avisa que algo é do CHAMMA+ (ou que o limite do grátis acabou) e leva pra Assinatura.
Future<void> showPlusSheet(BuildContext context, {required String titulo, required String motivo}) {
  return showRetroSheet<void>(
    context,
    (ctx) {
      final p = RetroPalette.of(ctx);
      return RetroSheet(
        title: titulo,
        subtitle: motivo,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EmberColors.lavanda.withAlpha(60),
              borderRadius: BorderRadius.circular(EmberRetro.raioCard),
              border: p.contornoBorda,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHAMMA+', style: EmberText.display(22)),
                const SizedBox(height: 6),
                for (final t in const [
                  'Rolês em votação sem limite',
                  'Até 15 horários e galera sem limite por rolê',
                  'Modos Rápido e Secreto',
                  'Grupos de conexões sem limite',
                ])
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded, size: 17, color: p.texto),
                        const SizedBox(width: 6),
                        Expanded(child: Text(t, style: EmberText.body(13.5, weight: FontWeight.w600))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RetroButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/assinatura');
            },
            expand: true,
            color: EmberColors.lavanda,
            child: const Text('Conhecer o CHAMMA+'),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: p.texto, minimumSize: const Size(44, 44)),
              child: const Text('Agora não'),
            ),
          ),
        ],
      );
    },
  );
}
