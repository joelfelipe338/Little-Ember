import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;

/// Logado de verdade (email/senha, Google...), não a sessão anônima do convidado.
bool isRealUserSession() {
  final session = supabase.auth.currentSession;
  return session != null && !session.user.isAnonymous;
}
