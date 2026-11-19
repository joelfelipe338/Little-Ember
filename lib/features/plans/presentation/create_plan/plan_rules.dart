import 'package:flutter/foundation.dart';

/// Modos prontos de decidir o rolê.
enum RuleMode {
  normal('Normal', 'Configuração padrão'),
  rapido('Rápido', 'Para agilizar'),
  secreto('Secreto', 'Votos ocultos');

  const RuleMode(this.titulo, this.descricao);
  final String titulo;
  final String descricao;
}

/// Regras da votação escolhidas no Novo rolê.
@immutable
class PlanRules {
  const PlanRules({
    this.essencialVisivel = false,
    this.quorumMinimo = 0,
    this.autoFechar = false,
    this.permitirSugestoes = false,
    this.votoAnonimo = false,
    this.limitePosso = 0,
    this.lembreteHoras = 0,
  });

  final bool essencialVisivel;

  /// Mínimo de votos pra fechar o rolê.
  final int quorumMinimo;
  final bool autoFechar;
  final bool permitirSugestoes;
  final bool votoAnonimo;
  final int limitePosso;

  /// Horas antes do prazo pra avisar quem não votou (0 = não avisa).
  final int lembreteHoras;

  /// Lembrete padrão pra quem não votou.
  static const lembretePadrao = 2;

  /// Metade de quem vai votar (convidados + organizador), arredondando pra cima.
  /// Nunca menos que 2, pra não fechar só com o voto do organizador.
  static int minimoVotos(int convidados) {
    final total = convidados + 1;
    final metade = (total + 1) ~/ 2;
    return metade < 2 ? 2 : metade;
  }

  /// As regras de cada modo pronto.
  static PlanRules preset(RuleMode mode, {required int convidados}) {
    final minimo = minimoVotos(convidados);
    return switch (mode) {
      // Padrão: mínimo = metade, avisa quem não votou, mostra essenciais.
      RuleMode.normal => PlanRules(
          quorumMinimo: minimo,
          lembreteHoras: lembretePadrao,
          essencialVisivel: true,
          permitirSugestoes: true,
        ),
      // Rápido: fecha sozinho no mínimo, 1 "Posso" por pessoa, sem essencial à vista.
      RuleMode.rapido => PlanRules(
          quorumMinimo: minimo,
          autoFechar: true,
          limitePosso: 1,
          lembreteHoras: lembretePadrao,
        ),
      // Secreto: ninguém vê votos nem essenciais, sem aviso e sem sugestões.
      RuleMode.secreto => PlanRules(
          quorumMinimo: minimo,
          votoAnonimo: true,
        ),
    };
  }

  /// Modo pronto que bate com estas regras (null = personalizado).
  RuleMode? modeFor(int convidados) {
    for (final m in RuleMode.values) {
      if (preset(m, convidados: convidados) == this) return m;
    }
    return null;
  }

  PlanRules copyWith({
    bool? essencialVisivel,
    int? quorumMinimo,
    bool? autoFechar,
    bool? permitirSugestoes,
    bool? votoAnonimo,
    int? limitePosso,
    int? lembreteHoras,
  }) =>
      PlanRules(
        essencialVisivel: essencialVisivel ?? this.essencialVisivel,
        quorumMinimo: quorumMinimo ?? this.quorumMinimo,
        autoFechar: autoFechar ?? this.autoFechar,
        permitirSugestoes: permitirSugestoes ?? this.permitirSugestoes,
        votoAnonimo: votoAnonimo ?? this.votoAnonimo,
        limitePosso: limitePosso ?? this.limitePosso,
        lembreteHoras: lembreteHoras ?? this.lembreteHoras,
      );

  /// O que estas regras fazem, em frases curtas (mostrado sob os modos).
  List<String> get descricao => [
        quorumMinimo > 0
            ? '${autoFechar ? 'Fecha sozinho com' : 'Pode fechar com'} $quorumMinimo ${quorumMinimo == 1 ? 'voto' : 'votos'}'
            : 'Fecha quando você quiser',
        votoAnonimo ? 'Ninguém vê os votos' : 'Todo mundo vê os votos',
        lembreteHoras > 0 ? 'Avisa quem não votou ${lembreteHoras}h antes do prazo' : 'Não avisa quem não votou',
        if (limitePosso > 0) 'Cada um marca "Posso" em até $limitePosso ${limitePosso == 1 ? 'horário' : 'horários'}',
        if (permitirSugestoes) 'A galera pode sugerir horário',
        essencialVisivel ? 'Mostra quem é essencial' : 'Não mostra quem é essencial',
      ];

  /// Resumo curto pra linha fechada dos ajustes finos.
  String get resumo => [
        if (quorumMinimo > 0) 'MÍN. $quorumMinimo',
        if (autoFechar) 'AUTO',
        if (lembreteHoras > 0) 'AVISO ${lembreteHoras}H',
        if (limitePosso > 0) 'LIMITE $limitePosso',
      ].join(' · ');

  @override
  bool operator ==(Object other) =>
      other is PlanRules &&
      other.essencialVisivel == essencialVisivel &&
      other.quorumMinimo == quorumMinimo &&
      other.autoFechar == autoFechar &&
      other.permitirSugestoes == permitirSugestoes &&
      other.votoAnonimo == votoAnonimo &&
      other.limitePosso == limitePosso &&
      other.lembreteHoras == lembreteHoras;

  @override
  int get hashCode => Object.hash(
        essencialVisivel,
        quorumMinimo,
        autoFechar,
        permitirSugestoes,
        votoAnonimo,
        limitePosso,
        lembreteHoras,
      );
}
