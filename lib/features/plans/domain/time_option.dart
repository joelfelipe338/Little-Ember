import 'package:flutter/foundation.dart';

@immutable
class TimeOption {
  const TimeOption({
    this.id,
    this.planId,
    required this.inicioUtc,
    this.fimUtc,
  });

  final String? id;
  final String? planId;
  final DateTime inicioUtc;
  final DateTime? fimUtc;

  factory TimeOption.fromSupabase(Map<String, dynamic> row) => TimeOption(
        id: row['id'] as String,
        planId: row['plan_id'] as String,
        inicioUtc: DateTime.parse(row['inicio_utc'] as String),
        fimUtc: row['fim_utc'] != null
            ? DateTime.parse(row['fim_utc'] as String)
            : null,
      );

  Map<String, dynamic> toInsert(String planId) => {
        'plan_id': planId,
        'inicio_utc': inicioUtc.toUtc().toIso8601String(),
        if (fimUtc != null) 'fim_utc': fimUtc!.toUtc().toIso8601String(),
      };
}
