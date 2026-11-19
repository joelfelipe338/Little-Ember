import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../plans/presentation/create_plan/plan_rules.dart';

/// Jeito de decidir que já vem marcado no Novo rolê (salvo no aparelho).
final defaultRuleModeProvider =
    StateNotifierProvider<DefaultRuleModeNotifier, RuleMode>((ref) => DefaultRuleModeNotifier());

class DefaultRuleModeNotifier extends StateNotifier<RuleMode> {
  DefaultRuleModeNotifier() : super(RuleMode.normal) {
    _load();
  }

  static const _key = 'modo_decidir_padrao';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = RuleMode.values.asNameMap()[prefs.getString(_key)];
      if (saved != null && mounted) state = saved;
    } catch (_) {}
  }

  Future<void> set(RuleMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}

/// Preferência de avisos (votos, prazos, pedidos de vínculo).
/// Por enquanto só guarda a escolha: as notificações ainda não são enviadas.
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsPrefNotifier, bool>((ref) => NotificationsPrefNotifier());

class NotificationsPrefNotifier extends StateNotifier<bool> {
  NotificationsPrefNotifier() : super(true) {
    _load();
  }

  static const _key = 'avisos_ligados';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_key);
      if (saved != null && mounted) state = saved;
    } catch (_) {}
  }

  Future<void> set(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}
