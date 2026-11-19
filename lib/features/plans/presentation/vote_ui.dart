import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/ember_retro_theme.dart';
import '../../places/domain/place.dart';
import '../domain/plan_member.dart';
import '../domain/tally.dart';
import '../domain/time_option.dart';
import '../domain/time_vote.dart';

// Peças de votação usadas no painel do organizador e na página do convidado.

String capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Sáb 22", "Sex 21".
String diaCurto(DateTime d) => capitalizar(DateFormat('EEE d', 'pt_BR').format(d.toLocal()).replaceAll('.', ''));

/// "Sáb, 22 de nov · 19:00".
String diaHora(DateTime d) =>
    capitalizar(DateFormat("EEE, d 'de' MMM · HH:mm", 'pt_BR').format(d.toLocal()).replaceAll('.', ''));

String hora(DateTime d) => DateFormat('HH:mm').format(d.toLocal());

const _coresGente = [EmberColors.lavanda, EmberColors.menta, EmberColors.sol, EmberColors.brasa];

/// Bolinhas sobrepostas com as iniciais da galera.
class PeopleDots extends StatelessWidget {
  const PeopleDots({super.key, required this.names, this.max = 4, this.size = 26});

  final List<String> names;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    if (shown.isEmpty) return const SizedBox.shrink();
    final step = size * 0.68;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + (shown.length - 1) * step,
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * step,
                  child: Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _coresGente[i % _coresGente.length],
                      shape: BoxShape.circle,
                      border: Border.all(color: p.contorno, width: 2),
                    ),
                    child: Text(
                      shown[i].trim().isEmpty ? '?' : shown[i].trim()[0].toUpperCase(),
                      style: EmberText.body(size * 0.42, color: EmberColors.tinta, weight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (extra > 0) ...[
          const SizedBox(width: 5),
          Text('+$extra', style: EmberText.mono(10, color: p.texto)),
        ],
      ],
    );
  }
}

/// Bloquinho de calendário (dia da semana em cima, número embaixo).
class DateBlock extends StatelessWidget {
  const DateBlock({super.key, required this.date, this.width = 48, this.color = EmberColors.brasa});

  final DateTime date;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final d = date.toLocal();
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.contorno, width: 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: color,
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              DateFormat('EEE', 'pt_BR').format(d).replaceAll('.', '').toUpperCase(),
              textAlign: TextAlign.center,
              style: EmberText.mono(width * 0.19, color: EmberColors.tinta),
            ),
          ),
          Container(height: 2, color: p.contorno),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${d.day}', style: EmberText.display(width * 0.42).copyWith(height: 1.15)),
          ),
        ],
      ),
    );
  }
}

/// Os três botões de voto. [big] = página do convidado (com texto), senão compacto (só ícone).
class VoteButtons extends StatelessWidget {
  const VoteButtons({super.key, required this.selected, required this.onVote, this.big = false});

  final Disp? selected;
  final ValueChanged<Disp>? onVote;
  final bool big;

  static const _opts = [
    (Disp.posso, Icons.check_rounded, 'Posso', EmberColors.menta),
    (Disp.talvez, Icons.question_mark_rounded, 'Talvez', EmberColors.lavanda),
    (Disp.naoPosso, Icons.close_rounded, 'Não', EmberColors.neblina),
  ];

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);

    Widget button((Disp, IconData, String, Color) o) {
      final (disp, icon, label, color) = o;
      final on = selected == disp;
      final fg = on ? (disp == Disp.naoPosso ? EmberColors.tinta : Colors.white) : p.texto;
      return Semantics(
        button: true,
        selected: on,
        label: label == 'Não' ? 'Não posso' : label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onVote == null ? null : () => onVote!(disp),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: big ? 46 : 36,
            width: big ? null : 40,
            margin: EdgeInsets.only(top: on ? 2 : 0, bottom: on ? 0 : 2),
            decoration: BoxDecoration(
              color: on ? color : p.superficie,
              borderRadius: BorderRadius.circular(big ? 12 : 10),
              border: Border.all(color: p.contorno, width: 2.5),
              boxShadow: on ? null : [BoxShadow(color: p.contorno, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: big ? 17 : 18, color: fg),
                if (big) ...[
                  const SizedBox(width: 5),
                  Text(label, style: EmberText.body(14, color: fg, weight: FontWeight.w800)),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (big) {
      return Row(
        children: [
          for (var i = 0; i < _opts.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: button(_opts[i])),
          ],
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _opts.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          button(_opts[i]),
        ],
      ],
    );
  }
}

/// Um horário na votação: data, hora, selo, quem pode, barra e botões de voto.
class OptionVoteCard extends StatelessWidget {
  const OptionVoteCard({
    super.key,
    required this.option,
    required this.tally,
    required this.canNames,
    this.myVote,
    this.onVote,
    this.isLeader = false,
    this.isFinal = false,
    this.eliminatedBy,
    this.showTally = true,
    this.big = false,
    this.pending = false,
    this.totalPessoas = 0,
  });

  final TimeOption option;
  final OptionTally tally;

  /// Quem marcou "Posso" (só os nomes).
  final List<String> canNames;
  final Disp? myVote;
  final ValueChanged<Disp>? onVote;
  final bool isLeader;
  final bool isFinal;

  /// Nome do essencial que não pode (horário fora).
  final String? eliminatedBy;
  final bool showTally;

  /// Página do convidado: botões grandes embaixo.
  final bool big;

  /// Ainda sem o voto da pessoa (contorno mais forte).
  final bool pending;

  /// Quantas pessoas estão no rolê: a barra mostra a fatia de cada voto
  /// sobre esse total, e o que sobra fica vazio (quem ainda não votou).
  final int totalPessoas;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final t = option.inicioUtc;
    final eliminated = eliminatedBy != null;
    final total = tally.total;

    final badge = isFinal
        ? const RetroTag('Escolhido', color: EmberColors.menta)
        : eliminated
            ? RetroTag('Sem ${eliminatedBy!.split(' ').first}', color: EmberColors.neblina)
            : isLeader
                ? const RetroTag('Liderando', color: EmberColors.sol)
                : null;

    final info = !showTally
        ? 'Votos ocultos'
        : total == 0
            ? 'Ninguém votou ainda'
            : '${tally.posso} ${tally.posso == 1 ? 'pode' : 'podem'}'
                '${tally.talvez > 0 ? ' · ${tally.talvez} talvez' : ''}';

    final header = Row(
      children: [
        DateBlock(date: t, width: big ? 50 : 46),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(hora(t), style: EmberText.display(big ? 21 : 19)),
                  if (badge != null) ...[const SizedBox(width: 8), Flexible(child: badge)],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (showTally && canNames.isNotEmpty) ...[
                    PeopleDots(names: canNames, size: 22),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(info,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EmberText.body(12, color: p.textoSecundario, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!big && onVote != null) ...[
          const SizedBox(width: 6),
          VoteButtons(selected: myVote, onVote: onVote),
        ],
        if (big && myVote != null)
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: EmberColors.menta,
              shape: BoxShape.circle,
              border: Border.all(color: p.contorno, width: 2.5),
            ),
            child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
          ),
      ],
    );

    return Opacity(
      opacity: eliminated && !isFinal ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFinal
              ? EmberColors.menta.withAlpha(45)
              : (isLeader ? EmberColors.sol.withAlpha(35) : p.superficie),
          borderRadius: BorderRadius.circular(EmberRetro.raioCard),
          border: Border.all(color: p.contorno, width: pending || isLeader ? 3.5 : EmberRetro.borda),
          boxShadow: [pending ? BoxShadow(color: p.contorno, offset: const Offset(0, 6)) : p.sombraDeCard],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (showTally && (total > 0 || totalPessoas > 0)) ...[
              const SizedBox(height: 10),
              _TallyBar(tally: tally, totalPessoas: totalPessoas),
            ],
            if (big && onVote != null) ...[
              const SizedBox(height: 12),
              VoteButtons(selected: myVote, onVote: onVote, big: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _TallyBar extends StatelessWidget {
  const _TallyBar({required this.tally, this.totalPessoas = 0});

  final OptionTally tally;
  final int totalPessoas;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final faltam = totalPessoas - tally.total;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: p.tela,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.contorno, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        // Sem isso o ColoredBox fica com altura 0 e a barra parece vazia.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tally.posso > 0) Expanded(flex: tally.posso, child: const ColoredBox(color: EmberColors.menta)),
          if (tally.talvez > 0) Expanded(flex: tally.talvez, child: const ColoredBox(color: EmberColors.lavanda)),
          if (tally.nao > 0) Expanded(flex: tally.nao, child: const ColoredBox(color: EmberColors.neblina)),
          // Quem ainda não votou nesse horário: espaço vazio.
          if (faltam > 0) Expanded(flex: faltam, child: const SizedBox.shrink()),
        ],
      ),
    );
  }
}

/// Rolê fechado em formato de ingresso: data, hora, local e ações.
class ClosedTicket extends StatelessWidget {
  const ClosedTicket({
    super.key,
    required this.titulo,
    required this.quando,
    this.place,
    this.onCalendar,
    this.onShare,
    this.shareLabel = 'Avisar galera',
  });

  final String titulo;
  final DateTime quando;
  final Place? place;
  final VoidCallback? onCalendar;
  final VoidCallback? onShare;
  final String shareLabel;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final t = quando.toLocal();
    final dias = DateUtils.dateOnly(t).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final falta = dias == 0
        ? 'HOJE'
        : dias == 1
            ? 'AMANHÃ'
            : dias > 1
                ? 'FALTAM $dias DIAS'
                : 'JÁ ROLOU';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RetroTag('Fechou!', color: EmberColors.menta),
          ],
        ),
        const SizedBox(height: 8),
        Text(titulo, textAlign: TextAlign.center, style: EmberText.display(26).copyWith(height: 1.05)),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.superficie,
            borderRadius: BorderRadius.circular(EmberRetro.raioCard),
            border: p.contornoBorda,
            boxShadow: [p.sombraDeCard],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 92,
                  color: EmberColors.brasa,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('MMM', 'pt_BR').format(t).replaceAll('.', '').toUpperCase(),
                          style: EmberText.mono(10, color: EmberColors.tinta)),
                      Text('${t.day}', style: EmberText.display(38, color: EmberColors.tinta).copyWith(height: 1)),
                      Text(DateFormat('EEEE', 'pt_BR').format(t).split('-').first.toUpperCase(),
                          style: EmberText.mono(9, color: EmberColors.tinta)),
                    ],
                  ),
                ),
                Container(width: 3, color: p.contorno),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(hora(t), style: EmberText.display(28).copyWith(height: 1)),
                        if (place != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.place_rounded, size: 16, color: p.texto),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(place!.nome,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: EmberText.body(13.5, weight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(falta, style: EmberText.mono(10, color: p.textoSecundario)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onCalendar != null || onShare != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (onCalendar != null)
                Expanded(
                  child: RetroButton(
                    onPressed: onCalendar,
                    height: 44,
                    color: p.botaoSecundario,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_rounded, size: 18),
                        const SizedBox(width: 6),
                        Flexible(child: Text('Pôr na agenda', style: EmberText.body(13.5, weight: FontWeight.w800))),
                      ],
                    ),
                  ),
                ),
              if (onCalendar != null && onShare != null) const SizedBox(width: 10),
              if (onShare != null)
                Expanded(
                  child: RetroButton(
                    onPressed: onShare,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        const SizedBox(width: 6),
                        Flexible(child: Text(shareLabel, style: EmberText.body(13.5, weight: FontWeight.w800))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Quem vai": quem marcou Posso no horário escolhido.
class GoingCard extends StatelessWidget {
  const GoingCard({super.key, required this.going, this.talvez = 0});

  final List<PlanMember> going;
  final int talvez;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text('Quem vai', style: EmberText.display(20))),
            Text(
              '${going.length} ${going.length == 1 ? 'CONFIRMADO' : 'CONFIRMADOS'}${talvez > 0 ? ' · $talvez TALVEZ' : ''}',
              style: EmberText.mono(10, color: p.textoSecundario),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RetroCard(
          padding: const EdgeInsets.all(12),
          child: going.isEmpty
              ? Text('Ninguém confirmou ainda.', style: EmberText.body(13, color: p.textoSecundario))
              : Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < going.length; i++)
                      SizedBox(
                        width: 54,
                        child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _coresGente[i % _coresGente.length],
                                shape: BoxShape.circle,
                                border: Border.all(color: p.contorno, width: 2.5),
                              ),
                              child: Text(
                                going[i].nome.trim().isEmpty ? '?' : going[i].nome.trim()[0].toUpperCase(),
                                style: EmberText.body(16, color: EmberColors.tinta, weight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(going[i].nome.trim().split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: EmberText.body(11.5, weight: FontWeight.w700)),
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
