import 'package:flutter/foundation.dart';

/// Recursos com limite por plano (mesmos nomes da tabela `plan_limits`).
enum PlanFeature {
  rolesAtivos('roles_ativos'),
  horariosPorRole('horarios_por_role'),
  pessoasPorRole('pessoas_por_role'),
  grupos('grupos'),
  modosAvancados('modos_avancados');

  const PlanFeature(this.db);
  final String db;
}

/// Plano do usuário + limites que valem pra ele agora.
@immutable
class Subscription {
  const Subscription({required this.isPlus, required this.expiraEm, required this.limits});

  final bool isPlus;
  final DateTime? expiraEm;
  final Map<PlanFeature, int> limits;

  /// Limites do plano grátis, usados enquanto a tabela não carrega.
  static const gratisPadrao = {
    PlanFeature.rolesAtivos: 3,
    PlanFeature.horariosPorRole: 5,
    PlanFeature.pessoasPorRole: 15,
    PlanFeature.grupos: 3,
    PlanFeature.modosAvancados: 0,
  };

  static const plusPadrao = {
    PlanFeature.rolesAtivos: 1000,
    PlanFeature.horariosPorRole: 15,
    PlanFeature.pessoasPorRole: 200,
    PlanFeature.grupos: 1000,
    PlanFeature.modosAvancados: 1,
  };

  static const gratis = Subscription(isPlus: false, expiraEm: null, limits: gratisPadrao);

  int limit(PlanFeature f) => limits[f] ?? (isPlus ? plusPadrao[f]! : gratisPadrao[f]!);

  /// Rápido e Secreto (fecha sozinho, voto secreto, limite de "Posso").
  bool get modosAvancados => limit(PlanFeature.modosAvancados) > 0;

  /// "ilimitado" quando o número é grande o bastante pra não importar.
  static String label(int n) => n >= 1000 ? 'Ilimitado' : '$n';
}

/// Erros do banco quando um limite do plano é atingido.
enum LimitError {
  rolesAtivos('limite_roles_ativos', 'Você chegou no limite de rolês em votação ao mesmo tempo.'),
  horarios('limite_horarios', 'Esse rolê chegou no limite de horários.'),
  pessoas('limite_pessoas', 'Esse rolê chegou no limite de pessoas.'),
  grupos('limite_grupos', 'Você chegou no limite de grupos.'),
  recursoPlus('recurso_plus', 'Esse modo é do CHAMMA+.');

  const LimitError(this.code, this.message);
  final String code;
  final String message;

  /// Descobre se um erro do Supabase é de limite do plano.
  static LimitError? from(Object error) {
    final text = error.toString();
    for (final e in values) {
      if (text.contains(e.code)) return e;
    }
    return null;
  }
}
