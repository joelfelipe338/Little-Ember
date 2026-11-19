import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../connections/domain/brasa.dart';
import '../../connections/presentation/widgets/connection_sheets.dart';
import '../../connections/presentation/widgets/connection_ui.dart';
import '../../connections/providers/connections_providers.dart';
import '../../plans/domain/plan.dart';
import '../../plans/domain/plan_overview.dart';
import '../../plans/presentation/create_plan/create_plan_widgets.dart' show RetroToggle;
import '../../plans/presentation/create_plan/plan_rules.dart';
import '../../plans/providers/plan_providers.dart';
import '../../subscription/presentation/plus_sheet.dart';
import '../../subscription/providers/subscription_providers.dart';
import '../providers/app_version_provider.dart';
import '../providers/preferences_provider.dart';

/// Perfil: quem você é no CHAMMA, seus números, código de convite,
/// aparência, preferências, conta e versão do app.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você vai precisar entrar de novo pra ver seus rolês.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: RetroPalette.of(ctx).erroTexto),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> _pickMode(BuildContext context, WidgetRef ref) async {
    final current = ref.read(defaultRuleModeProvider);
    final picked = await showRetroSheet<RuleMode>(
      context,
      (ctx) => RetroSheet(
        title: 'Jeito de decidir',
        subtitle: 'Já vem marcado quando você cria um rolê. Dá pra trocar em cada rolê.',
        children: [
          for (final m in RuleMode.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RetroButton(
                onPressed: () => Navigator.pop(ctx, m),
                expand: true,
                color: m == current ? EmberColors.sol : RetroPalette.of(ctx).botaoSecundario,
                child: Row(
                  children: [
                    Expanded(child: Text('${m.titulo} · ${m.descricao}')),
                    if (m != RuleMode.normal && !ref.read(subscriptionProvider).modosAvancados) const PlusBadge(),
                    if (m == current) const Icon(Icons.check_rounded, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    if (picked != RuleMode.normal && !ref.read(subscriptionProvider).modosAvancados) {
      if (context.mounted) {
        await showPlusSheet(context, titulo: 'Modo ${picked.titulo}', motivo: 'Os modos Rápido e Secreto fazem parte do CHAMMA+.');
      }
      return;
    }
    await ref.read(defaultRuleModeProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SEU',
        right: 'PERFIL',
        trailing: profileAsync.valueOrNull == null
            ? null
            : RetroButton.icon(
                onPressed: () => context.push('/profile/edit'),
                shape: RetroButtonShape.circle,
                semanticLabel: 'Editar perfil',
                icon: const Icon(Icons.edit_rounded),
              ),
      ),
      panelPadding: EdgeInsets.zero,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: RetroErrorBox('Não deu pra carregar o perfil.'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text('Perfil não encontrado', style: EmberText.body(15)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(myPlansProvider);
              refreshConnections(ref);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 26, 14, 24),
              children: [
                _PlayerCard(profile: profile),
                const SizedBox(height: 12),
                const _Stats(),
                const SizedBox(height: 12),
                _InviteCodeCard(profile: profile),
                const SizedBox(height: 18),

                const SectionLabel('Aparência'),
                const SizedBox(height: 8),
                const _ThemeSelector(),
                const SizedBox(height: 18),

                const SectionLabel('Preferências'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  _SettingRow(
                    icon: Icons.tune_rounded,
                    title: 'Jeito de decidir',
                    subtitle: 'Usado no Novo rolê',
                    value: ref.watch(defaultRuleModeProvider).titulo,
                    onTap: () => _pickMode(context, ref),
                  ),
                  _SettingRow(
                    icon: Icons.notifications_rounded,
                    title: 'Avisos',
                    subtitle: 'Votos, prazos e pedidos de vínculo · em breve',
                    trailing: RetroToggle(
                      value: ref.watch(notificationsEnabledProvider),
                      onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).set(v),
                      semanticLabel: 'Avisos',
                    ),
                    onTap: () => ref
                        .read(notificationsEnabledProvider.notifier)
                        .set(!ref.read(notificationsEnabledProvider)),
                  ),
                  _SettingRow(
                    icon: Icons.schedule_rounded,
                    title: 'Fuso horário',
                    value: profile.fuso,
                    onTap: () => context.push('/profile/edit'),
                  ),
                ]),
                const SizedBox(height: 18),

                const SectionLabel('Conta'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  _SettingRow(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Assinatura',
                    subtitle: ref.watch(subscriptionProvider).isPlus ? 'CHAMMA+ ativo' : 'Conheça o CHAMMA+',
                    value: ref.watch(subscriptionProvider).isPlus ? 'Plus' : 'Grátis',
                    onTap: () => context.push('/assinatura'),
                  ),
                  _SettingRow(
                    icon: Icons.edit_rounded,
                    title: 'Editar perfil',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _SettingRow(
                    icon: Icons.logout_rounded,
                    title: 'Sair da conta',
                    danger: true,
                    showChevron: false,
                    onTap: () => _logout(context, ref),
                  ),
                ]),
                const SizedBox(height: 18),

                const SectionLabel('Sobre'),
                const SizedBox(height: 8),
                const _AboutCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Pedaços da tela
// ===========================================================================

class _PlayerCard extends ConsumerWidget {
  const _PlayerCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = RetroPalette.of(context);
    final nome = profile.nome.trim();
    final initial = nome.isEmpty ? '?' : nome[0].toUpperCase();
    final fallback = Center(child: Text(initial, style: EmberText.display(32, color: EmberColors.tinta)));

    // Brasa: tempo desde o seu último rolê (não cancelado e que já aconteceu ou está marcado).
    final overviews = ref.watch(myPlanOverviewsProvider).valueOrNull ?? const <PlanOverview>[];
    final agora = DateTime.now();
    DateTime? ultimo;
    for (final o in overviews) {
      if (o.plan.status == PlanStatus.cancelado) continue;
      final d = o.finalTime ?? o.plan.createdAt;
      if (d == null || d.isAfter(agora)) continue;
      if (ultimo == null || d.isAfter(ultimo)) ultimo = d;
    }
    final level = ultimo == null ? null : brasaOf(LastPlan(titulo: '', data: ultimo));
    final (tagLabel, tagColor) = switch (level) {
      BrasaLevel.quente => ('Brasa quente', EmberColors.brasa),
      BrasaLevel.morna => ('Brasa morna', EmberColors.sol),
      BrasaLevel.fria => ('Brasa esfriando', EmberColors.neblina),
      null => ('Sem rolês ainda', EmberColors.neblina),
    };

    return RetroCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: EmberColors.sol,
              shape: BoxShape.circle,
              border: p.contornoBorda,
            ),
            clipBehavior: Clip.antiAlias,
            child: profile.avatarUrl != null
                ? Image.network(profile.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
                : fallback,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nome, style: EmberText.display(23), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (profile.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EmberText.body(12.5, color: p.textoSecundario),
                  ),
                ],
               
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviews = ref.watch(myPlanOverviewsProvider).valueOrNull;
    final contacts = ref.watch(myContactsProvider).valueOrNull;
    final fechados = overviews?.where((o) => o.plan.status == PlanStatus.fechado).length;
    final p = RetroPalette.of(context);

    Widget box(String? n, String label) => Expanded(
          child: RetroCard(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              children: [
                Text(n ?? '–', style: EmberText.display(26).copyWith(height: 1)),
                const SizedBox(height: 3),
                Text(label, style: EmberText.mono(9, color: p.textoSecundario)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        box(overviews?.length.toString(), 'ROLÊS'),
        const SizedBox(width: 8),
        box(fechados?.toString(), 'FECHADOS'),
        const SizedBox(width: 8),
        box(contacts?.length.toString(), 'CONEXÕES'),
      ],
    );
  }
}

/// Código pessoal de convite. Por enquanto só mostra, copia e compartilha.
class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final code = profile.codigoConvite;

    return RetroCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SEU CÓDIGO DE CONVITE', style: EmberText.mono(10, color: p.textoSecundario)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.tela,
                    borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
                    border: Border.all(color: p.contorno, width: 2.5),
                  ),
                  child: SelectableText(
                    code ?? '······',
                    style: EmberText.mono(22).copyWith(letterSpacing: 6, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              RetroButton.icon(
                onPressed: code == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Código copiado!')));
                        }
                      },
                semanticLabel: 'Copiar código',
                icon: const Icon(Icons.copy_rounded),
              ),
              const SizedBox(width: 8),
              RetroButton.icon(
                onPressed: code == null
                    ? null
                    : () => Share.share('Me acha no CHAMMA pra gente marcar uns rolês! Meu código: $code'),
                color: EmberColors.sol,
                semanticLabel: 'Compartilhar código',
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            code == null
                ? 'Seu código aparece depois que o banco for atualizado.'
                : 'Em breve: adicionar amigos pelo código.',
            style: EmberText.body(12, color: p.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final p = RetroPalette.of(context);

    Widget btn(ThemeMode mode, IconData icon, String label) {
      final active = themeMode == mode;
      return Expanded(
        child: RetroButton(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: active ? EmberColors.sol : p.superficie,
          foregroundColor: active ? EmberColors.tinta : p.texto,
          onPressed: () => ref.read(themeModeProvider.notifier).set(mode),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icon, size: 16), const SizedBox(width: 5), Text(label)],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(ThemeMode.system, Icons.brightness_auto_rounded, 'Sistema'),
        const SizedBox(width: 8),
        btn(ThemeMode.light, Icons.light_mode_rounded, 'Claro'),
        const SizedBox(width: 8),
        btn(ThemeMode.dark, Icons.dark_mode_rounded, 'Escuro'),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return RetroCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 2, color: p.linhaSuave),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  /// Controle à direita (ex.: interruptor). Substitui valor e seta.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final color = danger ? p.erroTexto : p.texto;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: EmberText.body(14.5, color: color, weight: FontWeight.w700)),
                      if (subtitle != null)
                        Text(subtitle!, style: EmberText.body(12, color: p.textoSecundario)),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else ...[
                  if (value != null)
                    Text(value!.toUpperCase(), style: EmberText.mono(10.5, color: p.textoSecundario)),
                  if (showChevron && onTap != null) Icon(Icons.chevron_right_rounded, color: p.textoSecundario),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Versão instalada do app.
class _AboutCard extends ConsumerWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).valueOrNull;
    return _SettingsCard(children: [
      _SettingRow(
        icon: Icons.info_outline_rounded,
        title: 'Versão do app',
        value: version ?? '...',
        showChevron: false,
      ),
    ]);
  }
}
