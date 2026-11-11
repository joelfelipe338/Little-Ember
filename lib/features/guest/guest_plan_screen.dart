import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../shared/widgets/ember_button.dart';
import '../../shared/widgets/ember_logo.dart';
import '../../shared/widgets/retro_top_bar.dart';
import '../../theme/ember_retro_theme.dart';
import '../plans/domain/plan.dart';
import '../plans/domain/plan_member.dart';
import '../plans/domain/tally.dart';
import '../plans/domain/time_option.dart';
import '../plans/domain/time_vote.dart';
import '../plans/presentation/plan_widgets.dart';
import '../plans/providers/plan_providers.dart';

/// Página do convidado, aberta pelo link `/#/r/<slug>`.
///
/// Funciona no navegador sem conta: ao entrar, o convidado ganha uma sessão
/// anônima do Supabase, que fica salva no navegador, então ele pode voltar
/// pelo mesmo link e trocar o voto até o prazo.
class GuestPlanScreen extends ConsumerStatefulWidget {
  const GuestPlanScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<GuestPlanScreen> createState() => _GuestPlanScreenState();
}

class _GuestPlanScreenState extends ConsumerState<GuestPlanScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(planBySlugProvider(widget.slug));
    await ref.read(planBySlugProvider(widget.slug).future);
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planBySlugProvider(widget.slug));

    return RetroScaffold(
      top: const RetroTopBar(left: AppConstants.appName),
      ticker: 'VOCÊ FOI CHAMADO PRO ROLÊ • VOTE SEM INSTALAR NADA • ',
      panelPadding: EdgeInsets.zero,
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PlanMessage(
          text: 'Não deu pra abrir o rolê. Confere a internet e tenta de novo.',
          action: EmberButton(label: 'Tentar de novo', onPressed: _reload),
        ),
        data: (plan) {
          if (plan == null) {
            return const PlanMessage(
              text: 'Esse link não leva a nenhum rolê. Pede o link de novo pra quem te chamou.',
            );
          }
          return _GuestBody(plan: plan, onRefresh: _reload);
        },
      ),
    );
  }
}

// ===========================================================================
// Conteúdo
// ===========================================================================

class _GuestBody extends ConsumerStatefulWidget {
  const _GuestBody({required this.plan, required this.onRefresh});

  final Plan plan;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_GuestBody> createState() => _GuestBodyState();
}

class _GuestBodyState extends ConsumerState<_GuestBody> {
  final _nameController = TextEditingController();
  bool _joining = false;
  String? _joinError;

  /// Votos otimistas: aparecem na hora, antes do Realtime confirmar.
  final Map<String, Disp> _pending = {};

  Plan get plan => widget.plan;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _join() async {
    final nome = _nameController.text.trim();
    if (nome.isEmpty || _joining) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _joining = true;
      _joinError = null;
    });
    try {
      await ref.read(planRepositoryProvider).joinPlan(planId: plan.id, nome: nome);
      ref.invalidate(myMemberProvider(plan.id));
      await ref.read(myMemberProvider(plan.id).future);
    } catch (e) {
      if (mounted) {
        setState(() => _joinError = 'Não deu pra entrar no rolê. Tenta de novo em instantes.');
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _vote(TimeOption option, PlanMember me, Disp disp) async {
    setState(() => _pending[option.id!] = disp);
    try {
      await ref.read(planRepositoryProvider).vote(timeOptionId: option.id!, memberId: me.id, disp: disp);
    } catch (_) {
      if (mounted) {
        setState(() => _pending.remove(option.id));
        _snack('Não deu pra salvar o voto. Tenta de novo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final options = ref.watch(planOptionsProvider(plan.id)).valueOrNull ?? const <TimeOption>[];
    final votes = ref.watch(planVotesProvider(plan.id)).valueOrNull ?? const <TimeVote>[];
    final members = ref.watch(planMembersProvider(plan.id)).valueOrNull ?? const <PlanMember>[];
    final meAsync = ref.watch(myMemberProvider(plan.id));
    final me = meAsync.valueOrNull;

    final ranking = rankOptions(options, votes);
    final leader = ranking.isNotEmpty && ranking.first.total > 0 ? ranking.first : null;
    final tallyById = {for (final t in ranking) t.option.id!: t};
    final myVotes = <String, Disp>{
      for (final v in votes)
        if (me != null && v.memberId == me.id) v.timeOptionId: v.disp,
      ..._pending,
    };
    final votedMemberIds = votes.map((v) => v.memberId).toSet();
    final canVote = plan.isVotingOpen && me != null;
    final votedAll = options.isNotEmpty && options.every((o) => myVotes.containsKey(o.id));

    TimeOption? finalOption;
    for (final o in options) {
      if (o.id == plan.horarioFinalId) finalOption = o;
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InviteHeader(plan: plan, organizer: _organizerName(members)),
                  const SizedBox(height: 18),

                  if (plan.status == PlanStatus.fechado && finalOption != null) ...[
                    PlanFinalCard(when: _fmtOption(finalOption)),
                    const SizedBox(height: 18),
                  ],

                  // --------------------------------------------- entrar
                  if (plan.isVotingOpen && me == null)
                    meAsync.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _JoinCard(
                            controller: _nameController,
                            loading: _joining,
                            error: _joinError,
                            onSubmit: _join,
                          ),

                  if (!plan.isVotingOpen && plan.status == PlanStatus.votando)
                    const _InfoBox(
                      icon: Icons.timer_off_rounded,
                      text: 'O prazo de votação acabou. Agora é com quem organizou: logo sai o horário.',
                    ),
                  if (plan.status == PlanStatus.cancelado)
                    const _InfoBox(
                      icon: Icons.block_rounded,
                      text: 'Esse rolê foi cancelado por quem organizou.',
                    ),

                  if (canVote) ...[
                    _HelloStrip(nome: me!.nome, done: votedAll),
                  ],
                  const SizedBox(height: 22),

                  // --------------------------------------------- horários
                  PlanSectionTitle(
                    title: canVote ? 'Quando você pode?' : 'Horários',
                    trailing: canVote
                        ? '${myVotes.length}/${options.length} VOTADOS'
                        : (leader != null ? 'PLACAR' : null),
                  ),
                  const SizedBox(height: 10),
                  if (options.isEmpty)
                    Text('Nenhum horário cadastrado ainda.', style: EmberText.body(14, color: p.textoSecundario))
                  else
                    for (final o in options) ...[
                      PlanOptionCard(
                        label: _fmtOption(o),
                        tally: tallyById[o.id] ?? OptionTally(o),
                        isLeader: leader != null && leader.option.id == o.id && plan.status == PlanStatus.votando,
                        isFinal: plan.horarioFinalId == o.id,
                        myVote: myVotes[o.id],
                        onVote: canVote ? (d) => _vote(o, me!, d) : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                  if (canVote && votedAll) ...[
                    const SizedBox(height: 4),
                    const _DoneCard(),
                    const SizedBox(height: 12),
                  ],

                  // --------------------------------------------- galera
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    PlanSectionTitle(
                      title: 'Galera',
                      trailing: '${votedMemberIds.length} DE ${members.length} VOTARAM',
                    ),
                    const SizedBox(height: 10),
                    RetroCard(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in members)
                            _MemberChip(
                              member: m,
                              isMe: me != null && m.id == me.id,
                              voted: votedMemberIds.contains(m.id),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _organizerName(List<PlanMember> members) {
    for (final m in members) {
      if (m.isOrganizador) return m.nome;
    }
    return null;
  }

  String _fmtOption(TimeOption o) =>
      DateFormat("EEE, d 'de' MMM · HH:mm", 'pt_BR').format(o.inicioUtc.toLocal());
}

// ===========================================================================
// Pedaços da tela
// ===========================================================================

class _InviteHeader extends StatelessWidget {
  const _InviteHeader({required this.plan, required this.organizer});

  final Plan plan;
  final String? organizer;

  @override
  Widget build(BuildContext context) {
    final tag = planStatusTag(plan);
    final remaining = plan.status == PlanStatus.votando ? formatRemaining(plan.prazoVotacao) : null;
    final prazo = DateFormat("EEE, d 'de' MMM 'às' HH:mm", 'pt_BR').format(plan.prazoVotacao.toLocal());
    const ink = EmberColors.tinta;

    return RetroCard(
      color: EmberColors.sol,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            organizer == null ? 'VOCÊ FOI CHAMADO PRO ROLÊ' : '${organizer!.toUpperCase()} TE CHAMOU PRO ROLÊ',
            style: EmberText.mono(11, color: ink),
          ),
          const SizedBox(height: 10),
          Text(plan.titulo, style: EmberText.display(30, color: ink)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RetroTag(tag.label, color: tag.color),
              if (remaining != null) RetroTag(remaining.toUpperCase(), color: EmberColors.creme),
            ],
          ),
          if (plan.status == PlanStatus.votando) ...[
            const SizedBox(height: 10),
            Text('Votação até $prazo', style: EmberText.body(14, color: ink, weight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.controller,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final hasName = controller.text.trim().isNotEmpty;

    return RetroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bora votar?', style: EmberText.display(22)),
          const SizedBox(height: 4),
          Text(
            'Diz seu nome pra galera saber quem é. Não precisa de conta nem de app.',
            style: EmberText.body(14, color: p.textoSecundario),
          ),
          const SizedBox(height: 14),
          const RetroFieldLabel('SEU NOME'),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: !loading,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.givenName],
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(hintText: 'Como a galera te chama', counterText: ''),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            RetroErrorBox(error!),
          ],
          const SizedBox(height: 14),
          EmberButton(
            label: 'Entrar e votar',
            icon: Icons.local_fire_department_rounded,
            expand: true,
            isLoading: loading,
            onPressed: hasName ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

class _HelloStrip extends StatelessWidget {
  const _HelloStrip({required this.nome, required this.done});

  final String nome;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Row(
      children: [
        const EmberLogo(width: 38, semanticLabel: null),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            done
                ? 'Valeu, $nome! Dá pra mudar o voto até o prazo.'
                : 'Oi, $nome! Marca em cada horário se você pode.',
            style: EmberText.body(15, weight: FontWeight.w600, color: p.texto),
          ),
        ),
      ],
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard();

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      color: EmberColors.menta,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: EmberColors.tinta, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pronto!', style: EmberText.display(20, color: EmberColors.tinta)),
                const SizedBox(height: 2),
                Text(
                  'Seu voto tá salvo. Volta por este link pra ver qual horário venceu.',
                  style: EmberText.body(13, color: EmberColors.tinta),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return RetroCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: p.textoSecundario),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: EmberText.body(14, color: p.textoSecundario))),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member, required this.isMe, required this.voted});

  final PlanMember member;
  final bool isMe;
  final bool voted;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final label = isMe ? '${member.nome} (você)' : member.nome;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: voted ? EmberColors.menta : p.superficie,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.contorno, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            member.isOrganizador
                ? Icons.local_fire_department_rounded
                : (voted ? Icons.check_rounded : Icons.schedule_rounded),
            size: 16,
            color: voted ? EmberColors.tinta : p.textoSecundario,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: EmberText.body(13, weight: FontWeight.w700, color: voted ? EmberColors.tinta : p.texto),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Column(
      children: [
        const EmberLogo(width: 44, semanticLabel: null),
        const SizedBox(height: 6),
        Text(AppConstants.appName, style: EmberText.display(16)),
        const SizedBox(height: 2),
        Text(
          AppConstants.slogan,
          textAlign: TextAlign.center,
          style: EmberText.body(12, color: p.textoSecundario),
        ),
      ],
    );
  }
}
