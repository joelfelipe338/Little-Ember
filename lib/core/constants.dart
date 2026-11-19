abstract final class AppConstants {
  static const appName = 'CHAMMA';
  static const slogan = 'Hora de acender uma chamma.';
  static const sloganCurto = 'Acende a chamma.';

  static const supabaseUrl = 'https://gqkaczrraugnwqtqomox.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdxa2FjenJyYXVnbndxdHFvbW94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0Nzk1NTIsImV4cCI6MjEwODA1NTU1Mn0.QLC1WZaMisHGppJmCD9B-FryKkiDUGF8eK8J28dnzv0';

  /// Site do CHAMMA (GitHub Pages com domínio próprio). O convidado abre `<base>/#/r/<slug>`.
  /// No celular com o app instalado, esse mesmo link abre direto no app (App Links / Universal Links).
  static const webHost = 'chamma.site';
  static const webBaseUrl = 'https://$webHost';
  static String guestLink(String slug) => '$webBaseUrl/#/r/$slug';

  /// Abre o rolê direto no app instalado (Android/iOS registram o esquema `chamma://`).
  static const appScheme = 'chamma';
  static const appHost = 'chamma.app';
  static String appLink(String slug) => '$appScheme://$appHost/r/$slug';

  static const fusos = [
    'UTC-12', 'UTC-11', 'UTC-10', 'UTC-9:30', 'UTC-9', 'UTC-8',
    'UTC-7', 'UTC-6', 'UTC-5', 'UTC-4', 'UTC-3', 'UTC-2',
    'UTC-1', 'UTC+0', 'UTC+1', 'UTC+2', 'UTC+3', 'UTC+3:30',
    'UTC+4', 'UTC+4:30', 'UTC+5', 'UTC+5:30', 'UTC+5:45',
    'UTC+6', 'UTC+6:30', 'UTC+7', 'UTC+8', 'UTC+8:45',
    'UTC+9', 'UTC+9:30', 'UTC+10', 'UTC+10:30', 'UTC+11',
    'UTC+12', 'UTC+12:45', 'UTC+13', 'UTC+14',
  ];

  static String detectFuso() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    final sign = hours >= 0 ? '+' : '';
    final label = minutes == 0
        ? 'UTC$sign$hours'
        : 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
    return fusos.contains(label) ? label : 'UTC-3';
  }

  static const defaultPrazoHoras = 48;
  static const minQuorum = 2;
  static const maxTimeOptions = 6;
  static const maxPlaceOptions = 4;
}
