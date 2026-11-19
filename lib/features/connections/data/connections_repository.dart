import '../../../core/supabase/supabase_client.dart';
import '../../plans/domain/invited_person.dart';
import '../domain/brasa.dart';
import '../domain/contact.dart';
import '../domain/contact_group.dart';
import '../domain/link_request.dart';

class ConnectionsRepository {
  String get _userId => supabase.auth.currentUser!.id;

  // ---------------------------------------------------------------- pessoas

  Future<List<Contact>> getMyContacts() async {
    final rows = await supabase
        .from('connections')
        .select()
        .eq('criado_por', _userId)
        .order('nome');
    return rows.map(Contact.fromSupabase).toList();
  }

  Future<Contact> createContact({
    required String nome,
    required ConnectionType tipo,
  }) async {
    final rows = await supabase.from('connections').insert({
      'nome': nome,
      'tipo': tipo.name,
      'criado_por': _userId,
    }).select();
    return Contact.fromSupabase(rows.first);
  }

  Future<Contact> updateContact({
    required String id,
    required String nome,
    required ConnectionType tipo,
  }) async {
    final row = await supabase
        .from('connections')
        .update({'nome': nome, 'tipo': tipo.name})
        .eq('id', id)
        .select()
        .single();
    return Contact.fromSupabase(row);
  }

  Future<void> deleteContact(String id) async {
    await supabase.from('connections').delete().eq('id', id);
  }

  Future<void> saveContacts(List<InvitedPerson> people) async {
    final newPeople =
        people.where((p) => p.existingContactId == null).toList();
    if (newPeople.isEmpty) return;

    await supabase.from('connections').insert(
          newPeople
              .map((p) => {
                    'nome': p.nome,
                    'tipo': p.tipo.name,
                    'criado_por': _userId,
                  })
              .toList(),
        );
  }

  // ---------------------------------------------------------------- grupos

  Future<List<ContactGroup>> getMyGroups() async {
    final rows = await supabase
        .from('contact_groups')
        .select('*, contact_group_members(connection_id)')
        .eq('criado_por', _userId)
        .order('nome');
    return rows.map(ContactGroup.fromSupabase).toList();
  }

  Future<ContactGroup> createGroup({
    required String nome,
    required GroupColor cor,
    required Set<String> memberIds,
  }) async {
    final row = await supabase
        .from('contact_groups')
        .insert({'nome': nome, 'cor': cor.name, 'criado_por': _userId})
        .select()
        .single();
    final groupId = row['id'] as String;
    await _insertMembers(groupId, memberIds);
    return ContactGroup(id: groupId, nome: nome, cor: cor, memberIds: memberIds);
  }

  Future<void> updateGroup({
    required String id,
    required String nome,
    required GroupColor cor,
    required Set<String> memberIds,
  }) async {
    await supabase.from('contact_groups').update({'nome': nome, 'cor': cor.name}).eq('id', id);
    await supabase.from('contact_group_members').delete().eq('group_id', id);
    await _insertMembers(id, memberIds);
  }

  Future<void> deleteGroup(String id) async {
    await supabase.from('contact_groups').delete().eq('id', id);
  }

  /// Define em quais grupos a pessoa está (substitui os anteriores).
  Future<void> setContactGroups(String contactId, Set<String> groupIds) async {
    await supabase.from('contact_group_members').delete().eq('connection_id', contactId);
    if (groupIds.isEmpty) return;
    await supabase.from('contact_group_members').insert([
      for (final g in groupIds) {'group_id': g, 'connection_id': contactId},
    ]);
  }

  Future<void> _insertMembers(String groupId, Set<String> memberIds) async {
    if (memberIds.isEmpty) return;
    await supabase.from('contact_group_members').insert([
      for (final m in memberIds) {'group_id': groupId, 'connection_id': m},
    ]);
  }

  // ---------------------------------------------------------------- brasa

  /// Último rolê (não cancelado) com cada pessoa, por ID da conexão.
  Future<Map<String, LastPlan>> getLastPlans(List<String> contactIds) async {
    if (contactIds.isEmpty) return {};
    final rows = await supabase
        .from('plan_members')
        .select('connection_id, plans(titulo, created_at, status)')
        .inFilter('connection_id', contactIds);

    final result = <String, LastPlan>{};
    for (final r in rows) {
      final id = r['connection_id'] as String?;
      final plan = r['plans'] as Map<String, dynamic>?;
      if (id == null || plan == null || plan['status'] == 'cancelado') continue;
      final data = DateTime.parse(plan['created_at'] as String).toLocal();
      final current = result[id];
      if (current == null || data.isAfter(current.data)) {
        result[id] = LastPlan(titulo: plan['titulo'] as String, data: data);
      }
    }
    return result;
  }

  // ---------------------------------------------------------------- vínculo

  /// Pede pra vincular com quem organizou, a partir da vaga no rolê.
  /// Retorna 'pendente' ou 'aceito' (se já estava vinculado).
  Future<String> requestLink(String planMemberId) async {
    final result = await supabase.rpc('request_link', params: {'p_member_id': planMemberId});
    return result as String;
  }

  /// Quem criou a conexão aceita (vira conexão real dos dois lados) ou recusa.
  Future<void> respondLink(String requestId, {required bool accept}) async {
    await supabase.rpc('respond_link', params: {'p_request_id': requestId, 'p_accept': accept});
  }

  /// Pedidos de vínculo esperando a minha resposta.
  Future<List<LinkRequest>> getPendingLinkRequests() async {
    final rows = await supabase
        .from('link_requests')
        .select(
          '*, connection:connections(nome), requester:profiles!link_requests_requester_id_fkey(nome)',
        )
        .eq('owner_id', _userId)
        .eq('status', 'pendente')
        .order('created_at');
    return rows.map(LinkRequest.fromSupabase).toList();
  }

  /// Situação do meu pedido de vínculo para uma conexão (null = nunca pedi).
  Future<String?> getMyLinkStatus(String connectionId) async {
    final row = await supabase
        .from('link_requests')
        .select('status')
        .eq('connection_id', connectionId)
        .eq('requester_id', _userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['status'] as String?;
  }
}
