import 'time_option.dart';
import 'time_vote.dart';

/// Contagem de votos de uma opção de horário.
class OptionTally {
  OptionTally(this.option);

  final TimeOption option;
  int posso = 0;
  int talvez = 0;
  int nao = 0;

  int get total => posso + talvez + nao;

  /// Pontuação usada no placar: "Posso" vale 2, "Talvez" vale 1.
  int get score => posso * 2 + talvez;
}

/// Ordena as opções do placar. Critérios de desempate (do plano do produto):
/// mais pontos → mais "Posso" → menos "Não posso" → data mais cedo.
List<OptionTally> rankOptions(List<TimeOption> options, List<TimeVote> votes) {
  final byId = {for (final o in options) o.id!: OptionTally(o)};
  for (final v in votes) {
    final t = byId[v.timeOptionId];
    if (t == null) continue;
    switch (v.disp) {
      case Disp.posso:
        t.posso++;
      case Disp.talvez:
        t.talvez++;
      case Disp.naoPosso:
        t.nao++;
    }
  }
  final list = byId.values.toList()
    ..sort((a, b) {
      var c = b.score.compareTo(a.score);
      if (c != 0) return c;
      c = b.posso.compareTo(a.posso);
      if (c != 0) return c;
      c = a.nao.compareTo(b.nao);
      if (c != 0) return c;
      return a.option.inicioUtc.compareTo(b.option.inicioUtc);
    });
  return list;
}

/// "fecha em 2d 4h", "fecha em 3h 10min", "fecha em 12min" ou null se já passou.
String? formatRemaining(DateTime deadline, {DateTime? now}) {
  final diff = deadline.difference(now ?? DateTime.now());
  if (diff.isNegative) return null;
  final d = diff.inDays, h = diff.inHours % 24, m = diff.inMinutes % 60;
  if (d > 0) return 'fecha em ${d}d ${h}h';
  if (diff.inHours > 0) return 'fecha em ${diff.inHours}h ${m}min';
  return 'fecha em ${diff.inMinutes < 1 ? 1 : diff.inMinutes}min';
}
