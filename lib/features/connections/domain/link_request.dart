import 'package:flutter/foundation.dart';

/// Pedido pra transformar uma conexão salva por nome numa conexão real
/// (as duas pessoas com o app). Quem criou a conexão aceita ou recusa.
@immutable
class LinkRequest {
  const LinkRequest({
    required this.id,
    required this.connectionId,
    required this.contactName,
    required this.requesterName,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String connectionId;

  /// Nome que o dono deu à conexão (ex.: "Maria Clara").
  final String contactName;

  /// Nome do perfil de quem pediu (ex.: "Maria").
  final String requesterName;
  final String status;
  final DateTime? createdAt;

  factory LinkRequest.fromSupabase(Map<String, dynamic> row) {
    final conn = row['connection'] as Map<String, dynamic>?;
    final req = row['requester'] as Map<String, dynamic>?;
    return LinkRequest(
      id: row['id'] as String,
      connectionId: row['connection_id'] as String,
      contactName: (conn?['nome'] as String?) ?? 'Conexão',
      requesterName: (req?['nome'] as String?) ?? 'Alguém',
      status: row['status'] as String,
      createdAt: row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : null,
    );
  }
}
