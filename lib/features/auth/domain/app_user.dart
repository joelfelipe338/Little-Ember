import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.nome,
    this.avatarUrl,
    this.fuso = 'UTC-3',
    this.email,
    this.codigoConvite,
    this.plano = 'gratis',
    this.planoExpiraEm,
  });

  final String id;
  final String nome;
  final String? avatarUrl;
  final String fuso;
  final String? email;

  /// Código pessoal pra convidar gente pro CHAMMA (ex.: "K7Q2MX").
  final String? codigoConvite;

  /// 'gratis' ou 'plus' (CHAMMA+). Só o servidor muda.
  final String plano;
  final DateTime? planoExpiraEm;

  /// CHAMMA+ valendo agora.
  bool get isPlus => plano == 'plus' && (planoExpiraEm == null || planoExpiraEm!.isAfter(DateTime.now()));

  AppUser copyWith({
    String? id,
    String? nome,
    String? avatarUrl,
    String? fuso,
    String? email,
    String? codigoConvite,
    String? plano,
    DateTime? planoExpiraEm,
  }) =>
      AppUser(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        fuso: fuso ?? this.fuso,
        email: email ?? this.email,
        codigoConvite: codigoConvite ?? this.codigoConvite,
        plano: plano ?? this.plano,
        planoExpiraEm: planoExpiraEm ?? this.planoExpiraEm,
      );

  factory AppUser.fromSupabase(Map<String, dynamic> row) => AppUser(
        id: row['id'] as String,
        nome: row['nome'] as String,
        avatarUrl: row['avatar_url'] as String?,
        fuso: (row['fuso'] as String?) ?? 'UTC-3',
        codigoConvite: row['codigo_convite'] as String?,
        plano: (row['plano'] as String?) ?? 'gratis',
        planoExpiraEm: row['plano_expira_em'] != null ? DateTime.parse(row['plano_expira_em'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'avatar_url': avatarUrl,
        'fuso': fuso,
      };
}
