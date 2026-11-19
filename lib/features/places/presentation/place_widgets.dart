import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/ember_retro_theme.dart';
import '../domain/place.dart';

/// Camada de mapa padrão (OpenStreetMap).
TileLayer chammaTiles() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.chamma.app',
      maxZoom: 19,
    );

/// Alfinete do CHAMMA no mapa.
class MapPin extends StatelessWidget {
  const MapPin({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: EmberColors.brasa,
            shape: BoxShape.circle,
            border: Border.all(color: p.contorno, width: 3),
            boxShadow: [BoxShadow(color: p.contorno, offset: const Offset(0, 3))],
          ),
          child: Icon(Icons.place_rounded, color: Colors.white, size: size * 0.55),
        ),
        Container(width: 3, height: size * 0.3, color: p.contorno),
      ],
    );
  }
}

/// Créditos exigidos pelo OpenStreetMap.
class OsmCredit extends StatelessWidget {
  const OsmCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 6,
      bottom: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        color: Colors.white.withAlpha(200),
        child: const Text('© OpenStreetMap', style: TextStyle(fontSize: 9, color: Colors.black87)),
      ),
    );
  }
}

/// Cartão do local: mapinha + nome + endereço + "Abrir no mapa".
/// Tocar em qualquer parte abre o app de mapas.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place, this.onChange, this.compact = false});

  final Place place;

  /// Organizador: trocar o local.
  final VoidCallback? onChange;

  /// Sem o mapinha (só nome e endereço).
  final bool compact;

  Future<void> _open() => launchUrl(place.mapsUri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Semantics(
      button: true,
      label: 'Local: ${place.nome}, ${place.endereco}. Abrir no mapa',
      child: GestureDetector(
        onTap: _open,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.superficie,
            borderRadius: BorderRadius.circular(EmberRetro.raioCard),
            border: p.contornoBorda,
            boxShadow: [p.sombraDeCard],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact && place.hasCoords)
                SizedBox(
                  height: 130,
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(place.latitude!, place.longitude!),
                            initialZoom: 15.5,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            chammaTiles(),
                            MarkerLayer(markers: [
                              Marker(
                                point: LatLng(place.latitude!, place.longitude!),
                                width: 40,
                                height: 54,
                                alignment: Alignment.topCenter,
                                child: const MapPin(size: 34),
                              ),
                            ]),
                          ],
                        ),
                        const OsmCredit(),
                      ],
                    ),
                  ),
                ),
              if (!compact && place.hasCoords) Container(height: 3, color: p.contorno),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: EmberColors.brasa,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.contorno, width: 2.5),
                      ),
                      child: const Icon(Icons.place_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: EmberText.body(15, weight: FontWeight.w800)),
                          if (place.endereco.isNotEmpty)
                            Text(place.endereco,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: EmberText.body(12, color: p.textoSecundario)),
                        ],
                      ),
                    ),
                    if (onChange != null)
                      TextButton(
                        onPressed: onChange,
                        style: TextButton.styleFrom(foregroundColor: p.texto, minimumSize: const Size(44, 44)),
                        child: Text('TROCAR', style: EmberText.mono(10.5).copyWith(decoration: TextDecoration.underline)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('MAPA', style: EmberText.mono(10.5, color: p.texto)),
                            Icon(Icons.north_east_rounded, size: 16, color: p.texto),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão tracejado "Adicionar local" (organizador, quando o rolê não tem local).
class AddPlaceButton extends StatelessWidget {
  const AddPlaceButton({super.key, required this.onTap, this.label = 'Adicionar local no mapa'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EmberRetro.raioCard),
            border: Border.all(color: p.textoSecundario.withAlpha(150), width: 2.5),
          ),
          child: Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: p.texto),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: EmberText.body(14.5, weight: FontWeight.w700))),
              Icon(Icons.chevron_right_rounded, color: p.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}
