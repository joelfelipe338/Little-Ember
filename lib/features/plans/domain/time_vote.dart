import 'package:flutter/foundation.dart';

/// Disponibilidade de um membro para uma opção de horário (enum `vote_disp` no banco).
enum Disp {
  posso('posso'),
  talvez('talvez'),
  naoPosso('nao_posso');

  const Disp(this.db);
  final String db;

  static Disp fromDb(String value) => Disp.values.firstWhere((d) => d.db == value);
}

@immutable
class TimeVote {
  const TimeVote({
    required this.id,
    required this.timeOptionId,
    required this.memberId,
    required this.disp,
  });

  final String id;
  final String timeOptionId;
  final String memberId;
  final Disp disp;

  factory TimeVote.fromSupabase(Map<String, dynamic> row) => TimeVote(
        id: row['id'] as String,
        timeOptionId: row['time_option_id'] as String,
        memberId: row['member_id'] as String,
        disp: Disp.fromDb(row['disp'] as String),
      );
}
