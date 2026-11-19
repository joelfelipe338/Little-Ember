import 'package:flutter/foundation.dart';

import 'plan.dart';
import 'plan_member.dart';
import 'tally.dart';
import 'time_option.dart';
import 'time_vote.dart';

/// Aba da lista de rolês.
enum PlanBucket { votando, fechados, passados }

/// Tudo o que a lista de rolês precisa de um rolê, já calculado.
@immutable
class PlanOverview {
  PlanOverview({
    required this.plan,
    required this.members,
    required this.options,
    required this.votes,
    required this.myUserId,
    this.placeName,
  });

  final Plan plan;
  final List<PlanMember> members;
  final List<TimeOption> options;
  final List<TimeVote> votes;
  final String myUserId;

  /// Nome do local (null = sem local).
  final String? placeName;

  late final PlanMember? me = _find((m) => m.userId == myUserId);
  late final PlanMember? organizer = _find((m) => m.isOrganizador);
  late final bool isOrganizer = plan.criadorId == myUserId;
  late final Set<String> votedMemberIds = {for (final v in votes) v.memberId};
  late final bool iVoted = me != null && votedMemberIds.contains(me!.id);

  /// Quem ainda não votou (fora quem organiza).
  late final List<PlanMember> pending = [
    for (final m in members)
      if (!m.isOrganizador && !votedMemberIds.contains(m.id)) m,
  ];

  /// Horário na frente (null se ninguém votou ou se está empatado).
  late final OptionTally? leader = () {
    if (options.isEmpty) return null;
    final ranking = rankOptions(
      options,
      votes,
      essentialMemberIds: {for (final m in members) if (m.essencial) m.id},
      semRespostaContaComo: plan.semRespostaContaComo,
      totalMembers: members.length,
    );
    final first = ranking.first;
    if (first.total == 0 || first.eliminated) return null;
    if (ranking.length > 1 && ranking[1].score == first.score) return null;
    return first;
  }();

  late final TimeOption? finalOption = () {
    for (final o in options) {
      if (o.id == plan.horarioFinalId) return o;
    }
    return null;
  }();

  DateTime? get finalTime => finalOption?.inicioUtc.toLocal();

  /// Convidado que ainda não votou num rolê aberto.
  bool get needsMyVote => !isOrganizer && me != null && plan.isVotingOpen && !iVoted;

  /// Organizador com prazo vencido: falta escolher o horário.
  bool get needsClosing => isOrganizer && plan.isPastDeadline;

  bool get isUpcoming {
    final t = finalTime;
    return plan.status == PlanStatus.fechado && (t == null || t.isAfter(DateTime.now()));
  }

  PlanBucket get bucket => switch (plan.status) {
        PlanStatus.votando => PlanBucket.votando,
        PlanStatus.fechado => isUpcoming ? PlanBucket.fechados : PlanBucket.passados,
        PlanStatus.cancelado || PlanStatus.expirado => PlanBucket.passados,
      };

  /// Ordem da lista: o que pede ação primeiro, depois o que acontece antes.
  int get priority {
    if (needsClosing) return 0;
    if (needsMyVote) return 1;
    return switch (bucket) {
      PlanBucket.votando => 2,
      PlanBucket.fechados => 3,
      PlanBucket.passados => 4,
    };
  }

  /// Data usada pra ordenar dentro do mesmo grupo.
  DateTime get sortDate => switch (bucket) {
        PlanBucket.votando => plan.prazoVotacao,
        PlanBucket.fechados => finalTime ?? plan.prazoVotacao,
        PlanBucket.passados => finalTime ?? plan.createdAt ?? plan.prazoVotacao,
      };

  PlanMember? _find(bool Function(PlanMember) test) {
    for (final m in members) {
      if (test(m)) return m;
    }
    return null;
  }
}

/// Ordena: prioridade; dentro dela, mais cedo primeiro (passados: mais recente primeiro).
List<PlanOverview> sortOverviews(Iterable<PlanOverview> list) {
  final sorted = [...list];
  sorted.sort((a, b) {
    final c = a.priority.compareTo(b.priority);
    if (c != 0) return c;
    if (a.bucket == PlanBucket.passados) return b.sortDate.compareTo(a.sortDate);
    return a.sortDate.compareTo(b.sortDate);
  });
  return sorted;
}
