import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../domain/place.dart';
import '../providers/place_providers.dart';
import 'place_widgets.dart';

/// Escolher o local do rolê no mapa: busca por endereço ou toque no mapa.
/// Devolve um [PlaceDraft] com `context.pop(draft)`.
class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key, this.initial});

  final PlaceDraft? initial;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  static const _saoPaulo = LatLng(-23.5505, -46.6333);

  final _map = MapController();
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  List<PlaceDraft> _results = const [];
  bool _searching = false;
  bool _resolving = false;
  LatLng? _point;
  String _endereco = '';

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _point = LatLng(i.latitude, i.longitude);
      _nameCtrl.text = i.nome;
      _endereco = i.endereco;
    }
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    // Espera a pessoa parar de digitar (regra do serviço de busca: 1 por segundo).
    _debounce = Timer(const Duration(milliseconds: 900), () => _search(text));
  }

  Future<void> _search(String text) async {
    setState(() => _searching = true);
    try {
      final r = await ref.read(geocodingProvider).search(text);
      if (mounted) setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pickResult(PlaceDraft d) {
    FocusScope.of(context).unfocus();
    setState(() {
      _point = LatLng(d.latitude, d.longitude);
      _endereco = d.endereco;
      if (_nameCtrl.text.trim().isEmpty) _nameCtrl.text = d.nome;
      _results = const [];
      _searchCtrl.clear();
    });
    _map.move(_point!, 17);
  }

  Future<void> _onTapMap(LatLng latLng) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _point = latLng;
      _results = const [];
      _resolving = true;
    });
    try {
      final d = await ref.read(geocodingProvider).reverse(latLng.latitude, latLng.longitude);
      if (!mounted || _point != latLng) return;
      setState(() {
        _endereco = d?.endereco ?? '';
        if (_nameCtrl.text.trim().isEmpty && d != null) _nameCtrl.text = d.nome;
      });
    } catch (_) {
      // Sem endereço: dá pra seguir só com o nome.
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _confirm() {
    final pt = _point;
    final nome = _nameCtrl.text.trim();
    if (pt == null || nome.isEmpty) return;
    context.pop(PlaceDraft(nome: nome, endereco: _endereco, latitude: pt.latitude, longitude: pt.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final pt = _point;
    final canConfirm = pt != null && _nameCtrl.text.trim().isNotEmpty;

    return RetroScaffold(
      top: RetroTopBar(
        left: 'ONDE',
        right: 'É?',
        leading: RetroButton.icon(
          onPressed: _close,
          shape: RetroButtonShape.circle,
          semanticLabel: 'Fechar',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      panelPadding: EdgeInsets.zero,
      body: Column(
        children: [
          // ------------------------------------------------ busca
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Buscar endereço ou lugar',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                      )
                    : null,
              ),
            ),
          ),

          // ------------------------------------------------ mapa
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(EmberRetro.raioCard),
                      border: p.contornoBorda,
                    ),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _map,
                          options: MapOptions(
                            initialCenter: pt ?? _saoPaulo,
                            initialZoom: pt == null ? 11 : 16,
                            onTap: (_, latLng) => _onTapMap(latLng),
                          ),
                          children: [
                            chammaTiles(),
                            if (pt != null)
                              MarkerLayer(markers: [
                                Marker(
                                  point: pt,
                                  width: 50,
                                  height: 64,
                                  alignment: Alignment.topCenter,
                                  child: const MapPin(),
                                ),
                              ]),
                          ],
                        ),
                        const OsmCredit(),
                        if (pt == null)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: p.superficie,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: p.contorno, width: 2),
                              ),
                              child: Text(
                                'Busque o endereço ou toque no mapa pra marcar o local.',
                                style: EmberText.body(13, weight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Resultados da busca por cima do mapa.
                if (_results.isNotEmpty)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: p.superficie,
                        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
                        border: p.contornoBorda,
                        boxShadow: [p.sombraDeCard],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: p.linhaSuave),
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.place_outlined, color: p.texto),
                            title: Text(r.nome, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: EmberText.body(14, weight: FontWeight.w700)),
                            subtitle: Text(r.endereco, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: EmberText.body(12, color: p.textoSecundario)),
                            onTap: () => _pickResult(r),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ------------------------------------------------ confirmar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RetroFieldLabel('Nome do local'),
                TextField(
                  controller: _nameCtrl,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Ex.: Casa do Rafa, Bar do Zé', counterText: ''),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.map_outlined, size: 16, color: p.textoSecundario),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _resolving
                            ? 'Buscando endereço...'
                            : (pt == null
                                ? 'Nenhum ponto marcado ainda'
                                : (_endereco.isEmpty ? 'Ponto marcado no mapa' : _endereco)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: EmberText.body(12.5, color: p.textoSecundario),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RetroButton(
                  onPressed: canConfirm ? _confirm : null,
                  expand: true,
                  height: 52,
                  child: const Text('Usar este local'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
