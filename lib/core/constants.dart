abstract final class AppConstants {
  static const appName = 'CHAMMA';
  static const slogan = 'A chama que mantém a amizade acesa.';
  static const sloganCurto = 'Mantém a galera acesa.';

  static const supabaseUrl = 'https://gqkaczrraugnwqtqomox.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdxa2FjenJyYXVnbndxdHFvbW94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0Nzk1NTIsImV4cCI6MjEwODA1NTU1Mn0.QLC1WZaMisHGppJmCD9B-FryKkiDUGF8eK8J28dnzv0';

  /// Endereço público do app web (GitHub Pages). O convidado abre `<base>/#/r/<slug>`.
  /// Se mudar de domínio ou renomear o repositório, troque só aqui.
  static const webBaseUrl = 'https://joelfelipe338.github.io/Little-Ember';
  static String guestLink(String slug) => '$webBaseUrl/#/r/$slug';

  static const defaultPrazoHoras = 48;
  static const minQuorum = 2;
  static const maxTimeOptions = 6;
  static const maxPlaceOptions = 4;
}
