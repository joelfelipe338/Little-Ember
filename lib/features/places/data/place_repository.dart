import '../../../core/supabase/supabase_client.dart';
import '../domain/place.dart';

class PlaceRepository {
  Future<Place> createPlace(PlaceDraft d) async {
    final row = await supabase
        .from('places')
        .insert({
          'nome': d.nome,
          'endereco': d.endereco,
          'latitude': d.latitude,
          'longitude': d.longitude,
          'criado_por': supabase.auth.currentUser!.id,
        })
        .select()
        .single();
    return Place.fromSupabase(row);
  }

  Future<Place?> getPlace(String id) async {
    final row = await supabase.from('places').select().eq('id', id).maybeSingle();
    return row == null ? null : Place.fromSupabase(row);
  }

  /// Organizador escolhe ou troca o local de um rolê já criado.
  Future<Place> setPlanPlace({required String planId, required PlaceDraft draft}) async {
    final place = await createPlace(draft);
    await supabase.from('plans').update({'lugar_final_id': place.id}).eq('id', planId);
    return place;
  }

  Future<void> clearPlanPlace(String planId) async {
    await supabase.from('plans').update({'lugar_final_id': null}).eq('id', planId);
  }
}
