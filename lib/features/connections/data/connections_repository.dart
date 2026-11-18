import '../../../core/supabase/supabase_client.dart';
import '../../plans/domain/invited_person.dart';
import '../domain/contact.dart';

class ConnectionsRepository {
  String get _userId => supabase.auth.currentUser!.id;

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
}
