import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/retro_top_bar.dart';
import '../../../../theme/ember_retro_theme.dart';
import '../../../connections/presentation/widgets/connection_ui.dart';
import '../../domain/invited_person.dart';
import '../../domain/time_option.dart';
import '../../../places/domain/place.dart';
import '../../../subscription/presentation/plus_sheet.dart';
import 'create_plan_widgets.dart';
import 'plan_rules.dart';

/// Sugestão de prazo em chip ("1 dia antes", "Amanhã 20h").
class PrazoSuggestion {
  const PrazoSuggestion(this.label, this.when);
  final String label;
  final DateTime when;
}

/// Passo 4: convite em formato de ingresso, prazo, modo de decidir e ajustes finos.
class StepRevisar extends StatefulWidget {
  const StepRevisar({
    super.key,
    required this.titulo,
    required this.options,
    required this.convidados,
    required this.linkAberto,
    required this.prazo,
    required this.prazoError,
    required this.suggestions,
    required this.onPrazo,
    required this.onCustomPrazo,
    required this.mode,
    required this.onMode,
    required this.plusLiberado,
    required this.local,
    required this.rules,
    required this.onRules,
    required this.onEditStep,
  });

  final String titulo;
  final List<TimeOption> options;
  final List<InvitedPerson> convidados;
  final bool linkAberto;
  final DateTime prazo;
  final String? prazoError;
  final List<PrazoSuggestion> suggestions;
  final ValueChanged<DateTime> onPrazo;
  final VoidCallback onCustomPrazo;
  /// Modo pronto escolhido (null = personalizado nos ajustes finos).
  final RuleMode? mode;
  final ValueChanged<RuleMode> onMode;

  /// CHAMMA+ ativo (Rápido / Secreto liberados).
  final bool plusLiberado;
  final PlaceDraft? local;
  final PlanRules rules;
  final ValueChanged<PlanRules> onRules;
  final ValueChanged<int> onEditStep;

  @override
  State<StepRevisar> createState() => _StepRevisarState();
}

class _StepRevisarState extends State<StepRevisar> {
  bool _ajustesAbertos = false;

  PlanRules get r => widget.rules;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final prazoFmt = DateFormat("EEE, d 'de' MMM 'às' HH:mm", 'pt_BR');
    final mode = widget.mode;
    final hasEssenciais = widget.convidados.any((c) => c.essencial);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Ticket(
          titulo: widget.titulo,
          options: widget.options,
          convidados: widget.convidados,
          linkAberto: widget.linkAberto,
          local: widget.local,
          onEditStep: widget.onEditStep,
        ),
        const SizedBox(height: 18),

        // ------------------------------------------------ prazo
        const SectionLabel('Votação fecha em'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in widget.suggestions)
              RetroChoiceChip(
                label: s.label,
                selected: s.when == widget.prazo,
                onTap: () => widget.onPrazo(s.when),
              ),
            RetroChoiceChip(
              label: 'Escolher',
              icon: Icons.edit_calendar_rounded,
              selected: !widget.suggestions.any((s) => s.when == widget.prazo),
              onTap: widget.onCustomPrazo,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.timer_rounded, size: 16, color: p.textoSecundario),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Fecha ${prazoFmt.format(widget.prazo)}',
                style: EmberText.body(13, color: p.textoSecundario, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (widget.prazoError != null) ...[
          const SizedBox(height: 10),
          RetroErrorBox(widget.prazoError!),
        ],
        const SizedBox(height: 18),

        // ------------------------------------------------ modos
        const SectionLabel('Como decidir'),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final m in RuleMode.values) ...[
                if (m != RuleMode.values.first) const SizedBox(width: 8),
                _ModeCard(
                  title: m.titulo,
                  description: m.descricao,
                  selected: mode == m,
                  locked: m != RuleMode.normal && !widget.plusLiberado,
                  onTap: () => widget.onMode(m),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // O que o modo escolhido faz, em frases curtas.
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: EmberColors.sol.withAlpha(45),
            borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
            border: Border.all(color: p.contorno.withAlpha(110), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode == null ? 'PERSONALIZADO' : mode.titulo.toUpperCase(),
                style: EmberText.mono(10, color: p.textoSecundario),
              ),
              const SizedBox(height: 4),
              for (final linha in r.descricao)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(Icons.check_rounded, size: 15, color: p.texto),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(linha, style: EmberText.body(12.5, color: p.texto))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ------------------------------------------------ ajustes finos
        Container(
          decoration: BoxDecoration(
            color: p.superficie,
            borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
            border: Border.all(color: p.contorno, width: 2.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                expanded: _ajustesAbertos,
                child: InkWell(
                  onTap: () => setState(() => _ajustesAbertos = !_ajustesAbertos),
                  borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: p.texto),
                        const SizedBox(width: 10),
                        Text('Ajustes finos', style: EmberText.body(14, weight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r.resumo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: EmberText.mono(9.5, color: p.textoSecundario),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _ajustesAbertos ? 0.5 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: Icon(Icons.expand_more_rounded, color: p.texto),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_ajustesAbertos)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    children: [
                      Divider(height: 2, color: p.linhaSuave),
                      RuleRow(
                        icon: Icons.group_rounded,
                        title: 'Quórum mínimo',
                        description: r.autoFechar ? 'Fecha sozinho quando bater' : 'Mínimo de votos pra fechar',
                        trailing: RetroStepper(
                          label: r.quorumMinimo == 0 ? 'Sem' : '${r.quorumMinimo}',
                          onMinus: r.quorumMinimo > 0
                              ? () => widget.onRules(r.copyWith(
                                    quorumMinimo: r.quorumMinimo - 1,
                                    autoFechar: r.quorumMinimo - 1 == 0 ? false : r.autoFechar,
                                  ))
                              : null,
                          onPlus: () => widget.onRules(r.copyWith(quorumMinimo: r.quorumMinimo + 1)),
                        ),
                      ),
                      if (r.quorumMinimo > 0)
                        RuleRow(
                          icon: Icons.lock_clock_rounded,
                          title: 'Fechar sozinho',
                          description: '${widget.plusLiberado ? '' : 'CHAMMA+ · '}Quando o quórum bater',
                          trailing: RetroToggle(
                            value: r.autoFechar,
                            onChanged: (v) => widget.onRules(r.copyWith(autoFechar: v)),
                          ),
                        ),
                      RuleRow(
                        icon: Icons.visibility_off_rounded,
                        title: 'Voto secreto',
                        description: '${widget.plusLiberado ? '' : 'CHAMMA+ · '}Ninguém vê quem votou o quê',
                        trailing: RetroToggle(
                          value: r.votoAnonimo,
                          onChanged: (v) => widget.onRules(r.copyWith(votoAnonimo: v)),
                        ),
                      ),
                      RuleRow(
                        icon: Icons.add_comment_rounded,
                        title: 'Sugestões de horário',
                        description: 'A galera pode sugerir outro horário',
                        trailing: RetroToggle(
                          value: r.permitirSugestoes,
                          onChanged: (v) => widget.onRules(r.copyWith(permitirSugestoes: v)),
                        ),
                      ),
                      RuleRow(
                        icon: Icons.confirmation_number_rounded,
                        title: 'Limite de "Posso"',
                        description: '${widget.plusLiberado ? '' : 'CHAMMA+ · '}Máximo de horários com Posso',
                        trailing: RetroStepper(
                          label: r.limitePosso == 0 ? 'Sem' : '${r.limitePosso}',
                          onMinus: r.limitePosso > 0
                              ? () => widget.onRules(r.copyWith(limitePosso: r.limitePosso - 1))
                              : null,
                          onPlus: r.limitePosso < widget.options.length
                              ? () => widget.onRules(r.copyWith(limitePosso: r.limitePosso + 1))
                              : null,
                        ),
                      ),
                      RuleRow(
                        icon: Icons.notifications_active_rounded,
                        title: 'Lembrete',
                        description: 'Avisar quem não votou antes do prazo',
                        trailing: _LembreteStepper(
                          value: r.lembreteHoras,
                          onChanged: (v) => widget.onRules(r.copyWith(lembreteHoras: v)),
                        ),
                      ),
                      if (hasEssenciais)
                        RuleRow(
                          icon: Icons.star_rounded,
                          title: 'Mostrar essenciais',
                          description: 'A galera vê quem é essencial',
                          trailing: RetroToggle(
                            value: r.essencialVisivel,
                            onChanged: (v) => widget.onRules(r.copyWith(essencialVisivel: v)),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================

class _Ticket extends StatelessWidget {
  const _Ticket({
    required this.titulo,
    required this.options,
    required this.convidados,
    required this.linkAberto,
    required this.local,
    required this.onEditStep,
  });

  final PlaceDraft? local;
  final String titulo;
  final List<TimeOption> options;
  final List<InvitedPerson> convidados;
  final bool linkAberto;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final dia = DateFormat("EEE d", 'pt_BR');
    final n = options.length;
    final range = n == 0
        ? 'nenhum ainda'
        : n == 1
            ? '${dia.format(options.first.inicioUtc).replaceAll('.', '')} às ${DateFormat('HH:mm').format(options.first.inicioUtc)}'
            : '${dia.format(options.first.inicioUtc).replaceAll('.', '')} a ${dia.format(options.last.inicioUtc).replaceAll('.', '')}';
    final essenciais = [for (final c in convidados) if (c.essencial) c.nome.split(' ').first];
    final pessoas = convidados.length;

    Widget row(IconData icon, String bold, String rest, {int? step}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 17, color: p.texto),
              const SizedBox(width: 9),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (rest.isNotEmpty) TextSpan(text: ' · $rest'),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EmberText.body(13.5, color: p.texto),
                ),
              ),
              if (step != null) MonoLink('Editar', onTap: () => onEditStep(step)),
            ],
          ),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        border: p.contornoBorda,
        boxShadow: [p.sombraDeCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            color: EmberColors.brasa,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONVITE', style: EmberText.mono(10, color: EmberColors.tinta)),
                      const SizedBox(height: 2),
                      Text(titulo, style: EmberText.display(24, color: EmberColors.tinta).copyWith(height: 1.05)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onEditStep(0),
                  tooltip: 'Editar nome',
                  icon: const Icon(Icons.edit_rounded, size: 18, color: EmberColors.tinta),
                ),
              ],
            ),
          ),
          // Picote do ingresso.
          CustomPaint(size: const Size.fromHeight(3), painter: _DashPainter(p.contorno)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
            child: Column(
              children: [
                row(Icons.calendar_month_rounded, '$n ${n == 1 ? 'horário' : 'horários'}', range, step: 1),
                row(
                  Icons.people_alt_rounded,
                  pessoas == 0 ? 'Ninguém chamado' : '$pessoas ${pessoas == 1 ? 'pessoa' : 'pessoas'}',
                  [
                    if (essenciais.isNotEmpty)
                      '${essenciais.join(', ')} ${essenciais.length == 1 ? 'é essencial' : 'são essenciais'}',
                    if (linkAberto) 'link aberto' else 'só convidados',
                  ].join(' · '),
                  step: 2,
                ),
                row(
                  Icons.place_rounded,
                  local == null ? 'Sem local' : local!.nome,
                  local == null ? 'dá pra marcar no mapa' : local!.endereco,
                  step: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 1.5), Offset(x + 7, 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String title;
  final String description;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final fg = selected ? EmberColors.tinta : p.texto;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.fromLTRB(9, 9, 8, 10),
            decoration: BoxDecoration(
              color: selected ? EmberColors.sol : p.superficie,
              borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
              border: Border.all(color: p.contorno, width: 2.5),
              boxShadow: selected ? null : [BoxShadow(color: p.contorno, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: EmberText.body(13.5, color: fg, weight: FontWeight.w800))),
                    if (locked) ...[const SizedBox(width: 4), const PlusBadge(small: true)],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: EmberText.body(11, color: selected ? EmberColors.tinta : p.textoSecundario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LembreteStepper extends StatelessWidget {
  const _LembreteStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _opcoes = [0, 2, 6, 12, 24];

  @override
  Widget build(BuildContext context) {
    final idx = _opcoes.indexOf(value).clamp(0, _opcoes.length - 1);
    return RetroStepper(
      label: value == 0 ? 'Não' : '${value}h',
      onMinus: idx > 0 ? () => onChanged(_opcoes[idx - 1]) : null,
      onPlus: idx < _opcoes.length - 1 ? () => onChanged(_opcoes[idx + 1]) : null,
    );
  }
}
