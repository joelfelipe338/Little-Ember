import 'package:flutter/foundation.dart';

/// Local escolhido no mapa, antes de ser salvo.
@immutable
class PlaceDraft {
  const PlaceDraft({required this.nome, required this.endereco, required this.latitude, required this.longitude});

  final String nome;
  final String endereco;
  final double latitude;
  final double longitude;

  PlaceDraft copyWith({String? nome, String? endereco, double? latitude, double? longitude}) => PlaceDraft(
        nome: nome ?? this.nome,
        endereco: endereco ?? this.endereco,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}

/// Local salvo (tabela `places`).
@immutable
class Place {
  const Place({
    required this.id,
    required this.nome,
    required this.endereco,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String nome;
  final String endereco;
  final double? latitude;
  final double? longitude;

  bool get hasCoords => latitude != null && longitude != null;

  /// Abre no app de mapas do celular (ou no Google Maps no navegador).
  Uri get mapsUri => hasCoords
      ? Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$latitude,$longitude'})
      : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$nome $endereco'});

  PlaceDraft? get asDraft => hasCoords
      ? PlaceDraft(nome: nome, endereco: endereco, latitude: latitude!, longitude: longitude!)
      : null;

  factory Place.fromSupabase(Map<String, dynamic> row) => Place(
        id: row['id'] as String,
        nome: row['nome'] as String,
        endereco: (row['endereco'] as String?) ?? '',
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
      );
}
