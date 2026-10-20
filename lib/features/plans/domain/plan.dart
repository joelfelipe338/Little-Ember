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
  final DateTime? createdAt;

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
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : null,
      );
}
