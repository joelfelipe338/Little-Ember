import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/plan.dart';
import '../domain/time_option.dart';

class PlanRepository {
  String get _userId => supabase.auth.currentUser!.id;

  Future<Plan> createPlan({
    required String titulo,
    required DateTime prazoVotacao,
    required List<TimeOption> timeOptions,
  }) async {
    final planId = const Uuid().v4();
    final slug = planId.substring(0, 8);

    final planRow = await supabase.from('plans').insert({
      'id': planId,
      'slug': slug,
      'criador_id': _userId,
      'titulo': titulo,
      'prazo_votacao': prazoVotacao.toUtc().toIso8601String(),
    }).select().single();

    await supabase.from('plan_members').insert({
      'plan_id': planId,
      'user_id': _userId,
      'nome_exibicao': '',
      'papel': 'organizador',
    });

    if (timeOptions.isNotEmpty) {
      await supabase.from('time_options').insert(
        timeOptions.map((t) => t.toInsert(planId)).toList(),
      );
    }

    return Plan.fromSupabase(planRow);
  }

  Future<List<Plan>> getMyPlans() async {
    final memberRows = await supabase
        .from('plan_members')
        .select('plan_id')
        .eq('user_id', _userId);

    final planIds = memberRows.map((r) => r['plan_id'] as String).toList();
    if (planIds.isEmpty) return [];

    final rows = await supabase
        .from('plans')
        .select()
        .inFilter('id', planIds)
        .order('created_at', ascending: false);

    return rows.map(Plan.fromSupabase).toList();
  }

  Future<Plan?> getPlan(String id) async {
    final row = await supabase
        .from('plans')
        .select()
        .eq('id', id)
        .maybeSingle();

    return row != null ? Plan.fromSupabase(row) : null;
  }

  Future<List<TimeOption>> getTimeOptions(String planId) async {
    final rows = await supabase
        .from('time_options')
        .select()
        .eq('plan_id', planId)
        .order('inicio_utc');

    return rows.map(TimeOption.fromSupabase).toList();
  }
}
