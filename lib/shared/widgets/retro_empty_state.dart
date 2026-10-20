import 'package:flutter/material.dart';
import '../../theme/ember_retro_theme.dart';

/// Estado vazio padrão: ilustração num círculo com contorno, título, texto e uma ação.
class RetroEmptyState extends StatelessWidget {
  const RetroEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    this.action,
  });

  final Widget illustration;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 148,
                height: 148,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: EmberColors.branco,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: EmberColors.tinta, width: EmberRetro.borda)),
                  boxShadow: [BoxShadow(color: EmberColors.tinta, offset: Offset(0, 6))],
                ),
                child: illustration,
              ),
              const SizedBox(height: 26),
              Text(title, style: EmberText.display(26), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: EmberText.body(15, color: EmberColors.textoSecundario).copyWith(height: 1.45),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 26),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
