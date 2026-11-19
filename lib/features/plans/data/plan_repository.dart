import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../places/domain/place.dart';
import '../domain/invited_person.dart';
import '../domain/plan.dart';
import '../domain/plan_member.dart';
import '../domain/plan_overview.dart';
import '../domain/time_option.dart';
import '../domain/time_vote.dart';

class PlanRepository {
  String get _userId => supabase.auth.currentUser!.id;

  // ---------------------------------------------------------------- criar

  Future<Plan> createPlan({
    required String titulo,
    required DateTime prazoVotacao,
    required List<TimeOption> timeOptions,
    List<InvitedPerson> convidados = const [],
    bool votosVisiveis = true,
    int quorumMinimo = 0,
    String semRespostaContaComo = 'nada',
    bool essencialVisivel = false,
    bool autoFechar = false,
    bool permitirSugestoes = false,
    bool votoAnonimo = false,
    int limitePosso = 0,
    int lembreteHoras = 0,
    bool linkAberto = true,
    PlaceDraft? local,
  }) async {
    final planId = const Uuid().v4();
    final slug = planId.substring(0, 8);

    // Local escolhido no mapa vira um registro em `places`.
    String? lugarId;
    if (local != null) {
      final placeRow = await supabase.from('places').insert({
        'nome': local.nome,
        'endereco': local.endereco,
        'latitude': local.latitude,
        'longitude': local.longitude,
        'criado_por': _userId,
      }).select('id').single();
      lugarId = placeRow['id'] as String;
    }

    final profile = await supabase.from('profiles').select('nome').eq('id', _userId).maybeSingle();
    final nome = (profile?['nome'] as String?)?.trim();

    final planRow = await supabase.from('plans').insert({
      'id': planId,
      'slug': slug,
      'criador_id': _userId,
      'titulo': titulo,
      'lugar_final_id': lugarId,
      'prazo_votacao': prazoVotacao.toUtc().toIso8601String(),
      'votos_visiveis': votosVisiveis,
      'quorum_minimo': quorumMinimo,
      'sem_resposta_conta_como': semRespostaContaComo,
      'essencial_visivel': essencialVisivel,
      'auto_fechar': autoFechar,
      'permitir_sugestoes': permitirSugestoes,
      'voto_anonimo': votoAnonimo,
      'limite_posso': limitePosso,
      'lembrete_horas': lembreteHoras,
      'link_aberto': linkAberto,
    }).select().single();

    await supabase.from('plan_members').insert({
      'plan_id': planId,
      'user_id': _userId,
      'nome_exibicao': (nome == null || nome.isEmpty) ? 'Organizador' : nome,
      'papel': 'organizador',
    });

    if (convidados.isNotEmpty) {
      await supabase.from('plan_members').insert(
        convidados
            .map((c) => {
                  'plan_id': planId,
                  'nome_exibicao': c.nome,
                  'papel': 'convidado',
                  'essencial': c.essencial,
                  // Liga o convidado à conexão (brasa / último rolê juntos).
                  'connection_id': c.existingContactId,
                  // Conexão vinculada entra já com a conta da pessoa (o rolê aparece no app dela).
                  'user_id': c.linkedUserId,
                })
            .toList(),
      );
    }

    if (timeOptions.isNotEmpty) {
      await supabase.from('time_options').insert(
        timeOptions.map((t) => t.toInsert(planId)).toList(),
      );
    }

    return Plan.fromSupabase(planRow);
  }

  Future<void> addTimeOption({required String planId, required DateTime inicio}) async {
    await supabase.from('time_options').insert({
      'plan_id': planId,
      'inicio_utc': inicio.toUtc().toIso8601String(),
    });
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

  /// Junta galera, horários e votos dos rolês pra montar a lista (3 consultas no total).
  Future<List<PlanOverview>> getPlanOverviews(List<Plan> plans) async {
    if (plans.isEmpty) return [];
    final ids = [for (final p in plans) p.id];

    final memberRows = await supabase.from('plan_members').select().inFilter('plan_id', ids).order('created_at');
    final optionRows = await supabase.from('time_options').select().inFilter('plan_id', ids).order('inicio_utc');
    final options = optionRows.map(TimeOption.fromSupabase).toList();
    final optionIds = [for (final o in options) o.id!];
    final voteRows = optionIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await supabase.from('time_votes').select().inFilter('time_option_id', optionIds);

    final members = memberRows.map(PlanMember.fromSupabase).toList();
    final votes = voteRows.map(TimeVote.fromSupabase).toList();
    final optionPlan = {for (final o in options) o.id!: o.planId};

    // Nome do local de cada rolê (pra mostrar na lista).
    final placeIds = {for (final p in plans) if (p.lugarFinalId != null) p.lugarFinalId!}.toList();
    final placeRows = placeIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await supabase.from('places').select('id, nome').inFilter('id', placeIds);
    final placeNames = {for (final r in placeRows) r['id'] as String: r['nome'] as String};

    return [
      for (final plan in plans)
        PlanOverview(
          plan: plan,
          members: [for (final m in members) if (m.planId == plan.id) m],
          options: [for (final o in options) if (o.planId == plan.id) o],
          votes: [for (final v in votes) if (optionPlan[v.timeOptionId] == plan.id) v],
          myUserId: _userId,
          placeName: plan.lugarFinalId == null ? null : placeNames[plan.lugarFinalId],
        ),
    ];
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

  /// Convidados pré-adicionados que ainda não reivindicaram sua vaga.
  Future<List<PlanMember>> getUnclaimedMembers(String planId) async {
    final rows = await supabase
        .from('plan_members')
        .select()
        .eq('plan_id', planId)
        .isFilter('user_id', null)
        .eq('papel', 'convidado')
        .order('nome_exibicao');
    return rows.map(PlanMember.fromSupabase).toList();
  }

  /// Convidado reivindica uma vaga pré-adicionada (seta user_id).
  Future<PlanMember> claimMember({required String memberId}) async {
    if (supabase.auth.currentSession == null) {
      await supabase.auth.signInAnonymously();
    }
    final row = await supabase
        .from('plan_members')
        .update({'user_id': _userId})
        .eq('id', memberId)
        .isFilter('user_id', null)
        .select()
        .single();
    return PlanMember.fromSupabase(row);
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
