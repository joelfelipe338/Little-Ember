import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import 'plan.dart';
import 'time_option.dart';

/// Mensagem do convite pra mandar no WhatsApp (negrito com *asterisco*).
///
/// Exemplo:
/// ```
/// 🔥 *Churras de sábado*
/// Joel te chamou pro rolê!
///
/// 🗓️ *Quando pode ser?*
/// • Sex, 21/11 às 19:00
/// • Sáb, 22/11 às 15:00
///
/// 📍 Casa do Rafa
/// ⏳ Vota até sex, 21/11 às 12:00
///
/// 👉 Vota aqui, sem instalar nada:
/// https://...
/// ```
String buildInviteMessage({
  required Plan plan,
  required List<TimeOption> options,
  String? organizerName,
  String? local,
}) {
  final dia = DateFormat("EEE, dd/MM 'às' HH:mm", 'pt_BR');
  String fmt(DateTime d) {
    final s = dia.format(d.toLocal()).replaceAll('.', '');
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  final sorted = [...options]..sort((a, b) => a.inicioUtc.compareTo(b.inicioUtc));
  final quem = organizerName?.trim().split(' ').first;
  final prazo = DateFormat("EEE, dd/MM 'às' HH:mm", 'pt_BR').format(plan.prazoVotacao.toLocal()).replaceAll('.', '');

  final b = StringBuffer()
    ..writeln('🔥 *${plan.titulo.trim()}*')
    ..writeln(quem == null || quem.isEmpty ? 'Você foi chamado pro rolê!' : '$quem te chamou pro rolê!')
    ..writeln();

  if (sorted.isNotEmpty) {
    b.writeln(sorted.length == 1 ? '🗓️ *Quando:*' : '🗓️ *Quando pode ser?*');
    const max = 6;
    for (final o in sorted.take(max)) {
      b.writeln('• ${fmt(o.inicioUtc)}');
    }
    if (sorted.length > max) b.writeln('• e mais ${sorted.length - max} opções');
    b.writeln();
  }

  if (local != null && local.trim().isNotEmpty) b.writeln('📍 ${local.trim()}');
  b
    ..writeln('⏳ Vota até $prazo')
    ..writeln()
    ..writeln('👉 Vota aqui, sem instalar nada:')
    ..write(AppConstants.guestLink(plan.slug));

  return b.toString();
}

/// Cobrança pra quem ainda não votou ("Cutucar").
String buildReminderMessage({required Plan plan, required List<String> pendingNames}) {
  final prazo = DateFormat("EEE, dd/MM 'às' HH:mm", 'pt_BR').format(plan.prazoVotacao.toLocal()).replaceAll('.', '');
  final nomes = [for (final n in pendingNames) n.trim().split(' ').first];
  final quem = switch (nomes.length) {
    0 => 'Ainda dá tempo de votar!',
    1 => 'Falta só o voto de ${nomes.first}!',
    _ => 'Ainda faltam os votos de ${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}.',
  };
  return '⏰ *${plan.titulo.trim()}*\n'
      '$quem\n\n'
      '⏳ A votação fecha $prazo\n'
      '👉 ${AppConstants.guestLink(plan.slug)}';
}


/// Aviso de rolê fechado ("Fechou! Sábado às 19h, na Casa do Rafa").
String buildClosedMessage({required Plan plan, required DateTime quando, String? local, String? endereco}) {
  final d = DateFormat("EEEE, dd/MM 'às' HH:mm", 'pt_BR').format(quando.toLocal());
  final dia = d.isEmpty ? d : d[0].toUpperCase() + d.substring(1);
  final b = StringBuffer()
    ..writeln('🎉 *Fechou: ${plan.titulo.trim()}*')
    ..writeln()
    ..writeln('🗓️ $dia');
  if (local != null && local.trim().isNotEmpty) {
    b.writeln('📍 ${local.trim()}${endereco == null || endereco.trim().isEmpty ? '' : ' · ${endereco.trim()}'}');
  }
  b
    ..writeln()
    ..writeln('Detalhes e mapa:')
    ..write(AppConstants.guestLink(plan.slug));
  return b.toString();
}
