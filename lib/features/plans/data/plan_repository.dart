import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/plan.dart';
import '../domain/plan_member.dart';
import '../domain/time_option.dart';
import '../domain/time_vote.dart';

class PlanRepository {
  String get _userId => supabase.auth.currentUser!.id;

  // ---------------------------------------------------------------- criar

  Future<Plan> createPlan({
    required String titulo,
    required DateTime prazoVotacao,
    required List<TimeOption> timeOptions,
  }) async {
    final planId = const Uuid().v4();
    final slug = planId.substring(0, 8);

    // Nome do organizador, para aparecer na lista da galera.
    final profile = await supabase.from('profiles').select('nome').eq('id', _userId).maybeSingle();
    final nome = (profile?['nome'] as String?)?.trim();

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
      'nome_exibicao': (nome == null || nome.isEmpty) ? 'Organizador' : nome,
      'papel': 'organizador',
    });

    if (timeOptions.isNotEmpty) {
      await supabase.from('time_options').insert(
        timeOptions.map((t) => t.toInsert(planId)).toList(),
      );
    }

    return Plan.fromSupabase(planRow);
  }

  // ---------------------------------------------------------------- ler

  Future<List<Plan>> getMyPlans() async {
    final memberRows = await supabase
        .from('plan_members')
        .select('plan_id')
        .eq('user_id', _userId);

    final planIds = memberRows.map((r) => r['plan_id'] as String).toSet().toList();
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

  /// Rolê pelo código do link (`/r/<slug>`). Funciona sem login.
  Future<Plan?> getPlanBySlug(String slug) async {
    final row = await supabase
        .from('plans')
        .select()
        .eq('slug', slug)
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

  /// O registro do usuário logado como membro do rolê (null se não participa).
  Future<PlanMember?> getMyMember(String planId) async {
    final row = await supabase
        .from('plan_members')
        .select()
        .eq('plan_id', planId)
        .eq('user_id', _userId)
        .maybeSingle();
    return row != null ? PlanMember.fromSupabase(row) : null;
  }

  // ---------------------------------------------------------------- ao vivo (Realtime)

  Stream<List<PlanMember>> watchMembers(String planId) => supabase
      .from('plan_members')
      .stream(primaryKey: ['id'])
      .eq('plan_id', planId)
      .order('created_at')
      .map((rows) => rows.map(PlanMember.fromSupabase).toList());

  Stream<List<TimeVote>> watchVotes(List<String> timeOptionIds) {
    if (timeOptionIds.isEmpty) return Stream.value(const []);
    return supabase
        .from('time_votes')
        .stream(primaryKey: ['id'])
        .inFilter('time_option_id', timeOptionIds)
        .map((rows) => rows.map(TimeVote.fromSupabase).toList());
  }

  // ---------------------------------------------------------------- convidado

  /// Entra no rolê como convidado. Quem não tem conta ganha uma sessão anônima
  /// do Supabase (fica salva no navegador, então o voto continua editável).
  Future<PlanMember> joinPlan({required String planId, required String nome}) async {
    if (supabase.auth.currentSession == null) {
      await supabase.auth.signInAnonymously();
    }
    final existing = await getMyMember(planId);
    if (existing != null) return existing;

    final row = await supabase.from('plan_members').insert({
      'plan_id': planId,
      'user_id': _userId,
      'nome_exibicao': nome,
      'papel': 'convidado',
    }).select().single();
    return PlanMember.fromSupabase(row);
  }

  /// Membro do usuário atual no rolê, sem exigir sessão (null para visitante).
  Future<PlanMember?> getMyMemberIfAny(String planId) async {
    if (supabase.auth.currentUser == null) return null;
    return getMyMember(planId);
  }

  // ---------------------------------------------------------------- ações

  /// Registra (ou troca) o voto de um membro numa opção de horário.
  Future<void> vote({
    required String timeOptionId,
    required String memberId,
    required Disp disp,
  }) async {
    await supabase.from('time_votes').upsert(
      {'time_option_id': timeOptionId, 'member_id': memberId, 'disp': disp.db},
      onConflict: 'time_option_id,member_id',
    );
  }

  /// Fecha a votação com o horário escolhido.
  Future<void> closePlan({required String planId, required String timeOptionId}) async {
    await supabase
        .from('plans')
        .update({'status': 'fechado', 'horario_final_id': timeOptionId})
        .eq('id', planId);
  }

  Future<void> cancelPlan(String planId) async {
    await supabase.from('plans').update({'status': 'cancelado'}).eq('id', planId);
  }
}
