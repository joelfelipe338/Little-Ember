import 'package:flutter/foundation.dart';

enum MemberRole { organizador, convidado }

@immutable
class PlanMember {
  const PlanMember({
    required this.id,
    required this.planId,
    this.userId,
    required this.nome,
    this.papel = MemberRole.convidado,
    this.createdAt,
  });

  final String id;
  final String planId;
  final String? userId;
  final String nome;
  final MemberRole papel;
  final DateTime? createdAt;

  bool get isOrganizador => papel == MemberRole.organizador;

  factory PlanMember.fromSupabase(Map<String, dynamic> row) => PlanMember(
        id: row['id'] as String,
        planId: row['plan_id'] as String,
        userId: row['user_id'] as String?,
        nome: (row['nome_exibicao'] as String?)?.trim().isNotEmpty == true
            ? row['nome_exibicao'] as String
            : 'Sem nome',
        papel: MemberRole.values.byName(row['papel'] as String),
        createdAt: row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : null,
      );
}
