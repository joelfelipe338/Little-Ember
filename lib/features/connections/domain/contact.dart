import 'package:flutter/foundation.dart';

enum ConnectionType { amigos, casal, familia, trabalho, outro }

@immutable
class Contact {
  const Contact({
    this.id,
    required this.nome,
    this.tipo = ConnectionType.amigos,
    this.criadoPor,
    this.createdAt,
  });

  final String? id;
  final String nome;
  final ConnectionType tipo;
  final String? criadoPor;
  final DateTime? createdAt;

  factory Contact.fromSupabase(Map<String, dynamic> row) => Contact(
        id: row['id'] as String,
        nome: row['nome'] as String,
        tipo: ConnectionType.values.byName(row['tipo'] as String),
        criadoPor: row['criado_por'] as String?,
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : null,
      );
}
