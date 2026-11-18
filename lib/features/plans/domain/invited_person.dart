import 'package:flutter/foundation.dart';
import '../../connections/domain/contact.dart';

@immutable
class InvitedPerson {
  const InvitedPerson({
    required this.nome,
    this.essencial = false,
    this.tipo = ConnectionType.amigos,
    this.existingContactId,
  });

  final String nome;
  final bool essencial;
  final ConnectionType tipo;
  final String? existingContactId;

  InvitedPerson copyWith({
    String? nome,
    bool? essencial,
    ConnectionType? tipo,
    String? existingContactId,
  }) =>
      InvitedPerson(
        nome: nome ?? this.nome,
        essencial: essencial ?? this.essencial,
        tipo: tipo ?? this.tipo,
        existingContactId: existingContactId ?? this.existingContactId,
      );
}
