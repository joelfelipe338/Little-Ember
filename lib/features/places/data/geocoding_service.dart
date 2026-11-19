import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../domain/place.dart';

/// Busca de endereços (OpenStreetMap / Nominatim, grátis e sem chave).
/// Regra de uso: no máximo 1 busca por segundo — a tela espera o usuário parar de digitar.
class GeocodingService {
  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'CHAMMA/0.1 (https://chamma.site)', 'Accept-Language': 'pt-BR'};

  Map<String, String>? get _h => kIsWeb ? null : _headers;

  Future<List<PlaceDraft>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final uri = Uri.https(_host, '/search', {
      'format': 'jsonv2',
      'q': q,
      'countrycodes': 'br',
      'limit': '6',
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });
    final res = await http.get(uri, headers: _h);
    if (res.statusCode != 200) return const [];
    final list = jsonDecode(res.body) as List;
    return [for (final r in list) _fromJson(r as Map<String, dynamic>)];
  }

  /// Endereço de um ponto do mapa (quando a pessoa toca no mapa).
  Future<PlaceDraft?> reverse(double lat, double lng) async {
    final uri = Uri.https(_host, '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '18',
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });
    final res = await http.get(uri, headers: _h);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['error'] != null) return null;
    return _fromJson(json).copyWith(latitude: lat, longitude: lng);
  }

  PlaceDraft _fromJson(Map<String, dynamic> r) {
    final a = (r['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final nome = (r['name'] as String?)?.trim();
    final rua = [a['road'], a['house_number']].whereType<String>().join(', ');
    final bairro = (a['suburb'] ?? a['neighbourhood']) as String?;
    final cidade = (a['city'] ?? a['town'] ?? a['village']) as String?;
    final curto = [rua, bairro, cidade].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final display = (r['display_name'] as String?) ?? '';
    return PlaceDraft(
      nome: (nome == null || nome.isEmpty) ? (rua.isNotEmpty ? rua : display.split(',').first) : nome,
      endereco: curto.isNotEmpty ? curto : display,
      latitude: double.parse('${r['lat']}'),
      longitude: double.parse('${r['lon']}'),
    );
  }
}
