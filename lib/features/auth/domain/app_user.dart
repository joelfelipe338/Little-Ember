import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.nome,
    this.avatarUrl,
    this.fuso = 'UTC-3',
    this.email,
  });

  final String id;
  final String nome;
  final String? avatarUrl;
  final String fuso;
  final String? email;

  AppUser copyWith({
    String? id,
    String? nome,
    String? avatarUrl,
    String? fuso,
    String? email,
  }) =>
      AppUser(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        fuso: fuso ?? this.fuso,
        email: email ?? this.email,
      );

  factory AppUser.fromSupabase(Map<String, dynamic> row) => AppUser(
        id: row['id'] as String,
        nome: row['nome'] as String,
        avatarUrl: row['avatar_url'] as String?,
        fuso: (row['fuso'] as String?) ?? 'UTC-3',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'avatar_url': avatarUrl,
        'fuso': fuso,
      };
}
