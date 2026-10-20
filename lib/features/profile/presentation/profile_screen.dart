import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/app_version_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nomeController;
  String _fusoSelecionado = 'UTC-3';

  static const _fusos = [
    'UTC-2',
    'UTC-3',
    'UTC-4',
    'UTC-5',
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      _nomeController.text = profile.nome;
      _fusoSelecionado = _fusos.contains(profile.fuso) ? profile.fuso : _fusos.first;
    }
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    if (_nomeController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile(
            nome: _nomeController.text.trim(),
            fuso: _fusoSelecionado,
          );
      if (mounted) setState(() => _isEditing = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar perfil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: EmberColors.brasaTexto),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  String _fusoLabel(String fuso) => fuso;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SEU',
        right: 'PERFIL',
        emblem: const Icon(Icons.person_rounded, size: 24, color: EmberColors.tinta),
        trailing: profileAsync.valueOrNull == null
            ? null
            : RetroButton.icon(
                onPressed: _isEditing ? () => setState(() => _isEditing = false) : _startEditing,
                semanticLabel: _isEditing ? 'Cancelar edição' : 'Editar perfil',
                color: _isEditing ? EmberColors.branco : EmberColors.creme,
                icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
              ),
      ),
      panelPadding: EdgeInsets.zero,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RetroErrorBox('Erro ao carregar perfil: $e'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text('Perfil não encontrado', style: EmberText.body(15)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlayerCard(profile: profile),
                const SizedBox(height: 20),
                if (_isEditing) _buildEditForm() else _buildInfoCard(profile),
                const SizedBox(height: 20),
                _buildThemeSection(),
                const SizedBox(height: 28),
                RetroButton(
                  onPressed: _handleLogout,
                  shape: RetroButtonShape.pill,
                  color: EmberColors.branco,
                  foregroundColor: EmberColors.brasaTexto,
                  expand: true,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout_rounded),
                      SizedBox(width: 8),
                      Text('Sair da conta'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _AppVersion(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(AppUser profile) {
    return RetroCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _infoRow(Icons.person_outline_rounded, 'Nome', profile.nome),
          const Divider(height: 2),
          _infoRow(Icons.alternate_email_rounded, 'Email', profile.email ?? '—'),
          const Divider(height: 2),
          _infoRow(Icons.schedule_rounded, 'Fuso horário', _fusoLabel(profile.fuso)),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return RetroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RetroFieldLabel('Nome'),
          TextFormField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          const RetroFieldLabel('Fuso horário'),
          DropdownButtonFormField<String>(
            initialValue: _fusoSelecionado,
            borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
            dropdownColor: EmberColors.branco,
            items: _fusos
                .map((f) => DropdownMenuItem(value: f, child: Text(_fusoLabel(f))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _fusoSelecionado = v);
            },
          ),
          const SizedBox(height: 22),
          EmberButton(
            label: 'Salvar',
            onPressed: _saveProfile,
            isLoading: _isSaving,
            expand: true,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    final themeMode = ref.watch(themeModeProvider);
    final tokens = RetroTokens.of(context);

    Widget themeBtn(ThemeMode mode, IconData icon, String label) {
      final isActive = themeMode == mode;
      return Expanded(
        child: RetroButton(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: isActive ? EmberColors.sol : tokens.cardBg,
          foregroundColor: isActive ? EmberColors.tinta : tokens.textPrimary,
          onPressed: () => ref.read(themeModeProvider.notifier).set(mode),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 5),
                Text(label),
              ],
            ),
          ),
        ),
      );
    }

    return RetroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APARÊNCIA', style: EmberText.mono(10, color: tokens.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              themeBtn(ThemeMode.system, Icons.brightness_auto_rounded, 'Sistema'),
              const SizedBox(width: 8),
              themeBtn(ThemeMode.light, Icons.light_mode_rounded, 'Claro'),
              const SizedBox(width: 8),
              themeBtn(ThemeMode.dark, Icons.dark_mode_rounded, 'Escuro'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: EmberColors.textoSecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: EmberText.mono(10, color: EmberColors.textoSecundario)),
                const SizedBox(height: 2),
                Text(value, style: EmberText.body(16, weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão do "jogador": avatar redondo com contorno + nome.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final initial = profile.nome.isNotEmpty ? profile.nome[0].toUpperCase() : '?';
    final fallback = Center(child: Text(initial, style: EmberText.display(36)));

    return RetroCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: EmberColors.sol,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: EmberColors.tinta, width: EmberRetro.borda)),
              boxShadow: [BoxShadow(color: EmberColors.tinta, offset: Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: profile.avatarUrl != null
                ? Image.network(
                    profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  )
                : fallback,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nome, style: EmberText.display(24), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (profile.email != null)
                  Text(
                    profile.email!,
                    style: EmberText.body(13, color: EmberColors.textoSecundario),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rodapé com a versão instalada do app.
class _AppVersion extends ConsumerWidget {
  const _AppVersion();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).valueOrNull;
    if (version == null) return const SizedBox.shrink();

    return Text(
      'LITTLE EMBER · V$version',
      textAlign: TextAlign.center,
      style: EmberText.mono(10, color: RetroTokens.of(context).textSecondary),
    );
  }
}
