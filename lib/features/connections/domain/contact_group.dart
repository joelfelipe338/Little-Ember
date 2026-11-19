import 'package:flutter/foundation.dart';

/// Cores disponíveis para um grupo (mesmos nomes da paleta do app).
enum GroupColor { lavanda, brasa, menta, sol, neblina }

/// Grupo de conexões, ex.: "Galera do vôlei". Uma pessoa pode estar em vários.
@immutable
class ContactGroup {
  const ContactGroup({
    required this.id,
    required this.nome,
    this.cor = GroupColor.lavanda,
    this.memberIds = const {},
    this.createdAt,
  });

  final String id;
  final String nome;
  final GroupColor cor;

  /// IDs das conexões (tabela `connections`) que estão no grupo.
  final Set<String> memberIds;
  final DateTime? createdAt;

  bool contains(String? contactId) => contactId != null && memberIds.contains(contactId);

  /// Espera a linha com o join `contact_group_members(connection_id)`.
  factory ContactGroup.fromSupabase(Map<String, dynamic> row) {
    final members = (row['contact_group_members'] as List?) ?? const [];
    return ContactGroup(
      id: row['id'] as String,
      nome: row['nome'] as String,
      cor: GroupColor.values.asNameMap()[row['cor'] as String?] ?? GroupColor.lavanda,
      memberIds: {for (final m in members) (m as Map<String, dynamic>)['connection_id'] as String},
      createdAt: row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : null,
    );
  }
}
