import 'package:flutter/material.dart';

import '../../../../theme/ember_retro_theme.dart';
import '../../../connections/presentation/widgets/connection_ui.dart';
import '../../../places/domain/place.dart';
import '../../../places/presentation/place_widgets.dart';
import 'create_plan_widgets.dart';

/// Passo 1: nome do rolê, ideias prontas, local (mapa, em breve) e prévia do convite.
class StepOQue extends StatelessWidget {
  const StepOQue({
    super.key,
    required this.controller,
    required this.organizerName,
    required this.onPickPlace,
    required this.onClearPlace,
    this.local,
  });

  final TextEditingController controller;
  final String organizerName;

  /// Local escolhido no mapa (null = sem local).
  final PlaceDraft? local;

  /// Abre o mapa pra escolher (ou trocar) o local.
  final VoidCallback onPickPlace;
  final VoidCallback onClearPlace;

  static const ideias = <(String, IconData)>[
    ('Churras', Icons.outdoor_grill_rounded),
    ('Barzinho', Icons.local_bar_rounded),
    ('Cinema', Icons.movie_rounded),
    ('Jantar', Icons.restaurant_rounded),
    ('Aniversário', Icons.cake_rounded),
    ('Futebol', Icons.sports_soccer_rounded),
    ('Praia', Icons.beach_access_rounded),
    ('Jogatina', Icons.sports_esports_rounded),
  ];

  void _useIdea(String ideia) {
    controller.text = ideia;
    controller.selection = TextSelection.collapsed(offset: ideia.length);
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final titulo = controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepQuestion('Qual é o rolê?'),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          autofocus: titulo.isEmpty,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: EmberText.body(17, weight: FontWeight.w700),
          decoration: const InputDecoration(hintText: 'Ex.: Churras de sábado', counterText: ''),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Ou comece por uma ideia'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (nome, icon) in ideias)
              RetroChoiceChip(
                label: nome,
                icon: icon,
                color: EmberColors.sol,
                selected: titulo.toLowerCase().startsWith(nome.toLowerCase()),
                onTap: () => _useIdea(nome),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionLabel('Onde? (opcional)'),
        const SizedBox(height: 8),
        if (local == null)
          AddPlaceButton(onTap: onPickPlace, label: 'Escolher no mapa')
        else
          _ChosenPlace(local: local!, onChange: onPickPlace, onClear: onClearPlace),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EmberRetro.raioCard),
            border: Border.all(color: p.textoSecundario.withAlpha(140), width: 2.5),
          ),
          child: Row(
            children: [
              Icon(Icons.visibility_rounded, size: 20, color: p.textoSecundario),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'É assim que a galera vai ver no convite: '),
                      TextSpan(
                        text: '"$organizerName te chamou pro ${titulo.isEmpty ? '...' : titulo}"',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  style: EmberText.body(13, color: p.texto),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Local já escolhido: mapinha + nome, com trocar e tirar.
class _ChosenPlace extends StatelessWidget {
  const _ChosenPlace({required this.local, required this.onChange, required this.onClear});

  final PlaceDraft local;
  final VoidCallback onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlaceCard(
          place: Place(
            id: '',
            nome: local.nome,
            endereco: local.endereco,
            latitude: local.latitude,
            longitude: local.longitude,
          ),
          onChange: onChange,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onClear,
            style: TextButton.styleFrom(foregroundColor: p.textoSecundario, minimumSize: const Size(44, 40)),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text('Sem local', style: EmberText.body(12.5, weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
