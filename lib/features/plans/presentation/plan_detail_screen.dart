import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../connections/presentation/widgets/connection_sheets.dart';
import '../../places/domain/place.dart';
import '../../places/presentation/place_widgets.dart';
import '../../places/providers/place_providers.dart';
import '../domain/invite_message.dart';
import '../domain/plan.dart';
import '../domain/plan_member.dart';
import '../domain/tally.dart';
import '../domain/time_option.dart';
import '../domain/time_vote.dart';
import '../providers/plan_providers.dart';
import 'create_plan/create_plan_widgets.dart' show RetroToggle;
import 'plan_widgets.dart';
import 'vote_ui.dart';

/// Painel do rolê. Organizador: quem falta, cutucar, placar com voto rápido,
/// local no mapa e fechar com um toque. Convidado com o app: votar e ver tudo.
class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  Timer? _ticker;
  bool _busy = false;
  bool _autoClosing = false;

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

  void _back() => context.canPop() ? context.pop() : context.go('/');

  Future<void> _refresh() async {
    ref.invalidate(planProvider(widget.planId));
    ref.invalidate(planOptionsProvider(widget.planId));
    ref.invalidate(myMemberProvider(widget.planId));
    await ref.read(planProvider(widget.planId).future);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _share(String text, String subject) async {
    try {
      await Share.share(text, subject: subject);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- ações

  Future<void> _vote(TimeOption option, PlanMember me, Disp disp) async {
    try {
      await ref.read(planRepositoryProvider).vote(timeOptionId: option.id!, memberId: me.id, disp: disp);
      ref.invalidate(myPlanOverviewsProvider);
      ref.invalidate(planVotesProvider(widget.planId));
    } catch (_) {
      if (mounted) _snack('Não deu pra salvar o voto. Tenta de novo.');
    }
  }

  Future<void> _copyLink(Plan plan) async {
    await Clipboard.setData(ClipboardData(text: AppConstants.guestLink(plan.slug)));
    if (mounted) _snack('Link copiado!');
  }

  void _shareInvite(Plan plan, List<TimeOption> options, List<PlanMember> members, Place? place) {
    String? organizer;
    for (final m in members) {
      if (m.isOrganizador) organizer = m.nome;
    }
    _share(
      buildInviteMessage(plan: plan, options: options, organizerName: organizer, local: place?.nome),
      plan.titulo,
    );
  }

  void _nudge(Plan plan, List<PlanMember> pending) =>
      _share(buildReminderMessage(plan: plan, pendingNames: [for (final m in pending) m.nome]), plan.titulo);

  Future<void> _pickPlace(Plan plan, Place? current) async {
    final draft = await context.push<PlaceDraft>('/map-picker', extra: current?.asDraft);
    if (draft == null || !mounted) return;
    try {
      await ref.read(placeRepositoryProvider).setPlanPlace(planId: plan.id, draft: draft);
      ref.invalidate(myPlansProvider);
      await _refresh();
      if (mounted) _snack('Local salvo! A galera já vê no link.');
    } catch (_) {
      if (mounted) _snack('Não deu pra salvar o local. Tenta de novo.');
    }
  }

  Future<void> _closePlan({
    required Plan plan,
    required List<OptionTally> ranking,
    required Map<String, String> eliminatedBy,
    required List<PlanMember> pending,
    required Place? place,
  }) async {
    final choices = [for (final t in ranking) if (eliminatedBy[t.option.id] == null) t];
    if (choices.isEmpty) return;
    final result = await showRetroSheet<(OptionTally, bool)>(
      context,
      (_) => _CloseSheet(choices: choices, pending: pending, place: place),
    );
    if (result == null || !mounted) return;
    final (chosen, avisar) = result;
    setState(() => _busy = true);
    try {
      await ref.read(planRepositoryProvider).closePlan(planId: plan.id, timeOptionId: chosen.option.id!);
      ref.invalidate(myPlansProvider);
      await _refresh();
      if (mounted) _snack('Fechou!');
      if (avisar) {
        _share(
          buildClosedMessage(plan: plan, quando: chosen.option.inicioUtc, local: place?.nome, endereco: place?.endereco),
          plan.titulo,
        );
      }
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

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planProvider(widget.planId));

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SEU',
        right: 'ROLÊ',
        leading: RetroButton.icon(
          onPressed: _back,
          shape: RetroButtonShape.circle,
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
          return _buildContent(plan);
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
    final place = plan.lugarFinalId == null ? null : ref.watch(placeProvider(plan.lugarFinalId!)).valueOrNull;

    final essentials = {for (final m in members) if (m.essencial) m.id: m};
    final ranking = rankOptions(
      options,
      votes,
      essentialMemberIds: essentials.keys.toSet(),
      semRespostaContaComo: plan.semRespostaContaComo,
      totalMembers: members.length,
    );
    final hasClearLeader = ranking.isNotEmpty &&
        ranking.first.total > 0 &&
        !ranking.first.eliminated &&
        (ranking.length < 2 || ranking.first.score > ranking[1].score);
    final leader = hasClearLeader ? ranking.first : null;
    final tallyById = {for (final t in ranking) t.option.id!: t};
    final byId = {for (final m in members) m.id: m};

    // Quem pode em cada horário e qual essencial derrubou o horário.
    final canNames = <String, List<String>>{};
    final eliminatedBy = <String, String>{};
    for (final v in votes) {
      final m = byId[v.memberId];
      if (m == null) continue;
      if (v.disp == Disp.posso) (canNames[v.timeOptionId] ??= []).add(m.nome);
      if (v.disp == Disp.naoPosso && essentials.containsKey(v.memberId)) eliminatedBy[v.timeOptionId] = m.nome;
    }

    final myVotes = {
      for (final v in votes)
        if (me != null && v.memberId == me.id) v.timeOptionId: v.disp,
    };
    final votedIds = votes.map((v) => v.memberId).toSet();
    final guests = [for (final m in members) if (!m.isOrganizador) m];
    final pending = [for (final m in guests) if (!votedIds.contains(m.id)) m];
    final isOrganizer = me?.isOrganizador ?? false;
    final canVote = plan.isVotingOpen && me != null;
    final showNames = !plan.votoAnonimo;

    TimeOption? finalOption;
    for (final o in options) {
      if (o.id == plan.horarioFinalId) finalOption = o;
    }

    // Fecha sozinho quando o quórum bate e tem um horário na frente.
    if (plan.autoFechar &&
        plan.isVotingOpen &&
        plan.quorumMinimo > 0 &&
        votedIds.length >= plan.quorumMinimo &&
        leader != null &&
        isOrganizer &&
        !_autoClosing) {
      _autoClosing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await ref.read(planRepositoryProvider).closePlan(planId: plan.id, timeOptionId: leader.option.id!);
          ref.invalidate(myPlansProvider);
          await _refresh();
          if (mounted) _snack('Bateu o mínimo de votos: rolê fechado sozinho!');
        } catch (_) {
          if (mounted) _snack('Não deu pra fechar sozinho. Feche pelo botão.');
        }
        _autoClosing = false;
      });
    }

    final showCloseBar = isOrganizer && plan.status == PlanStatus.votando && votes.isNotEmpty && options.isNotEmpty;

    // ------------------------------------------------ rolê fechado
    if (plan.status == PlanStatus.fechado && finalOption != null) {
      final finalId = finalOption.id!;
      final going = [
        for (final v in votes)
          if (v.timeOptionId == finalId && v.disp == Disp.posso && byId[v.memberId] != null) byId[v.memberId]!,
      ];
      final talvez = votes.where((v) => v.timeOptionId == finalId && v.disp == Disp.talvez).length;
      final quando = finalOption.inicioUtc;
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 28),
          children: [
            ClosedTicket(
              titulo: plan.titulo,
              quando: quando,
              place: place,
              onShare: () => _share(
                buildClosedMessage(plan: plan, quando: quando, local: place?.nome, endereco: place?.endereco),
                plan.titulo,
              ),
            ),
            const SizedBox(height: 16),
            if (place != null)
              PlaceCard(place: place, onChange: isOrganizer ? () => _pickPlace(plan, place) : null)
            else if (isOrganizer)
              AddPlaceButton(onTap: () => _pickPlace(plan, null)),
            const SizedBox(height: 18),
            GoingCard(going: going, talvez: talvez),
          ],
        ),
      );
    }

    // ------------------------------------------------ votando / encerrado
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 26, 16, showCloseBar ? 110 : 28),
            children: [
              _StatusCard(
                plan: plan,
                voted: guests.length - pending.length,
                total: guests.length,
                pending: pending,
                isOrganizer: isOrganizer,
                onNudge: pending.isEmpty ? null : () => _nudge(plan, pending),
                onShare: () => _shareInvite(plan, options, members, place),
                onCopy: () => _copyLink(plan),
              ),
              const SizedBox(height: 16),

              // -------------------------------------- local
              if (place != null)
                PlaceCard(
                  place: place,
                  onChange: isOrganizer && plan.status == PlanStatus.votando ? () => _pickPlace(plan, place) : null,
                )
              else if (isOrganizer && plan.status == PlanStatus.votando)
                AddPlaceButton(onTap: () => _pickPlace(plan, null)),
              if (place != null || (isOrganizer && plan.status == PlanStatus.votando)) const SizedBox(height: 18),

              // -------------------------------------- horários
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Horários', style: EmberText.display(22))),
                  if (canVote) Text('SEU VOTO →', style: EmberText.mono(10, color: p.textoSecundario)),
                ],
              ),
              const SizedBox(height: 10),
              if (options.isEmpty)
                Text('Nenhum horário cadastrado.', style: EmberText.body(14, color: p.textoSecundario))
              else
                for (final o in options) ...[
                  OptionVoteCard(
                    option: o,
                    tally: tallyById[o.id] ?? OptionTally(o),
                    canNames: showNames ? (canNames[o.id] ?? const []) : const [],
                    myVote: myVotes[o.id],
                    onVote: canVote ? (d) => _vote(o, me!, d) : null,
                    isLeader: leader?.option.id == o.id && plan.status == PlanStatus.votando,
                    eliminatedBy: eliminatedBy[o.id],
                    totalPessoas: members.length,
                  ),
                  const SizedBox(height: 10),
                ],

              // -------------------------------------- galera
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Galera', style: EmberText.display(22))),
                  Text('${members.length} ${members.length == 1 ? 'PESSOA' : 'PESSOAS'}',
                      style: EmberText.mono(10, color: p.textoSecundario)),
                ],
              ),
              const SizedBox(height: 10),
              RetroCard(
                padding: const EdgeInsets.all(12),
                child: members.length <= 1
                    ? Text('Mande o link no grupo: quem abrir entra aqui na hora.',
                        style: EmberText.body(13, color: p.textoSecundario))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in members)
                            _MemberChip(
                              member: m,
                              voted: votedIds.contains(m.id),
                              showStar: m.essencial && (isOrganizer || plan.essencialVisivel),
                            ),
                        ],
                      ),
              ),

              if (isOrganizer && plan.status == PlanStatus.votando) ...[
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => _cancelPlan(plan),
                    style: TextButton.styleFrom(foregroundColor: p.erroTexto, minimumSize: const Size(44, 44)),
                    child: const Text('Cancelar rolê'),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ------------------------------------------ barra "fechar agora"
        if (showCloseBar)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _CloseBar(
              leader: leader,
              busy: _busy,
              onClose: () => _closePlan(
                plan: plan,
                ranking: ranking,
                eliminatedBy: eliminatedBy,
                pending: pending,
                place: place,
              ),
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// Pedaços da tela
// ===========================================================================

/// Cartão escuro do topo: status, prazo, quantos votaram e o que fazer.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.plan,
    required this.voted,
    required this.total,
    required this.pending,
    required this.isOrganizer,
    required this.onNudge,
    required this.onShare,
    required this.onCopy,
  });

  final Plan plan;
  final int voted;
  final int total;
  final List<PlanMember> pending;
  final bool isOrganizer;
  final VoidCallback? onNudge;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final fg = p.noInvertido;
    final tag = planStatusTag(plan);
    final remaining = plan.status == PlanStatus.votando ? formatRemaining(plan.prazoVotacao) : null;
    final frac = total == 0 ? 0.0 : voted / total;
    final nomes = [for (final m in pending) m.nome.trim().split(' ').first];
    final faltam = nomes.isEmpty
        ? (total == 0 ? 'Ninguém entrou ainda. Mande o link!' : 'Todo mundo votou!')
        : nomes.length <= 3
            ? '${nomes.length == 1 ? 'Falta' : 'Faltam'} ${nomes.length}: ${nomes.length == 1 ? nomes.first : '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}'}'
            : 'Faltam ${nomes.length}: ${nomes.take(2).join(', ')} e mais ${nomes.length - 2}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.invertido,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        border: p.contornoBorda,
        boxShadow: [p.sombraDeCard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RetroTag(tag.label, color: tag.color),
              const Spacer(),
              if (remaining != null) Text(remaining.toUpperCase(), style: EmberText.mono(10, color: EmberColors.sol)),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.titulo, style: EmberText.display(25, color: fg).copyWith(height: 1.05)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: frac,
                        strokeWidth: 7,
                        backgroundColor: fg.withAlpha(45),
                        valueColor: const AlwaysStoppedAnimation(EmberColors.menta),
                      ),
                    ),
                    Text('$voted/$total', style: EmberText.display(15, color: fg)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faltam, style: EmberText.body(13.5, color: fg, weight: FontWeight.w700)),
                    if (plan.lembreteHoras > 0 && plan.status == PlanStatus.votando)
                      Text('Lembrete ${plan.lembreteHoras}h antes do prazo',
                          style: EmberText.body(12, color: fg.withAlpha(190))),
                    if (plan.quorumMinimo > 0 && plan.status == PlanStatus.votando)
                      Text(
                        '${plan.autoFechar ? 'Fecha sozinho com' : 'Mínimo de'} ${plan.quorumMinimo} votos',
                        style: EmberText.body(12, color: fg.withAlpha(190)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.status == PlanStatus.votando) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (isOrganizer && onNudge != null) ...[
                  Expanded(
                    child: RetroButton(
                      onPressed: onNudge,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active_rounded, size: 17),
                          const SizedBox(width: 6),
                          Flexible(child: Text('Cutucar quem falta', style: EmberText.body(13, weight: FontWeight.w800))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else
                  Expanded(
                    child: RetroButton(
                      onPressed: onShare,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.ios_share_rounded, size: 17),
                          const SizedBox(width: 6),
                          Text('Mandar link', style: EmberText.body(13, weight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                if (isOrganizer && onNudge != null)
                  _SquareButton(icon: Icons.ios_share_rounded, label: 'Mandar convite', onTap: onShare)
                else
                  const SizedBox(width: 8),
                const SizedBox(width: 8),
                _SquareButton(icon: Icons.link_rounded, label: 'Copiar link', onTap: onCopy),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RetroButton(
      onPressed: onTap,
      height: 40,
      color: EmberColors.creme,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      semanticLabel: label,
      child: Icon(icon, size: 18),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member, required this.voted, required this.showStar});

  final PlanMember member;
  final bool voted;
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
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
            size: 15,
            color: voted ? EmberColors.tinta : p.textoSecundario,
          ),
          const SizedBox(width: 4),
          Text(member.nome.trim().split(' ').first,
              style: EmberText.body(13, weight: FontWeight.w700, color: voted ? EmberColors.tinta : p.texto)),
          if (showStar) ...[
            const SizedBox(width: 3),
            Icon(Icons.star_rounded, size: 14, color: voted ? EmberColors.tinta : EmberColors.sol),
          ],
        ],
      ),
    );
  }
}

/// Barra fixa: o que acontece se fechar agora.
class _CloseBar extends StatelessWidget {
  const _CloseBar({required this.leader, required this.busy, required this.onClose});

  final OptionTally? leader;
  final bool busy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final l = leader;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        border: p.contornoBorda,
        boxShadow: [BoxShadow(color: p.contorno.withAlpha(90), offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l == null ? 'EMPATE' : 'SE FECHAR AGORA', style: EmberText.mono(10, color: p.textoSecundario)),
                Text(
                  l == null ? 'Escolha o horário' : '${diaCurto(l.option.inicioUtc)} · ${hora(l.option.inicioUtc)}',
                  style: EmberText.body(15, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
          RetroButton(
            onPressed: busy ? null : onClose,
            height: 42,
            color: EmberColors.menta,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: busy
                ? const RetroButtonSpinner()
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.check_rounded, size: 18), SizedBox(width: 6), Text('Fechar rolê')],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Confirmação de fechamento: horário escolhido, quem falta e outras opções.
class _CloseSheet extends StatefulWidget {
  const _CloseSheet({required this.choices, required this.pending, required this.place});

  final List<OptionTally> choices;
  final List<PlanMember> pending;
  final Place? place;

  @override
  State<_CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<_CloseSheet> {
  late OptionTally _chosen = widget.choices.first;
  bool _avisar = true;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final t = _chosen.option.inicioUtc;
    final nomes = [for (final m in widget.pending) m.nome.trim().split(' ').first];

    return RetroSheet(
      title: 'Fechar o rolê?',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EmberColors.menta,
            borderRadius: BorderRadius.circular(EmberRetro.raioCard),
            border: p.contornoBorda,
          ),
          child: Row(
            children: [
              DateBlock(date: t, width: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hora(t)}${widget.place == null ? '' : ' · ${widget.place!.nome}'}',
                      style: EmberText.display(20, color: EmberColors.tinta).copyWith(height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_chosen.posso} ${_chosen.posso == 1 ? 'pode' : 'podem'}'
                      '${_chosen.talvez > 0 ? ' · ${_chosen.talvez} talvez' : ''}',
                      style: EmberText.body(13, color: EmberColors.tinta, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (nomes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: EmberColors.sol.withAlpha(70),
              borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
              border: Border.all(color: p.contorno, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_rounded, size: 18, color: p.texto),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${nomes.length <= 3 ? nomes.join(', ') : '${nomes.take(3).join(', ')} e mais ${nomes.length - 3}'} '
                    '${nomes.length == 1 ? 'ainda não votou' : 'ainda não votaram'}. Quer esperar mais um pouco?',
                    style: EmberText.body(12.5, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text('Avisar a galera agora', style: EmberText.body(14.5, weight: FontWeight.w700))),
            RetroToggle(value: _avisar, onChanged: (v) => setState(() => _avisar = v), semanticLabel: 'Avisar a galera'),
          ],
        ),
        if (widget.choices.length > 1) ...[
          const SizedBox(height: 14),
          Text('OU ESCOLHA OUTRO', style: EmberText.mono(10.5, color: p.textoSecundario)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in widget.choices)
                ChoiceChip(
                  label: Text('${diaCurto(c.option.inicioUtc)} · ${hora(c.option.inicioUtc)}'),
                  selected: c == _chosen,
                  onSelected: (_) => setState(() => _chosen = c),
                  selectedColor: EmberColors.sol,
                  labelStyle: EmberText.body(13, color: c == _chosen ? EmberColors.tinta : p.texto, weight: FontWeight.w700),
                  side: BorderSide(color: p.contorno, width: 2),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: RetroButton(
                onPressed: () => Navigator.pop(context),
                color: p.botaoSecundario,
                child: const Text('Esperar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: RetroButton(
                onPressed: () => Navigator.pop(context, (_chosen, _avisar)),
                color: EmberColors.menta,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(_avisar ? 'Fechar e avisar' : 'Fechar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
