import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/supabase/supabase_client.dart';
import '../../shared/widgets/ember_button.dart';
import '../../shared/widgets/ember_logo.dart';
import '../../shared/widgets/retro_top_bar.dart';
import '../../theme/ember_retro_theme.dart';
import '../connections/providers/connections_providers.dart';
import '../places/domain/place.dart';
import '../places/presentation/place_widgets.dart';
import '../places/providers/place_providers.dart';
import '../plans/domain/invite_message.dart';
import '../plans/domain/plan.dart';
import '../plans/domain/plan_member.dart';
import '../plans/domain/tally.dart';
import '../plans/domain/time_option.dart';
import '../plans/domain/time_vote.dart';
import '../plans/presentation/plan_widgets.dart';
import '../plans/presentation/vote_ui.dart';
import '../plans/providers/plan_providers.dart';

/// Página do convidado, aberta pelo link `https://chamma.site/#/r/<slug>`.
///
/// No navegador, sem conta: ao entrar, o convidado ganha uma sessão anônima
/// do Supabase (fica salva no navegador), então pode voltar e trocar o voto.
/// No app (link aberto pelo celular), funciona igual e ainda permite o vínculo.
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
      top: RetroTopBar(
        left: 'BORA',
        right: 'VOTAR',
        leading: kIsWeb
            ? null
            : RetroButton.icon(
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                shape: RetroButtonShape.circle,
                semanticLabel: 'Voltar',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
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

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
        setState(() => _joinError = e.toString().contains('limite_pessoas')
            ? 'Esse rolê já está cheio. Fala com quem te chamou.'
            : 'Não deu pra entrar no rolê. Tenta de novo em instantes.');
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _claim(PlanMember member) async {
    if (_joining) return;
    setState(() {
      _joining = true;
      _joinError = null;
    });
    try {
      await ref.read(planRepositoryProvider).claimMember(memberId: member.id);
      ref.invalidate(myMemberProvider(plan.id));
      ref.invalidate(unclaimedMembersProvider(plan.id));
      await ref.read(myMemberProvider(plan.id).future);
    } catch (_) {
      if (mounted) setState(() => _joinError = 'Não deu pra entrar no rolê. Tenta de novo em instantes.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _vote(TimeOption option, PlanMember me, Disp disp) async {
    setState(() => _pending[option.id!] = disp);
    try {
      await ref.read(planRepositoryProvider).vote(timeOptionId: option.id!, memberId: me.id, disp: disp);
      ref.invalidate(planVotesProvider(plan.id));
      if (isRealUserSession()) ref.invalidate(myPlanOverviewsProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _pending.remove(option.id));
        _snack('Não deu pra salvar o voto. Tenta de novo.');
      }
    }
  }

  Future<void> _suggestTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 19, minute: 0));
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      await ref.read(planRepositoryProvider).addTimeOption(planId: plan.id, inicio: dt);
      ref.invalidate(planOptionsProvider(plan.id));
      _snack('Horário sugerido!');
    } catch (e) {
      _snack(e.toString().contains('limite_horarios')
          ? 'Esse rolê já tem o máximo de horários.'
          : 'Não deu pra sugerir. Tenta de novo.');
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
    final showTally = !plan.votoAnonimo;
    final tallyById = {for (final t in ranking) t.option.id!: t};
    final byId = {for (final m in members) m.id: m};

    final canNames = <String, List<String>>{};
    final eliminatedBy = <String, String>{};
    for (final v in votes) {
      final m = byId[v.memberId];
      if (m == null) continue;
      if (v.disp == Disp.posso) (canNames[v.timeOptionId] ??= []).add(m.nome);
      if (v.disp == Disp.naoPosso && essentials.containsKey(v.memberId) && plan.essencialVisivel) {
        eliminatedBy[v.timeOptionId] = m.nome;
      }
    }

    final myVotes = <String, Disp>{
      for (final v in votes)
        if (me != null && v.memberId == me.id) v.timeOptionId: v.disp,
      ..._pending,
    };
    final votedIds = votes.map((v) => v.memberId).toSet();
    final canVote = plan.isVotingOpen && me != null;
    final votedCount = options.where((o) => myVotes.containsKey(o.id)).length;
    final votedAll = options.isNotEmpty && votedCount == options.length;
    final possoCount = myVotes.values.where((d) => d == Disp.posso).length;
    final possoLimitReached = plan.limitePosso > 0 && possoCount >= plan.limitePosso;
    final organizer = _organizerName(members);

    TimeOption? finalOption;
    for (final o in options) {
      if (o.id == plan.horarioFinalId) finalOption = o;
    }

    final children = <Widget>[];

    // ------------------------------------------------ rolê fechado
    if (plan.status == PlanStatus.fechado && finalOption != null) {
      final finalId = finalOption.id!;
      final quando = finalOption.inicioUtc;
      final going = [
        for (final v in votes)
          if (v.timeOptionId == finalId && v.disp == Disp.posso && byId[v.memberId] != null) byId[v.memberId]!,
      ];
      children.addAll([
        ClosedTicket(
          titulo: plan.titulo,
          quando: quando,
          place: place,
        ),
        const SizedBox(height: 16),
        if (place != null) ...[PlaceCard(place: place), const SizedBox(height: 18)],
        if (showTally)
          GoingCard(
            going: going,
            talvez: votes.where((v) => v.timeOptionId == finalId && v.disp == Disp.talvez).length,
          ),
      ]);
    } else {
      // ---------------------------------------------- convite
      children.addAll([
        _InviteHeader(plan: plan, organizer: organizer, optionsCount: options.length, place: place),
        const SizedBox(height: 14),
        if (place != null) ...[PlaceCard(place: place), const SizedBox(height: 16)],
        if (kIsWeb && me == null) ...[_OpenInAppCard(slug: plan.slug), const SizedBox(height: 16)],
      ]);

      if (plan.isVotingOpen && me == null) {
        children.add(meAsync.isLoading
            ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            : _JoinOrClaimSection(
                plan: plan,
                votedIds: votedIds,
                nameController: _nameController,
                joining: _joining,
                joinError: _joinError,
                onJoin: _join,
                onClaim: _claim,
              ));
        children.add(const SizedBox(height: 18));
      }

      if (!plan.isVotingOpen && plan.status == PlanStatus.votando) {
        children.addAll([
          const _InfoBox(
            icon: Icons.timer_off_rounded,
            text: 'O prazo de votação acabou. Agora é com quem organizou: logo sai o horário.',
          ),
          const SizedBox(height: 18),
        ]);
      }
      if (plan.status == PlanStatus.cancelado) {
        children.addAll([
          const _InfoBox(icon: Icons.block_rounded, text: 'Esse rolê foi cancelado por quem organizou.'),
          const SizedBox(height: 18),
        ]);
      }

      // ---------------------------------------------- votar
      if (canVote) {
        children.addAll([
          _HelloStrip(nome: me!.nome, done: votedCount, total: options.length),
          const SizedBox(height: 14),
          if (votedAll) ...[
            _DoneCard(
              prazo: plan.prazoVotacao,
              myVotes: [
                for (final o in options)
                  if (myVotes[o.id] != null) (o, myVotes[o.id]!),
              ],
              leader: showTally ? leader : null,
            ),
            const SizedBox(height: 16),
          ],
        ]);
      }

      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(canVote ? 'Quando você pode?' : 'Horários', style: EmberText.display(22))),
          if (canVote && !votedAll) Text('TOQUE NUMA OPÇÃO', style: EmberText.mono(10, color: p.textoSecundario)),
        ],
      ));
      children.add(const SizedBox(height: 10));
      if (options.isEmpty) {
        children.add(Text('Nenhum horário cadastrado ainda.', style: EmberText.body(14, color: p.textoSecundario)));
      }
      for (final o in options) {
        children.addAll([
          OptionVoteCard(
            option: o,
            tally: tallyById[o.id] ?? OptionTally(o),
            canNames: showTally ? (canNames[o.id] ?? const []) : const [],
            myVote: myVotes[o.id],
            big: true,
            pending: canVote && myVotes[o.id] == null,
            showTally: showTally,
            isLeader: showTally && leader?.option.id == o.id && plan.status == PlanStatus.votando,
            eliminatedBy: eliminatedBy[o.id],
            onVote: canVote
                ? (d) {
                    if (d == Disp.posso && possoLimitReached && myVotes[o.id] != Disp.posso) {
                      _snack('Dá pra marcar "Posso" em até ${plan.limitePosso} '
                          '${plan.limitePosso == 1 ? 'horário' : 'horários'}.');
                      return;
                    }
                    _vote(o, me!, d);
                  }
                : null,
          ),
          const SizedBox(height: 10),
        ]);
      }

      if (plan.permitirSugestoes && canVote) {
        children.addAll([
          Center(
            child: TextButton.icon(
              onPressed: _suggestTime,
              style: TextButton.styleFrom(foregroundColor: p.texto, minimumSize: const Size(44, 44)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Nenhum serve? Sugerir outro horário',
                style: EmberText.body(13.5, weight: FontWeight.w700).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ]);
      }

      // ---------------------------------------------- galera
      if (members.isNotEmpty) {
        children.addAll([
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('Galera', style: EmberText.display(22))),
              Text(
                showTally
                    ? '${votedIds.length} DE ${members.length} VOTARAM'
                    : '${members.length} ${members.length == 1 ? 'PESSOA' : 'PESSOAS'}',
                style: EmberText.mono(10, color: p.textoSecundario),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RetroCard(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in members)
                  _MemberChip(
                    member: m,
                    isMe: me != null && m.id == me.id,
                    voted: showTally && votedIds.contains(m.id),
                  ),
              ],
            ),
          ),
        ]);
      }
    }

    // ------------------------------------------------ vínculo (no app, com conta)
    if (me != null && me.connectionId != null && me.userId != plan.criadorId && isRealUserSession()) {
      children.addAll([
        const SizedBox(height: 16),
        _LinkCard(member: me, organizer: organizer ?? 'quem organizou'),
      ]);
    }

    children.addAll([
      const SizedBox(height: 28),
      _Footer(showAppCta: kIsWeb),
    ]);

    final showBar = canVote && !votedAll && options.isNotEmpty;
    final faltam = options.length - votedCount;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 26, 16, showBar ? 96 : 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ],
          ),
        ),
        // Barra fixa: quanto falta pra terminar de votar.
        if (showBar)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.linhaSuave,
                    borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
                    border: p.contornoBorda,
                  ),
                  child: Text(
                    'Falta ${faltam == 1 ? '1 horário' : '$faltam horários'}',
                    style: EmberText.body(15, color: p.textoSecundario, weight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _organizerName(List<PlanMember> members) {
    for (final m in members) {
      if (m.isOrganizador) return m.nome;
    }
    return null;
  }
}

// ===========================================================================
// Pedaços da tela
// ===========================================================================

class _InviteHeader extends StatelessWidget {
  const _InviteHeader({required this.plan, required this.organizer, required this.optionsCount, this.place});

  final Plan plan;
  final String? organizer;
  final int optionsCount;
  final Place? place;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final remaining = plan.status == PlanStatus.votando ? formatRemaining(plan.prazoVotacao) : null;
    final prazo = DateFormat("EEE, d 'de' MMM 'às' HH:mm", 'pt_BR').format(plan.prazoVotacao.toLocal());
    const ink = EmberColors.tinta;
    final quem = organizer?.trim().split(' ').first;

    Widget tag(IconData icon, String text, {Color color = EmberColors.creme}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.contorno, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: ink),
              const SizedBox(width: 4),
              Flexible(child: Text(text.toUpperCase(), overflow: TextOverflow.ellipsis, style: EmberText.mono(9.5, color: ink))),
            ],
          ),
        );

    return RetroCard(
      color: EmberColors.sol,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EmberColors.creme,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.contorno, width: 2.5),
                ),
                child: Text(quem == null || quem.isEmpty ? '?' : quem[0].toUpperCase(),
                    style: EmberText.body(16, color: ink, weight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quem == null || quem.isEmpty ? 'VOCÊ FOI CHAMADO\nPRO ROLÊ' : '${quem.toUpperCase()} TE CHAMOU\nPRO ROLÊ',
                  style: EmberText.mono(10.5, color: ink).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(plan.titulo, style: EmberText.display(28, color: ink).copyWith(height: 1.05)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (optionsCount > 0)
                tag(Icons.calendar_today_rounded, '$optionsCount ${optionsCount == 1 ? 'horário' : 'horários'}'),
              if (place != null) tag(Icons.place_rounded, place!.nome),
              if (remaining != null) tag(Icons.timer_rounded, remaining, color: EmberColors.brasa),
            ],
          ),
          if (plan.status == PlanStatus.votando) ...[
            const SizedBox(height: 8),
            Text('Votação até $prazo', style: EmberText.body(13, color: ink, weight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

/// Entrar no rolê: escolher o nome na lista (quem o organizador chamou) ou digitar.
class _JoinOrClaimSection extends ConsumerStatefulWidget {
  const _JoinOrClaimSection({
    required this.plan,
    required this.votedIds,
    required this.nameController,
    required this.joining,
    required this.joinError,
    required this.onJoin,
    required this.onClaim,
  });

  final Plan plan;
  final Set<String> votedIds;
  final TextEditingController nameController;
  final bool joining;
  final String? joinError;
  final VoidCallback onJoin;
  final ValueChanged<PlanMember> onClaim;

  @override
  ConsumerState<_JoinOrClaimSection> createState() => _JoinOrClaimSectionState();
}

class _JoinOrClaimSectionState extends ConsumerState<_JoinOrClaimSection> {
  bool _typing = false;
  PlanMember? _selected;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final unclaimedAsync = ref.watch(unclaimedMembersProvider(widget.plan.id));
    final joinCard = _JoinCard(
      controller: widget.nameController,
      loading: widget.joining,
      error: widget.joinError,
      onSubmit: widget.onJoin,
    );

    return unclaimedAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (_, __) => joinCard,
      data: (unclaimed) {
        if (!widget.plan.linkAberto && unclaimed.isEmpty) {
          return const _InfoBox(
            icon: Icons.lock_rounded,
            text: 'Esse rolê é só pra quem foi adicionado. Pede pra quem organizou te colocar na lista.',
          );
        }
        if (unclaimed.isEmpty || (_typing && widget.plan.linkAberto)) return joinCard;

        final sel = _selected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quem é você?', style: EmberText.display(22)),
            const SizedBox(height: 2),
            Text('Toque no seu nome. Sem conta, sem app.', style: EmberText.body(13.5, color: p.textoSecundario)),
            const SizedBox(height: 12),
            for (final m in unclaimed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NameRow(
                  member: m,
                  selected: sel?.id == m.id,
                  showStar: widget.plan.essencialVisivel && m.essencial,
                  onTap: () => setState(() => _selected = m),
                ),
              ),
            if (widget.joinError != null) ...[
              const SizedBox(height: 4),
              RetroErrorBox(widget.joinError!),
            ],
            if (widget.plan.linkAberto)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _typing = true),
                  style: TextButton.styleFrom(foregroundColor: p.texto, minimumSize: const Size(44, 44)),
                  child: Text('Não tô na lista',
                      style: EmberText.body(13.5, weight: FontWeight.w700).copyWith(decoration: TextDecoration.underline)),
                ),
              ),
            const SizedBox(height: 6),
            RetroButton(
              onPressed: sel == null || widget.joining ? null : () => widget.onClaim(sel),
              expand: true,
              height: 52,
              child: widget.joining
                  ? const RetroButtonSpinner()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            sel == null ? 'Escolha seu nome' : 'Sou ${sel.nome.trim().split(' ').first}, bora votar',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.member, required this.selected, required this.showStar, required this.onTap});

  final PlanMember member;
  final bool selected;
  final bool showStar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final nome = member.nome.trim();
    return Semantics(
      button: true,
      selected: selected,
      label: nome,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? EmberColors.menta.withAlpha(50) : p.superficie,
            borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
            border: Border.all(color: p.contorno, width: selected ? 3.5 : 2.5),
            boxShadow: selected ? null : [BoxShadow(color: p.contorno, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EmberColors.lavanda,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.contorno, width: 2),
                ),
                child: Text(nome.isEmpty ? '?' : nome[0].toUpperCase(),
                    style: EmberText.body(13, color: EmberColors.tinta, weight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(nome, style: EmberText.body(15, weight: FontWeight.w700))),
              if (showStar) const Icon(Icons.star_rounded, size: 18, color: EmberColors.brasa),
              if (selected) ...[
                const SizedBox(width: 6),
                const RetroTag('Você?', color: EmberColors.menta),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.controller, required this.loading, required this.error, required this.onSubmit});

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
          Text('Diz seu nome pra galera saber quem é. Não precisa de conta nem de app.',
              style: EmberText.body(14, color: p.textoSecundario)),
          const SizedBox(height: 14),
          const RetroFieldLabel('Seu nome'),
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
          EmberButton(label: 'Entrar e votar', expand: true, isLoading: loading, onPressed: hasName ? onSubmit : null),
        ],
      ),
    );
  }
}

class _HelloStrip extends StatelessWidget {
  const _HelloStrip({required this.nome, required this.done, required this.total});

  final String nome;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final first = nome.trim().split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: EmberColors.sol,
                shape: BoxShape.circle,
                border: Border.all(color: p.contorno, width: 2.5),
              ),
              child: Text(first.isEmpty ? '?' : first[0].toUpperCase(),
                  style: EmberText.body(15, color: EmberColors.tinta, weight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Oi, $first!', style: EmberText.body(15, weight: FontWeight.w800)),
                  Text(
                    done == total ? 'Dá pra mudar o voto até o prazo.' : 'Marca se você pode em cada horário.',
                    style: EmberText.body(12.5, color: p.textoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: i < done ? EmberColors.sol : p.superficie,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: p.contorno, width: 2),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text('$done DE $total', style: EmberText.mono(10.5, color: p.texto)),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Voto enviado!" com o resumo e o horário que está na frente.
class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.prazo, required this.myVotes, required this.leader});

  final DateTime prazo;
  final List<(TimeOption, Disp)> myVotes;
  final OptionTally? leader;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final prazoTxt = DateFormat("EEE d, HH'h'mm", 'pt_BR').format(prazo.toLocal()).replaceAll('.', '');
    final l = leader;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroCard(
          color: EmberColors.menta,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: EmberColors.creme,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.contorno, width: 3),
                ),
                child: const Icon(Icons.check_rounded, size: 30, color: EmberColors.tinta),
              ),
              const SizedBox(height: 8),
              Text('Voto enviado!', style: EmberText.display(24, color: EmberColors.tinta)),
              Text('Dá pra mudar até $prazoTxt.',
                  style: EmberText.body(13, color: EmberColors.tinta, weight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        RetroCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('SEUS VOTOS', style: EmberText.mono(10, color: p.textoSecundario)),
              const SizedBox(height: 6),
              for (final (o, d) in myVotes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${diaCurto(o.inicioUtc)} · ${hora(o.inicioUtc)}',
                            style: EmberText.body(13.5, weight: FontWeight.w600)),
                      ),
                      RetroTag(
                        switch (d) { Disp.posso => 'Posso', Disp.talvez => 'Talvez', Disp.naoPosso => 'Não' },
                        color: switch (d) {
                          Disp.posso => EmberColors.menta,
                          Disp.talvez => EmberColors.lavanda,
                          Disp.naoPosso => EmberColors.neblina,
                        },
                      ),
                    ],
                  ),
                ),
              if (l != null) ...[
                Divider(height: 18, color: p.linhaSuave),
                Row(
                  children: [
                    const RetroTag('Liderando', color: EmberColors.sol),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${diaCurto(l.option.inicioUtc)} · ${hora(l.option.inicioUtc)}',
                          style: EmberText.body(14, weight: FontWeight.w800)),
                    ),
                    Text('${l.posso} PODEM', style: EmberText.mono(10, color: p.textoSecundario)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
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
    final first = member.nome.trim().split(' ').first;
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
          Text(isMe ? '$first (você)' : first,
              style: EmberText.body(13, weight: FontWeight.w700, color: voted ? EmberColors.tinta : p.texto)),
        ],
      ),
    );
  }
}

/// "Já tem o CHAMMA? Abrir no app" (só no navegador).
class _OpenInAppCard extends StatelessWidget {
  const _OpenInAppCard({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return RetroCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const EmberLogo(width: 40, semanticLabel: null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Já tem o CHAMMA?', style: EmberText.body(14, weight: FontWeight.w800)),
                Text('Abra no app pra votar e se conectar com quem te chamou.',
                    style: EmberText.body(12, color: p.textoSecundario)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RetroButton(
            onPressed: () => launchUrl(Uri.parse(AppConstants.appLink(slug))),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Abrir', style: EmberText.body(13, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// Pedido de vínculo com quem organizou (só pra quem está logado no app).
class _LinkCard extends ConsumerStatefulWidget {
  const _LinkCard({required this.member, required this.organizer});

  final PlanMember member;
  final String organizer;

  @override
  ConsumerState<_LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends ConsumerState<_LinkCard> {
  bool _sending = false;

  Future<void> _request() async {
    setState(() => _sending = true);
    try {
      await ref.read(connectionsRepositoryProvider).requestLink(widget.member.id);
      ref.invalidate(myLinkStatusProvider(widget.member.connectionId!));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Não deu pra pedir o vínculo. Tenta de novo.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final status = ref.watch(myLinkStatusProvider(widget.member.connectionId!));
    if (status.isLoading || status.hasError || status.valueOrNull == 'recusado') return const SizedBox.shrink();
    final quem = widget.organizer.split(' ').first;
    final (titulo, texto) = switch (status.valueOrNull) {
      'pendente' => ('Pedido enviado', 'Assim que $quem aceitar, vocês ficam conectados no CHAMMA.'),
      'aceito' => ('Vocês estão conectados', 'Os próximos rolês de $quem chegam direto no seu app.'),
      _ => ('Conectar com $quem?', 'Vocês viram conexão no app: os próximos rolês chegam direto pra você.'),
    };
    return RetroCard(
      color: EmberColors.lavanda.withAlpha(50),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(status.valueOrNull == 'aceito' ? Icons.check_circle_rounded : Icons.link_rounded, color: p.texto),
              const SizedBox(width: 10),
              Expanded(child: Text(titulo, style: EmberText.body(15, weight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 4),
          Text(texto, style: EmberText.body(13, color: p.textoSecundario)),
          if (status.valueOrNull == null) ...[
            const SizedBox(height: 12),
            RetroButton(
              onPressed: _sending ? null : _request,
              height: 44,
              color: EmberColors.lavanda,
              expand: true,
              child: _sending ? const RetroButtonSpinner() : const Text('Pedir vínculo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.showAppCta});

  /// No navegador: convite discreto pra baixar o app (sempre no fim, depois do voto).
  final bool showAppCta;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    if (!showAppCta) {
      return Column(
        children: [
          const EmberLogo(width: 44, semanticLabel: null),
          const SizedBox(height: 6),
          Text(AppConstants.appName, style: EmberText.display(16)),
          Text(AppConstants.slogan, textAlign: TextAlign.center, style: EmberText.body(12, color: p.textoSecundario)),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.invertido,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        border: p.contornoBorda,
      ),
      child: Row(
        children: [
          const EmberLogo(width: 48, semanticLabel: null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marque os seus rolês', style: EmberText.body(14.5, color: p.noInvertido, weight: FontWeight.w800)),
                Text('O CHAMMA é grátis. ${AppConstants.slogan}',
                    style: EmberText.body(12, color: p.noInvertido.withAlpha(200))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
