import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/subscription.dart';

/// Limites de todos os planos (tabela `plan_limits`), por plano.
final planLimitsProvider = FutureProvider<Map<String, Map<PlanFeature, int>>>((ref) async {
  final rows = await supabase.from('plan_limits').select();
  final byDb = {for (final f in PlanFeature.values) f.db: f};
  final result = <String, Map<PlanFeature, int>>{};
  for (final r in rows) {
    final f = byDb[r['recurso'] as String];
    if (f == null) continue;
    (result[r['plano'] as String] ??= {})[f] = r['valor'] as int;
  }
  return result;
});

/// Plano do usuário logado com os limites valendo agora.
final subscriptionProvider = Provider<Subscription>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final isPlus = profile?.isPlus ?? false;
  final table = ref.watch(planLimitsProvider).valueOrNull;
  final limits = table?[isPlus ? 'plus' : 'gratis'] ??
      (isPlus ? Subscription.plusPadrao : Subscription.gratisPadrao);
  return Subscription(isPlus: isPlus, expiraEm: profile?.planoExpiraEm, limits: limits);
});
