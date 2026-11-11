import 'package:flutter/material.dart';

import '../../../shared/widgets/vote_chip.dart';
import '../../../theme/ember_retro_theme.dart';
import '../domain/plan.dart';
import '../domain/tally.dart';
import '../domain/time_vote.dart';

// Peças compartilhadas entre o painel do organizador e a página do convidado.

({String label, Color color}) planStatusTag(Plan plan) => switch (plan.status) {
      PlanStatus.votando when plan.isPastDeadline => (label: 'Prazo encerrado', color: EmberColors.sol),
      PlanStatus.votando => (label: 'Votando', color: EmberColors.brasa),
      PlanStatus.fechado => (label: 'Fechou', color: EmberColors.menta),
      PlanStatus.cancelado => (label: 'Cancelado', color: EmberColors.neblina),
      PlanStatus.expirado => (label: 'Expirado', color: EmberColors.neblina),
    };


class PlanFinalCard extends StatelessWidget {
  const PlanFinalCard({required this.when});

  final String when;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      color: EmberColors.menta,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded, size: 32, color: EmberColors.tinta),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FECHOU!', style: EmberText.mono(12, color: EmberColors.tinta)),
                const SizedBox(height: 2),
                Text(when, style: EmberText.display(20, color: EmberColors.tinta)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class PlanSectionTitle extends StatelessWidget {
  const PlanSectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: EmberText.display(22))),
        if (trailing != null) Text(trailing!, style: EmberText.mono(10, color: p.textoSecundario)),
      ],
    );
  }
}


class PlanOptionCard extends StatelessWidget {
  const PlanOptionCard({
    required this.label,
    required this.tally,
    required this.isLeader,
    required this.isFinal,
    required this.myVote,
    required this.onVote,
  });

  final String label;
  final OptionTally tally;
  final bool isLeader;
  final bool isFinal;
  final Disp? myVote;
  final ValueChanged<Disp>? onVote;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final total = tally.total;

    return RetroCard(
      padding: const EdgeInsets.all(14),
      color: isFinal ? EmberColors.menta.withAlpha(46) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: p.textoSecundario),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: EmberText.body(16, weight: FontWeight.w700))),
              if (isLeader) const RetroTag('Liderando', color: EmberColors.sol),
              if (isFinal) const RetroTag('Escolhido', color: EmberColors.menta),
            ],
          ),
          const SizedBox(height: 10),
          // Barra empilhada: posso / talvez / não posso
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: p.superficie,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: p.contorno, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: total == 0
                ? null
                : Row(
                    children: [
                      if (tally.posso > 0) Expanded(flex: tally.posso, child: const ColoredBox(color: EmberColors.menta)),
                      if (tally.talvez > 0) Expanded(flex: tally.talvez, child: const ColoredBox(color: EmberColors.lavanda)),
                      if (tally.nao > 0) Expanded(flex: tally.nao, child: const ColoredBox(color: EmberColors.neblina)),
                    ],
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'Ninguém votou ainda'
                : '${tally.posso} posso · ${tally.talvez} talvez · ${tally.nao} não posso',
            style: EmberText.body(12, color: p.textoSecundario, weight: FontWeight.w600),
          ),
          if (onVote != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                VoteChip(type: VoteType.posso, selected: myVote == Disp.posso, onTap: () => onVote!(Disp.posso)),
                VoteChip(type: VoteType.talvez, selected: myVote == Disp.talvez, onTap: () => onVote!(Disp.talvez)),
                VoteChip(type: VoteType.naoPosso, selected: myVote == Disp.naoPosso, onTap: () => onVote!(Disp.naoPosso)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class PlanMessage extends StatelessWidget {
  const PlanMessage({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: EmberText.body(16, weight: FontWeight.w600)),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
