import 'package:flutter/foundation.dart';

enum PlanStatus { votando, fechado, cancelado, expirado }

@immutable
class Plan {
  const Plan({
    required this.id,
    required this.slug,
    required this.criadorId,
    this.connectionId,
    required this.titulo,
    required this.prazoVotacao,
    this.status = PlanStatus.votando,
    this.horarioFinalId,
    this.lugarFinalId,
    this.votosVisiveis = true,
    this.quorumMinimo = 0,
    this.semRespostaContaComo = 'nada',
    this.essencialVisivel = false,
    this.autoFechar = false,
    this.permitirSugestoes = false,
    this.votoAnonimo = false,
    this.limitePosso = 0,
    this.lembreteHoras = 0,
    this.createdAt,
  });

  final String id;
  final String slug;
  final String criadorId;
  final String? connectionId;
  final String titulo;
  final DateTime prazoVotacao;
  final PlanStatus status;
  final String? horarioFinalId;
  final String? lugarFinalId;
  final bool votosVisiveis;
  final int quorumMinimo;
  final String semRespostaContaComo;
  final bool essencialVisivel;
  final bool autoFechar;
  final bool permitirSugestoes;
  final bool votoAnonimo;
  final int limitePosso;
  final int lembreteHoras;
  final DateTime? createdAt;

  /// A votação ainda aceita votos (status "votando" e prazo no futuro).
  bool get isVotingOpen => status == PlanStatus.votando && prazoVotacao.isAfter(DateTime.now());

  /// Status "votando", mas o prazo já passou (aguardando o fechamento).
  bool get isPastDeadline => status == PlanStatus.votando && !prazoVotacao.isAfter(DateTime.now());

  factory Plan.fromSupabase(Map<String, dynamic> row) => Plan(
        id: row['id'] as String,
        slug: row['slug'] as String,
        criadorId: row['criador_id'] as String,
        connectionId: row['connection_id'] as String?,
        titulo: row['titulo'] as String,
        prazoVotacao: DateTime.parse(row['prazo_votacao'] as String),
        status: PlanStatus.values.byName(row['status'] as String),
        horarioFinalId: row['horario_final_id'] as String?,
        lugarFinalId: row['lugar_final_id'] as String?,
        votosVisiveis: (row['votos_visiveis'] as bool?) ?? true,
        quorumMinimo: (row['quorum_minimo'] as int?) ?? 0,
        semRespostaContaComo: (row['sem_resposta_conta_como'] as String?) ?? 'nada',
        essencialVisivel: (row['essencial_visivel'] as bool?) ?? false,
        autoFechar: (row['auto_fechar'] as bool?) ?? false,
        permitirSugestoes: (row['permitir_sugestoes'] as bool?) ?? false,
        votoAnonimo: (row['voto_anonimo'] as bool?) ?? false,
        limitePosso: (row['limite_posso'] as int?) ?? 0,
        lembreteHoras: (row['lembrete_horas'] as int?) ?? 0,
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : null,
      );
}
