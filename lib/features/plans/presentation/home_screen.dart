import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/ember_logo.dart';
import '../../../shared/widgets/retro_empty_state.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../domain/plan.dart';
import '../domain/tally.dart';
import '../providers/plan_providers.dart';
import 'plan_widgets.dart' show planStatusTag;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(myPlansProvider);

    return RetroScaffold(
      top: const RetroTopBar(left: 'SEUS', right: 'ROLÊS'),
      panelPadding: EdgeInsets.zero,
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RetroErrorBox('Não deu pra carregar seus rolês.'),
                const SizedBox(height: 16),
                EmberButton(label: 'Tentar de novo', onPressed: () => ref.invalidate(myPlansProvider)),
              ],
            ),
          ),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return RetroEmptyState(
              illustration: const EmberLogo(width: 104),
              title: 'Nenhuma brasa acesa ainda',
              message: '${AppConstants.slogan}\nCrie o primeiro rolê e chame a galera.',
              action: EmberButton(
                label: 'Novo rolê',
                icon: Icons.add_rounded,
                onPressed: () => context.push('/create-plan'),
              ),
            );
          }
          return _PlanList(plans: plans);
        },
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({required this.plans});

  final List<Plan> plans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = RetroPalette.of(context);
    // Rolês em votação primeiro; depois os encerrados.
    final sorted = [...plans]..sort((a, b) {
        final ao = a.status == PlanStatus.votando ? 0 : 1;
        final bo = b.status == PlanStatus.votando ? 0 : 1;
        if (ao != bo) return ao.compareTo(bo);
        return (b.createdAt ?? b.prazoVotacao).compareTo(a.createdAt ?? a.prazoVotacao);
      });

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.refresh(myPlansProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 100),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Seus rolês', style: EmberText.display(28))),
                  Text(
                    '${plans.length} ${plans.length == 1 ? 'ROLÊ' : 'ROLÊS'}',
                    style: EmberText.mono(11, color: p.textoSecundario),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final plan in sorted) ...[
                _PlanCard(plan: plan),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: RetroButton(
            onPressed: () => context.push('/create-plan'),
            shape: RetroButtonShape.pill,
            height: 50,
            semanticLabel: 'Novo rolê',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.add_rounded), SizedBox(width: 6), Text('Novo rolê')],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final tag = planStatusTag(plan);
    final remaining = plan.status == PlanStatus.votando ? formatRemaining(plan.prazoVotacao) : null;
    final prazo = DateFormat("EEE, d 'de' MMM 'às' HH:mm", 'pt_BR').format(plan.prazoVotacao.toLocal());

    return RetroCard(
      onTap: () => context.push('/plan/${plan.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RetroTag(tag.label, color: tag.color),
                    if (remaining != null)
                      Text(remaining.toUpperCase(), style: EmberText.mono(10, color: p.textoSecundario)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(plan.titulo, style: EmberText.display(21), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  plan.status == PlanStatus.votando ? 'Votação até $prazo' : 'Votação encerrada',
                  style: EmberText.body(13, color: p.textoSecundario),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textoSecundario),
        ],
      ),
    );
  }
}
