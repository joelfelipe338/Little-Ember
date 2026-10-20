import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/app_user.dart';

class AuthRepository {
  Session? get currentSession => supabase.auth.currentSession;
  String? get currentUserId => supabase.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String nome,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': nome},
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<AppUser?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    final user = AppUser.fromSupabase(row);
    final email = supabase.auth.currentUser?.email;
    return email != null ? user.copyWith(email: email) : user;
  }

  Future<void> updateProfile({
    String? nome,
    String? avatarUrl,
    String? fuso,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (nome != null) updates['nome'] = nome;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (fuso != null) updates['fuso'] = fuso;

    if (updates.isNotEmpty) {
      await supabase.from('profiles').update(updates).eq('id', userId);
    }
  }
}
