import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../auth/providers/auth_providers.dart';

/// Editar perfil: nome (aparece nos convites), fuso (UTC) e email só leitura.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nomeCtrl = TextEditingController();
  String _fuso = 'UTC-3';
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/profile');

  Future<void> _save() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      setState(() => _error = 'Digite seu nome.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileProvider.notifier).updateProfile(nome: nome, fuso: _fuso);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil salvo!')));
      _back();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não deu pra salvar. Confere a internet e tenta de novo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;

    // Preenche uma vez quando o perfil chega.
    if (!_loaded && profile != null) {
      _loaded = true;
      _nomeCtrl.text = profile.nome;
      _fuso = AppConstants.fusos.contains(profile.fuso) ? profile.fuso : 'UTC-3';
    }

    final nome = _nomeCtrl.text.trim();
    final first = nome.split(' ').first;

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SEU',
        right: 'PERFIL',
        leading: RetroButton.icon(
          onPressed: _back,
          shape: RetroButtonShape.circle,
          semanticLabel: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      panelPadding: EdgeInsets.zero,
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
              children: [
                Text('Editar perfil', style: EmberText.display(28)),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EmberColors.sol,
                      shape: BoxShape.circle,
                      border: p.contornoBorda,
                      boxShadow: [BoxShadow(color: p.contorno, offset: const Offset(0, 6))],
                    ),
                    child: Text(
                      nome.isEmpty ? '?' : nome[0].toUpperCase(),
                      style: EmberText.display(42, color: EmberColors.tinta),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const RetroFieldLabel('Como a galera te chama'),
                TextField(
                  controller: _nomeCtrl,
                  enabled: !_saving,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Seu nome', counterText: ''),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aparece nos convites: "${first.isEmpty ? 'Você' : first} te chamou pro rolê".',
                  style: EmberText.body(12, color: p.textoSecundario),
                ),
                const SizedBox(height: 18),
                const RetroFieldLabel('Fuso horário'),
                DropdownButtonFormField<String>(
                  initialValue: _fuso,
                  borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
                  dropdownColor: p.superficie,
                  menuMaxHeight: 360,
                  items: [
                    for (final f in AppConstants.fusos) DropdownMenuItem(value: f, child: Text(f)),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _fuso = v);
                        },
                ),
                const SizedBox(height: 18),
                const RetroFieldLabel('Email'),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: p.linhaSuave,
                    borderRadius: BorderRadius.circular(EmberRetro.raioInput),
                    border: Border.all(color: p.contorno, width: EmberRetro.borda),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 18, color: p.textoSecundario),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          profile.email ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: EmberText.body(15, color: p.textoSecundario),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  RetroErrorBox(_error!),
                ],
                const SizedBox(height: 26),
                RetroButton(
                  onPressed: _saving || nome.isEmpty ? null : _save,
                  expand: true,
                  height: 52,
                  child: _saving ? const RetroButtonSpinner() : const Text('Salvar'),
                ),
              ],
            ),
    );
  }
}
