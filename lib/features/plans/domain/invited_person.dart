import 'package:flutter/foundation.dart';
import '../../connections/domain/contact.dart';

@immutable
class InvitedPerson {
  const InvitedPerson({
    required this.nome,
    this.essencial = false,
    this.tipo = ConnectionType.amigos,
    this.existingContactId,
    this.linkedUserId,
  });

  final String nome;
  final bool essencial;
  final ConnectionType tipo;
  final String? existingContactId;

  /// Conexão vinculada: a pessoa já entra no rolê com a conta dela.
  final String? linkedUserId;

  InvitedPerson copyWith({
    String? nome,
    bool? essencial,
    ConnectionType? tipo,
    String? existingContactId,
    String? linkedUserId,
  }) =>
      InvitedPerson(
        nome: nome ?? this.nome,
        essencial: essencial ?? this.essencial,
        tipo: tipo ?? this.tipo,
        existingContactId: existingContactId ?? this.existingContactId,
        linkedUserId: linkedUserId ?? this.linkedUserId,
      );
}
