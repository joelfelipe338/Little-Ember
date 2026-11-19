import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../connections/presentation/widgets/connection_ui.dart';
import '../../connections/providers/connections_providers.dart';
import '../../plans/domain/plan_overview.dart';
import '../../plans/providers/plan_providers.dart';
import '../domain/subscription.dart';
import '../providers/subscription_providers.dart';

/// Assinatura: plano atual, quanto você está usando e o que o CHAMMA+ libera.
/// A compra ainda não existe: o plano muda pelo banco (`profiles.plano`).
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = RetroPalette.of(context);
    final sub = ref.watch(subscriptionProvider);
    final table = ref.watch(planLimitsProvider).valueOrNull;
    final gratis = table?['gratis'] ?? Subscription.gratisPadrao;
    final plus = table?['plus'] ?? Subscription.plusPadrao;

    final overviews = ref.watch(myPlanOverviewsProvider).valueOrNull ?? const <PlanOverview>[];
    final ativos = overviews.where((o) => o.isOrganizer && o.plan.isVotingOpen).length;
    final grupos = ref.watch(contactGroupsProvider).valueOrNull?.length ?? 0;

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SUA',
        right: 'ASSINATURA',
        leading: RetroButton.icon(
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
          shape: RetroButtonShape.circle,
          semanticLabel: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      panelPadding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(planLimitsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 26, 14, 28),
          children: [
            // ------------------------------------------------ plano atual
            RetroCard(
              color: sub.isPlus ? EmberColors.lavanda : null,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SEU PLANO',
                      style: EmberText.mono(10, color: sub.isPlus ? EmberColors.tinta : p.textoSecundario)),
                  const SizedBox(height: 4),
                  Text(sub.isPlus ? 'CHAMMA+' : 'Grátis',
                      style: EmberText.display(30, color: sub.isPlus ? EmberColors.tinta : null)),
                  const SizedBox(height: 4),
                  Text(
                    sub.isPlus
                        ? (sub.expiraEm == null
                            ? 'Tudo liberado. Valeu por apoiar o CHAMMA!'
                            : 'Tudo liberado até ${DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(sub.expiraEm!.toLocal())}.')
                        : 'Tudo o que você precisa pra marcar os rolês da galera.',
                    style: EmberText.body(13.5, color: sub.isPlus ? EmberColors.tinta : p.textoSecundario),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ------------------------------------------------ uso
            const SectionLabel('Seu uso agora'),
            const SizedBox(height: 8),
            RetroCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _UsageRow(
                    label: 'Rolês em votação',
                    used: ativos,
                    limit: sub.limit(PlanFeature.rolesAtivos),
                  ),
                  const SizedBox(height: 12),
                  _UsageRow(label: 'Grupos de conexões', used: grupos, limit: sub.limit(PlanFeature.grupos)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ------------------------------------------------ comparação
            const SectionLabel('Grátis x CHAMMA+'),
            const SizedBox(height: 8),
            RetroCard(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: [
                  const _CompareHeader(),
                  _CompareRow('Rolês em votação ao mesmo tempo',
                      Subscription.label(gratis[PlanFeature.rolesAtivos] ?? 3),
                      Subscription.label(plus[PlanFeature.rolesAtivos] ?? 1000)),
                  _CompareRow('Horários por rolê', Subscription.label(gratis[PlanFeature.horariosPorRole] ?? 5),
                      Subscription.label(plus[PlanFeature.horariosPorRole] ?? 15)),
                  _CompareRow('Pessoas por rolê', Subscription.label(gratis[PlanFeature.pessoasPorRole] ?? 15),
                      Subscription.label(plus[PlanFeature.pessoasPorRole] ?? 200)),
                  _CompareRow('Grupos de conexões', Subscription.label(gratis[PlanFeature.grupos] ?? 3),
                      Subscription.label(plus[PlanFeature.grupos] ?? 1000)),
                  const _CompareRow('Modo Normal', true, true),
                  const _CompareRow('Modos Rápido e Secreto', false, true),
                  const _CompareRow('Local no mapa', true, true),
                  const _CompareRow('Link pra galera votar sem app', true, true),
                  const _CompareRow('Conexões e vínculo no app', true, true),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ------------------------------------------------ assinar
            if (!sub.isPlus) ...[
              RetroCard(
                color: EmberColors.lavanda.withAlpha(60),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('CHAMMA+', style: EmberText.display(24))),
                        const RetroTag('Em breve', color: EmberColors.sol),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('R\$ 9,90 por mês ou R\$ 79,90 por ano', style: EmberText.body(14, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    RetroButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A assinatura chega em breve!')),
                      ),
                      expand: true,
                      color: EmberColors.lavanda,
                      child: const Text('Assinar o CHAMMA+'),
                    ),
                  ],
                ),
              ),
            ] else
              Center(
                child: Text('Gerenciar pagamento: em breve.',
                    style: EmberText.body(13, color: p.textoSecundario)),
              ),

            // Dica só em modo de desenvolvimento.
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Text(
                'DEV: pra testar, mude profiles.plano pra "plus" no Supabase e puxe a tela pra atualizar.',
                textAlign: TextAlign.center,
                style: EmberText.mono(9.5, color: p.textoSecundario),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.used, required this.limit});

  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final unlimited = limit >= 1000;
    final frac = unlimited || limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final full = !unlimited && used >= limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: EmberText.body(14, weight: FontWeight.w700))),
            Text(unlimited ? '$used · SEM LIMITE' : '$used DE $limit',
                style: EmberText.mono(10.5, color: full ? p.erroTexto : p.textoSecundario)),
          ],
        ),
        if (!unlimited) ...[
          const SizedBox(height: 6),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: p.tela,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: p.contorno, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: frac,
              child: Container(color: full ? EmberColors.brasa : EmberColors.menta),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompareHeader extends StatelessWidget {
  const _CompareHeader();

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          SizedBox(width: 70, child: Text('GRÁTIS', textAlign: TextAlign.center, style: EmberText.mono(10, color: p.textoSecundario))),
          SizedBox(width: 70, child: Text('PLUS', textAlign: TextAlign.center, style: EmberText.mono(10, color: p.texto))),
        ],
      ),
    );
  }
}

/// Linha da comparação: valor pode ser texto ou bool (✓ / –).
class _CompareRow extends StatelessWidget {
  const _CompareRow(this.label, this.gratis, this.plus);

  final String label;
  final Object gratis;
  final Object plus;

  Widget _cell(BuildContext context, Object v, {required bool destaque}) {
    final p = RetroPalette.of(context);
    if (v is bool) {
      return Icon(v ? Icons.check_rounded : Icons.remove_rounded,
          size: 20, color: v ? (destaque ? EmberColors.menta : p.texto) : p.textoSecundario);
    }
    return Text('$v',
        textAlign: TextAlign.center,
        style: EmberText.body(13, weight: destaque ? FontWeight.w800 : FontWeight.w600));
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.linhaSuave, width: 2))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: EmberText.body(13.5))),
          SizedBox(width: 70, child: Center(child: _cell(context, gratis, destaque: false))),
          SizedBox(width: 70, child: Center(child: _cell(context, plus, destaque: true))),
        ],
      ),
    );
  }
}
