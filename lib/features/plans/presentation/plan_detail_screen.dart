import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../domain/plan.dart';
import '../domain/plan_member.dart';
import '../domain/tally.dart';
import '../domain/time_option.dart';
import '../domain/time_vote.dart';
import '../providers/plan_providers.dart';
import 'plan_widgets.dart';

/// Painel do rolê: status, link para a galera, placar ao vivo, voto do
/// organizador, quem já votou e as ações de fechar/cancelar.
class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Atualiza a contagem regressiva do prazo a cada minuto.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(planProvider(widget.planId));
    ref.invalidate(planOptionsProvider(widget.planId));
    ref.invalidate(myMemberProvider(widget.planId));
    await ref.read(planProvider(widget.planId).future);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _vote(TimeOption option, PlanMember me, Disp disp) async {
    try {
      await ref.read(planRepositoryProvider).vote(timeOptionId: option.id!, memberId: me.id, disp: disp);
    } catch (e) {
      if (mounted) _snack('Não deu pra salvar o voto. Tenta de novo.');
    }
  }

  Future<void> _closePlan(Plan plan, OptionTally leader) async {
    final when = _fmtOption(leader.option);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar o rolê?'),
        content: Text('O horário escolhido vai ser $when. A votação acaba agora.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Agora não')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Fechar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(planRepositoryProvider).closePlan(planId: plan.id, timeOptionId: leader.option.id!);
      ref.invalidate(myPlansProvider);
      await _refresh();
      if (mounted) _snack('Fechou! Avisa a galera.');
    } catch (_) {
      if (mounted) _snack('Não deu pra fechar o rolê. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelPlan(Plan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar o rolê?'),
        content: const Text('A votação para e o rolê fica marcado como cancelado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: RetroPalette.of(ctx).erroTexto),
            child: const Text('Cancelar rolê'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(planRepositoryProvider).cancelPlan(plan.id);
      ref.invalidate(myPlansProvider);
      await _refresh();
    } catch (_) {
      if (mounted) _snack('Não deu pra cancelar. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink(Plan plan) async {
    await Clipboard.setData(ClipboardData(text: AppConstants.guestLink(plan.slug)));
    if (mounted) _snack('Link copiado!');
  }

  Future<void> _shareLink(Plan plan) async {
    final prazo = DateFormat("EEE, d 'de' MMM 'às' HH:mm", 'pt_BR').format(plan.prazoVotacao.toLocal());
    await Share.share(
      'Bora? Vota no rolê "${plan.titulo}" até $prazo:\n${AppConstants.guestLink(plan.slug)}',
      subject: plan.titulo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planProvider(widget.planId));

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SEU',
        right: 'ROLÊ',
        emblem: const Icon(Icons.local_fire_department_rounded, size: 24),
        leading: RetroButton.icon(
          onPressed: _back,
          semanticLabel: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      panelPadding: EdgeInsets.zero,
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PlanMessage(
          text: 'Não deu pra carregar o rolê.',
          action: EmberButton(label: 'Tentar de novo', onPressed: _refresh),
        ),
        data: (plan) {
          if (plan == null) {
            return PlanMessage(
              text: 'Esse rolê não existe mais.',
              action: EmberButton(label: 'Voltar', onPressed: _back),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _buildContent(plan),
          );
        },
      ),
    );
  }

  Widget _buildContent(Plan plan) {
    final p = RetroPalette.of(context);
    final options = ref.watch(planOptionsProvider(plan.id)).valueOrNull ?? const <TimeOption>[];
    final votes = ref.watch(planVotesProvider(plan.id)).valueOrNull ?? const <TimeVote>[];
    final members = ref.watch(planMembersProvider(plan.id)).valueOrNull ?? const <PlanMember>[];
    final me = ref.watch(myMemberProvider(plan.id)).valueOrNull;

    final ranking = rankOptions(options, votes);
    final leader = ranking.isNotEmpty && ranking.first.total > 0 ? ranking.first : null;
    final tallyById = {for (final t in ranking) t.option.id!: t};
    final myVotes = {
      for (final v in votes)
        if (me != null && v.memberId == me.id) v.timeOptionId: v.disp,
    };
    final votedMemberIds = votes.map((v) => v.memberId).toSet();
    final isOrganizer = me?.isOrganizador ?? false;
    final canVote = plan.isVotingOpen && me != null;
    TimeOption? finalOption;
    for (final o in options) {
      if (o.id == plan.horarioFinalId) finalOption = o;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 28),
      children: [
        _HeaderCard(plan: plan, votedCount: votedMemberIds.length, memberCount: members.length),
        const SizedBox(height: 18),

        if (plan.status == PlanStatus.fechado && finalOption != null) ...[
          PlanFinalCard(when: _fmtOption(finalOption)),
          const SizedBox(height: 18),
        ],

        if (plan.status == PlanStatus.votando) ...[
          _ShareCard(
            link: AppConstants.guestLink(plan.slug),
            onCopy: () => _copyLink(plan),
            onShare: () => _shareLink(plan),
          ),
          const SizedBox(height: 22),
        ],

        // ---------------------------------------------------- placar
        PlanSectionTitle(
          title: 'Quando?',
          trailing: canVote ? 'SEU VOTO' : (plan.isPastDeadline ? 'PRAZO ENCERRADO' : null),
        ),
        const SizedBox(height: 10),
        if (options.isEmpty)
          Text('Nenhum horário cadastrado.', style: EmberText.body(14, color: p.textoSecundario))
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

        // ---------------------------------------------------- galera
        const SizedBox(height: 10),
        PlanSectionTitle(title: 'Galera', trailing: '${members.length} ${members.length == 1 ? 'PESSOA' : 'PESSOAS'}'),
        const SizedBox(height: 10),
        RetroCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < members.length; i++) ...[
                if (i > 0) const Divider(height: 2),
                _MemberRow(member: members[i], voted: votedMemberIds.contains(members[i].id)),
              ],
              if (members.length <= 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Text(
                    'Mande o link no grupo: quem abrir entra aqui na hora.',
                    style: EmberText.body(13, color: p.textoSecundario),
                  ),
                ),
            ],
          ),
        ),

        // ---------------------------------------------------- ações do organizador
        if (isOrganizer && plan.status == PlanStatus.votando) ...[
          const SizedBox(height: 26),
          EmberButton(
            label: 'Fechar rolê agora',
            icon: Icons.check_rounded,
            expand: true,
            isLoading: _busy,
            onPressed: leader == null ? null : () => _closePlan(plan, leader),
          ),
          if (leader == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Dá pra fechar depois do primeiro voto.',
                textAlign: TextAlign.center,
                style: EmberText.body(13, color: p.textoSecundario),
              ),
            ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => _cancelPlan(plan),
              style: TextButton.styleFrom(foregroundColor: p.erroTexto, minimumSize: const Size(44, 44)),
              child: const Text('Cancelar rolê'),
            ),
          ),
        ],
      ],
    );
  }

  String _fmtOption(TimeOption o) =>
      DateFormat("EEE, d 'de' MMM · HH:mm", 'pt_BR').format(o.inicioUtc.toLocal());
}

// ===========================================================================
// Pedaços da tela
// ===========================================================================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.plan, required this.votedCount, required this.memberCount});

  final Plan plan;
  final int votedCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final tag = planStatusTag(plan);
    final remaining = plan.status == PlanStatus.votando ? formatRemaining(plan.prazoVotacao) : null;
    final prazo = DateFormat("EEE, d 'de' MMM 'às' HH:mm", 'pt_BR').format(plan.prazoVotacao.toLocal());

    return RetroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RetroTag(tag.label, color: tag.color),
              if (remaining != null)
                Text(remaining.toUpperCase(), style: EmberText.mono(10, color: p.textoSecundario)),
            ],
          ),
          const SizedBox(height: 12),
          Text(plan.titulo, style: EmberText.display(28)),
          const SizedBox(height: 8),
          Text(
            plan.status == PlanStatus.votando ? 'Votação até $prazo' : 'Votação encerrada',
            style: EmberText.body(14, color: p.textoSecundario),
          ),
          if (memberCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$votedCount de $memberCount já ${votedCount == 1 ? 'votou' : 'votaram'}',
              style: EmberText.body(14, color: p.textoSecundario, weight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.link, required this.onCopy, required this.onShare});

  final String link;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return RetroCard(
      color: EmberColors.sol,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('LINK PARA A GALERA', style: EmberText.mono(11, color: EmberColors.tinta)),
          const SizedBox(height: 4),
          Text(
            'Quem receber vota pelo navegador, sem instalar nada.',
            style: EmberText.body(13, color: EmberColors.tinta),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: EmberColors.creme,
              borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
              border: Border.all(color: p.contorno, width: 2),
            ),
            child: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EmberText.mono(12, color: EmberColors.tinta).copyWith(letterSpacing: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RetroButton(
                  onPressed: onCopy,
                  color: EmberColors.branco,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.copy_rounded, size: 18), SizedBox(width: 6), Text('Copiar')],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RetroButton(
                  onPressed: onShare,
                  color: EmberColors.tinta,
                  foregroundColor: EmberColors.creme,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.ios_share_rounded, size: 18), SizedBox(width: 6), Text('Mandar')],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.voted});

  final PlanMember member;
  final bool voted;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final initial = member.nome.isNotEmpty ? member.nome[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: member.isOrganizador ? EmberColors.sol : EmberColors.lavanda,
              shape: BoxShape.circle,
              border: Border.all(color: p.contorno, width: 2),
            ),
            child: Text(initial, style: EmberText.body(14, color: EmberColors.tinta, weight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.nome, style: EmberText.body(15, weight: FontWeight.w700)),
                if (member.isOrganizador)
                  Text('ORGANIZADOR', style: EmberText.mono(9, color: p.textoSecundario)),
              ],
            ),
          ),
          RetroTag(voted ? 'Votou' : 'Falta votar', color: voted ? EmberColors.menta : EmberColors.neblina),
        ],
      ),
    );
  }
}

