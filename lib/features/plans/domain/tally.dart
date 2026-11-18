import 'time_option.dart';
import 'time_vote.dart';

/// Contagem de votos de uma opção de horário.
class OptionTally {
  OptionTally(this.option);

  final TimeOption option;
  int posso = 0;
  int talvez = 0;
  int nao = 0;
  bool eliminated = false;

  int get total => posso + talvez + nao;

  /// Pontuação usada no placar: "Posso" vale 2, "Talvez" vale 1.
  /// Eliminados ficam com -1 para irem ao final do ranking.
  int get score => eliminated ? -1 : posso * 2 + talvez;
}

/// Ordena as opções do placar. Critérios de desempate (do plano do produto):
/// mais pontos → mais "Posso" → menos "Não posso" → data mais cedo.
/// Eliminados (essencial votou "Não posso") vão para o final.
List<OptionTally> rankOptions(
  List<TimeOption> options,
  List<TimeVote> votes, {
  Set<String> essentialMemberIds = const {},
  String semRespostaContaComo = 'nada',
  int totalMembers = 0,
}) {
  final byId = {for (final o in options) o.id!: OptionTally(o)};
  final votedMembers = <String, Set<String>>{
    for (final o in options) o.id!: {},
  };

  for (final v in votes) {
    final t = byId[v.timeOptionId];
    if (t == null) continue;
    votedMembers[v.timeOptionId]!.add(v.memberId);
    switch (v.disp) {
      case Disp.posso:
        t.posso++;
      case Disp.talvez:
        t.talvez++;
      case Disp.naoPosso:
        t.nao++;
        if (essentialMemberIds.contains(v.memberId)) {
          t.eliminated = true;
        }
    }
  }

  if (semRespostaContaComo == 'nao_posso' && totalMembers > 0) {
    for (final entry in byId.entries) {
      final missing = totalMembers - votedMembers[entry.key]!.length;
      if (missing > 0) entry.value.nao += missing;
    }
  }

  final list = byId.values.toList()
    ..sort((a, b) {
      if (a.eliminated != b.eliminated) return a.eliminated ? 1 : -1;
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
