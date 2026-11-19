import 'package:flutter/foundation.dart';

import 'contact.dart';

/// Último rolê (não cancelado) que você organizou com a pessoa.
@immutable
class LastPlan {
  const LastPlan({required this.titulo, required this.data});

  final String titulo;
  final DateTime data;
}

/// Temperatura da brasa com a pessoa, pelo tempo desde o último rolê.
enum BrasaLevel { quente, morna, fria }

/// A partir de quantos dias sem rolê a brasa conta como "esfriando".
const diasParaEsfriar = 30;

int? daysSince(LastPlan? last, {DateTime? now}) =>
    last == null ? null : (now ?? DateTime.now()).difference(last.data).inDays;

BrasaLevel brasaOf(LastPlan? last, {DateTime? now}) {
  final d = daysSince(last, now: now);
  if (d == null) return BrasaLevel.fria;
  if (d <= 14) return BrasaLevel.quente;
  if (d <= diasParaEsfriar) return BrasaLevel.morna;
  return BrasaLevel.fria;
}

/// "Churras de sábado · há 5 dias" ou "Ainda sem rolê juntos".
String brasaSubtitle(LastPlan? last, {DateTime? now}) {
  final d = daysSince(last, now: now);
  if (last == null || d == null) return 'Ainda sem rolê juntos';
  return '${last.titulo} · ${relativeDays(d)}';
}

String relativeDays(int d) {
  if (d <= 0) return 'hoje';
  if (d == 1) return 'ontem';
  if (d < 30) return 'há $d dias';
  final meses = d ~/ 30;
  return meses == 1 ? 'há 1 mês' : 'há $meses meses';
}

// ---------------------------------------------------------------- ordenação

enum ContactSort {
  nome('Nome (A–Z)', 'NOME'),
  brasa('Brasa esfriando primeiro', 'BRASA'),
  ultimoRole('Último rolê mais recente', 'ÚLTIMO ROLÊ'),
  recentes('Adicionados por último', 'RECENTES');

  const ContactSort(this.label, this.short);
  final String label;
  final String short;
}

List<Contact> sortContacts(
  Iterable<Contact> contacts,
  ContactSort sort,
  Map<String, LastPlan> lastPlans,
) {
  int byName(Contact a, Contact b) => normalizeName(a.nome).compareTo(normalizeName(b.nome));
  DateTime? last(Contact c) => c.id == null ? null : lastPlans[c.id]?.data;

  final list = [...contacts];
  list.sort((a, b) {
    switch (sort) {
      case ContactSort.nome:
        return byName(a, b);
      case ContactSort.brasa:
      case ContactSort.ultimoRole:
        final la = last(a), lb = last(b);
        // Quem nunca teve rolê vai pro fim nas duas ordens.
        if (la == null && lb == null) return byName(a, b);
        if (la == null) return 1;
        if (lb == null) return -1;
        final cmp = sort == ContactSort.brasa ? la.compareTo(lb) : lb.compareTo(la);
        return cmp != 0 ? cmp : byName(a, b);
      case ContactSort.recentes:
        final ca = a.createdAt, cb = b.createdAt;
        if (ca == null || cb == null) return byName(a, b);
        return cb.compareTo(ca);
    }
  });
  return list;
}

/// Minúsculas e sem acento, para busca, ordem e aviso de nome repetido.
String normalizeName(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final lower = s.trim().toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
}
