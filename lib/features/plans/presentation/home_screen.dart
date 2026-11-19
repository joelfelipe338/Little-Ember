import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/ember_logo.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../connections/domain/brasa.dart';
import '../../connections/presentation/widgets/connection_ui.dart';
import '../../subscription/domain/subscription.dart';
import '../../subscription/presentation/plus_sheet.dart';
import '../../subscription/providers/subscription_providers.dart';
import '../domain/invite_message.dart';
import '../domain/plan.dart';
import '../domain/plan_member.dart';
import '../domain/plan_overview.dart';
import '../domain/tally.dart';
import '../providers/plan_providers.dart';
import 'plan_widgets.dart' show planStatusTag;

/// Seus rolês: próximo rolê confirmado, o que precisa de você e a lista por aba.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  PlanBucket? _filter;
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final Set<String> _closing = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _refresh() async {
    ref.invalidate(myPlansProvider);
    await ref.read(myPlanOverviewsProvider.future);
  }

  void _open(PlanOverview o) => context.push('/plan/${o.plan.id}');

  /// Novo rolê, respeitando o limite de rolês em votação do plano.
  void _newPlan() {
    final all = ref.read(myPlanOverviewsProvider).valueOrNull ?? const <PlanOverview>[];
    final ativos = all.where((o) => o.isOrganizer && o.plan.isVotingOpen).length;
    final max = ref.read(subscriptionProvider).limit(PlanFeature.rolesAtivos);
    if (ativos >= max) {
      showPlusSheet(
        context,
        titulo: 'Limite de rolês em votação',
        motivo: 'No plano grátis dá pra ter $max rolês em votação ao mesmo tempo. Feche um ou conheça o CHAMMA+.',
      );
      return;
    }
    context.push('/create-plan');
  }

  Future<void> _shareInvite(PlanOverview o) async {
    try {
      await Share.share(
        buildInviteMessage(plan: o.plan, options: o.options, organizerName: o.organizer?.nome),
        subject: o.plan.titulo,
      );
    } catch (_) {}
  }

  Future<void> _nudge(PlanOverview o) async {
    try {
      await Share.share(
        buildReminderMessage(plan: o.plan, pendingNames: [for (final m in o.pending) m.nome]),
        subject: o.plan.titulo,
      );
    } catch (_) {}
  }

  Future<void> _closeWithLeader(PlanOverview o, OptionTally leader) async {
    final when = _fmtOption(leader.option.inicioUtc);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar o rolê?'),
        content: Text('O horário vai ser $when.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Agora não')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Fechar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _closing.add(o.plan.id));
    try {
      await ref.read(planRepositoryProvider).closePlan(planId: o.plan.id, timeOptionId: leader.option.id!);
      await _refresh();
      if (mounted) _snack('Fechou! Avisa a galera.');
    } catch (_) {
      if (mounted) _snack('Não deu pra fechar o rolê. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _closing.remove(o.plan.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myPlanOverviewsProvider);

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SEUS',
        right: 'ROLÊS',
        trailing: (async.valueOrNull?.isNotEmpty ?? false)
            ? RetroButton.icon(
                onPressed: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) _searchCtrl.clear();
                }),
                shape: RetroButtonShape.circle,
                semanticLabel: _searching ? 'Fechar busca' : 'Buscar rolê',
                icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
              )
            : null,
      ),
      panelPadding: EdgeInsets.zero,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RetroErrorBox('Não deu pra carregar seus rolês.'),
                const SizedBox(height: 16),
                EmberButton(label: 'Tentar de novo', onPressed: _refresh),
              ],
            ),
          ),
        ),
        data: (list) => list.isEmpty ? const _EmptyRoles() : _buildList(list),
      ),
    );
  }

  Widget _buildList(List<PlanOverview> all) {
    final p = RetroPalette.of(context);
    final query = normalizeName(_searchCtrl.text);
    final filtering = _filter != null || query.isNotEmpty;

    final counts = {for (final b in PlanBucket.values) b: all.where((o) => o.bucket == b).length};
    final upcoming = sortOverviews(all.where((o) => o.bucket == PlanBucket.fechados && o.finalTime != null));
    final next = upcoming.isEmpty ? null : upcoming.first;
    final needsMe = sortOverviews(all.where((o) => o.needsMyVote));

    final visible = sortOverviews(all.where((o) =>
        (_filter == null || o.bucket == _filter) &&
        (query.isEmpty || normalizeName(o.plan.titulo).contains(query)) &&
        // Sem filtro, quem já aparece em destaque não se repete na lista.
        (filtering || (o != next && !needsMe.contains(o)))));

    final title = switch (_filter) {
      null => 'Seus rolês',
      PlanBucket.votando => 'Votando',
      PlanBucket.fechados => 'Fechados',
      PlanBucket.passados => 'Passados',
    };

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 26, 14, 100),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text(title, style: EmberText.display(29))),
                  Text(
                    '${all.length} ${all.length == 1 ? 'ROLÊ' : 'ROLÊS'}',
                    style: EmberText.mono(10.5, color: p.textoSecundario),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_searching) ...[
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar pelo nome do rolê',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ------------------------------------------ próximo rolê
              if (!filtering && next != null) ...[
                _NextTicket(overview: next, onTap: () => _open(next), ),
                const SizedBox(height: 16),
              ],

              // ------------------------------------------ precisa de você
              if (!filtering && needsMe.isNotEmpty) ...[
                const SectionLabel('Precisa de você'),
                const SizedBox(height: 8),
                for (final o in needsMe.take(3)) ...[
                  _NeedsYouCard(overview: o, onTap: () => _open(o)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
              ],

              // ------------------------------------------ filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    RetroChoiceChip(
                      label: 'Todos',
                      trailing: '${all.length}',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final (b, label) in const [
                      (PlanBucket.votando, 'Votando'),
                      (PlanBucket.fechados, 'Fechados'),
                      (PlanBucket.passados, 'Passados'),
                    ]) ...[
                      const SizedBox(width: 8),
                      RetroChoiceChip(
                        label: label,
                        trailing: '${counts[b]}',
                        selected: _filter == b,
                        onTap: () => setState(() => _filter = _filter == b ? null : b),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    query.isNotEmpty
                        ? 'Nenhum rolê com esse nome.'
                        : (filtering ? 'Nada por aqui.' : 'Tudo em dia por aqui.'),
                    textAlign: TextAlign.center,
                    style: EmberText.body(15, color: p.textoSecundario, weight: FontWeight.w600),
                  ),
                ),
              for (final o in visible) ...[
                _PlanCard(
                  overview: o,
                  closing: _closing.contains(o.plan.id),
                  onTap: () => _open(o),
                  onClose: (l) => _closeWithLeader(o, l),
                  onNudge: () => _nudge(o),
                  onShare: () => _shareInvite(o),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: RetroButton(
            onPressed: _newPlan,
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

// ===========================================================================
// Formatação
// ===========================================================================

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _fmtOption(DateTime d) =>
    _cap(DateFormat("EEE, d 'de' MMM · HH:mm", 'pt_BR').format(d.toLocal()).replaceAll('.', ''));

String _fmtShort(DateTime d) => _cap(DateFormat("EEE d", 'pt_BR').format(d.toLocal()).replaceAll('.', ''));

String _relative(DateTime t) {
  final hoje = DateUtils.dateOnly(DateTime.now());
  final dias = DateUtils.dateOnly(t).difference(hoje).inDays;
  if (dias == 0) return 'HOJE';
  if (dias == 1) return 'AMANHÃ';
  if (dias > 1) return 'EM $dias DIAS';
  if (dias == -1) return 'ONTEM';
  return 'HÁ ${-dias} DIAS';
}

/// Linha "quando" do card.
String _whenLine(PlanOverview o) {
  final t = o.finalTime;
  if (o.plan.status == PlanStatus.fechado && t != null) return _fmtOption(t);
  final leader = o.leader;
  if (o.plan.status == PlanStatus.votando && leader != null && !o.plan.votoAnonimo) {
    return 'Liderando: ${_fmtOption(leader.option.inicioUtc)}';
  }
  final n = o.options.length;
  if (n == 0) return 'Sem horários';
  if (n == 1) return _fmtOption(o.options.first.inicioUtc);
  final a = _fmtShort(o.options.first.inicioUtc), b = _fmtShort(o.options.last.inicioUtc);
  return '${a == b ? a : '$a a $b'} · $n opções';
}

// ===========================================================================
// Pedaços da tela
// ===========================================================================

class _PeopleStack extends StatelessWidget {
  const _PeopleStack({required this.members});

  final List<PlanMember> members;

  static const _cores = [EmberColors.lavanda, EmberColors.menta, EmberColors.sol, EmberColors.brasa];

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final shown = members.take(4).toList();
    final extra = members.length - shown.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: shown.isEmpty ? 0 : 26.0 + (shown.length - 1) * 18,
          height: 26,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 18.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _cores[i % _cores.length],
                      shape: BoxShape.circle,
                      border: Border.all(color: p.contorno, width: 2),
                    ),
                    child: Text(
                      shown[i].nome.trim().isEmpty ? '?' : shown[i].nome.trim()[0].toUpperCase(),
                      style: EmberText.body(11, color: EmberColors.tinta, weight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (extra > 0) ...[
          const SizedBox(width: 6),
          Text('+$extra', style: EmberText.mono(10, color: p.texto)),
        ],
      ],
    );
  }
}

class _VotesBar extends StatelessWidget {
  const _VotesBar({required this.voted, required this.total});

  final int voted;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final frac = total == 0 ? 0.0 : (voted / total).clamp(0.0, 1.0);
    return Semantics(
      label: '$voted de $total votaram',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('VOTOS', style: EmberText.mono(9, color: p.textoSecundario)),
          const SizedBox(width: 6),
          Container(
            width: 72,
            height: 11,
            decoration: BoxDecoration(
              color: p.tela,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: p.contorno, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: frac,
              child: Container(color: EmberColors.menta),
            ),
          ),
          const SizedBox(width: 6),
          Text('$voted/$total', style: EmberText.mono(10, color: p.texto)),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.overview,
    required this.closing,
    required this.onTap,
    required this.onClose,
    required this.onNudge,
    required this.onShare,
  });

  final PlanOverview overview;
  final bool closing;
  final VoidCallback onTap;
  final ValueChanged<OptionTally> onClose;
  final VoidCallback onNudge;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final o = overview;
    final plan = o.plan;
    final tag = o.needsClosing ? (label: 'Prazo acabou', color: EmberColors.sol) : planStatusTag(plan);

    final hint = switch (o.bucket) {
      PlanBucket.votando when o.needsClosing => 'ESPERANDO VOCÊ',
      PlanBucket.votando => (formatRemaining(plan.prazoVotacao) ?? '').toUpperCase(),
      PlanBucket.fechados => o.finalTime == null ? '' : _relative(o.finalTime!),
      PlanBucket.passados => o.finalTime == null ? '' : _relative(o.finalTime!),
    };

    final nomeOrg = o.organizer?.nome.trim().split(' ').first ?? '';
    final organizer = nomeOrg.isEmpty ? 'Alguém' : nomeOrg;
    final who = o.isOrganizer
        ? 'Você organiza'
        : '$organizer te chamou${plan.isVotingOpen ? (o.iVoted ? ' · você votou' : ' · falta você') : ''}';

    final leader = o.leader;
    final canNudge = o.isOrganizer && plan.isVotingOpen;
    final votante = o.members.where((m) => !m.isOrganizador).length;

    return RetroCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RetroTag(tag.label, color: tag.color),
              const Spacer(),
              Text(hint, style: EmberText.mono(10, color: p.textoSecundario)),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.titulo, style: EmberText.display(21), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(who, style: EmberText.body(12.5, color: p.textoSecundario)),
          const SizedBox(height: 8),
          if (o.placeName != null) ...[
            Row(
              children: [
                Icon(Icons.place_rounded, size: 15, color: p.texto),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(o.placeName!,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: EmberText.body(13.5, weight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 15, color: p.texto),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _whenLine(o),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EmberText.body(13.5, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (o.needsClosing) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: EmberColors.sol.withAlpha(70),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.contorno, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_off_rounded, size: 16, color: p.texto),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      leader == null
                          ? 'A votação fechou e deu empate. Abra o rolê pra escolher o horário.'
                          : 'A votação fechou. Escolha o horário pra avisar a galera.',
                      style: EmberText.body(12.5, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _PeopleStack(members: o.members),
              const Spacer(),
              if (plan.status == PlanStatus.votando && votante > 0)
                _VotesBar(voted: o.members.where((m) => !m.isOrganizador && o.votedMemberIds.contains(m.id)).length, total: votante),
            ],
          ),

          // ------------------------------------------ ações
          if (o.needsClosing && leader != null) ...[
            const SizedBox(height: 10),
            RetroButton(
              onPressed: closing ? null : () => onClose(leader),
              height: 40,
              expand: true,
              color: EmberColors.menta,
              child: closing
                  ? const RetroButtonSpinner()
                  : Text('Fechar com ${_fmtShort(leader.option.inicioUtc).toLowerCase()} '
                      '${DateFormat('HH:mm').format(leader.option.inicioUtc.toLocal())}'),
            ),
          ] else if (canNudge) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (o.pending.isNotEmpty) ...[
                  Expanded(
                    child: RetroButton(
                      onPressed: onNudge,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('Cutucar ${o.pending.length}', style: EmberText.body(13, weight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: RetroButton(
                    onPressed: onShare,
                    height: 38,
                    color: p.botaoSecundario,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.ios_share_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('Mandar link', style: EmberText.body(13, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else if (o.needsMyVote) ...[
            const SizedBox(height: 10),
            RetroButton(
              onPressed: onTap,
              height: 38,
              expand: true,
              child: const Text('Votar agora'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Próximo rolê confirmado, em formato de ingresso.
class _NextTicket extends StatelessWidget {
  const _NextTicket({required this.overview, required this.onTap});

  final PlanOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final o = overview;
    final t = o.finalTime!;
    final confirmados = o.members.length;

    return Semantics(
      button: true,
      label: 'Próximo rolê: ${o.plan.titulo}, ${_fmtOption(t)}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.superficie,
            borderRadius: BorderRadius.circular(EmberRetro.raioCard),
            border: p.contornoBorda,
            boxShadow: [p.sombraDeCard],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 84,
                  color: EmberColors.menta,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('MMM', 'pt_BR').format(t).replaceAll('.', '').toUpperCase(),
                          style: EmberText.mono(10, color: EmberColors.tinta)),
                      Text('${t.day}', style: EmberText.display(34, color: EmberColors.tinta).copyWith(height: 1)),
                      Text(DateFormat('EEEE', 'pt_BR').format(t).split('-').first.toUpperCase(),
                          style: EmberText.mono(9, color: EmberColors.tinta)),
                    ],
                  ),
                ),
                Container(width: 3, color: p.contorno),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('PRÓXIMO ROLÊ', style: EmberText.mono(10, color: p.textoSecundario))),
                            Text(_relative(t), style: EmberText.mono(10, color: EmberColors.menta)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(o.plan.titulo,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: EmberText.display(19)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${DateFormat('HH:mm').format(t)} · $confirmados ${confirmados == 1 ? 'pessoa' : 'pessoas'}',
                                style: EmberText.body(12.5, weight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convite de outra pessoa esperando o seu voto.
class _NeedsYouCard extends StatelessWidget {
  const _NeedsYouCard({required this.overview, required this.onTap});

  final PlanOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final o = overview;
    final nomeOrg = o.organizer?.nome.trim().split(' ').first ?? '';
    final quem = nomeOrg.isEmpty ? 'Alguém' : nomeOrg;
    final restante = formatRemaining(o.plan.prazoVotacao);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: EmberColors.sol,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        border: p.contornoBorda,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: EmberColors.lavanda,
              shape: BoxShape.circle,
              border: Border.all(color: p.contorno, width: 2.5),
            ),
            child: Text(quem.isEmpty ? '?' : quem[0].toUpperCase(),
                style: EmberText.body(14, color: EmberColors.tinta, weight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$quem te chamou pro ${o.plan.titulo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EmberText.body(13.5, color: EmberColors.tinta, weight: FontWeight.w800)),
                Text(
                  '${restante == null ? 'Fecha logo' : _cap(restante)} · você ainda não votou',
                  style: EmberText.body(12, color: EmberColors.tinta),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RetroButton(
            onPressed: onTap,
            height: 36,
            color: EmberColors.branco,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Votar', style: EmberText.body(13, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// Primeiro uso: ensina o fluxo em 3 passos.
class _EmptyRoles extends StatelessWidget {
  const _EmptyRoles();

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    const passos = [
      ('1', 'Dê um nome', 'Churras, cinema, barzinho...', EmberColors.sol),
      ('2', 'Escolha horários', '2 a 5 opções é o ideal', EmberColors.lavanda),
      ('3', 'Mande o link', 'A galera vota sem instalar nada', EmberColors.menta),
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 128,
                  height: 128,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.superficie,
                    shape: BoxShape.circle,
                    border: p.contornoBorda,
                    boxShadow: [BoxShadow(color: p.contorno, offset: const Offset(0, 6))],
                  ),
                  child: const EmberLogo(width: 92),
                ),
              ),
              const SizedBox(height: 18),
              Text('Nenhuma brasa acesa', textAlign: TextAlign.center, style: EmberText.display(26)),
              const SizedBox(height: 4),
              Text('Marcar rolê leva 1 minuto:',
                  textAlign: TextAlign.center, style: EmberText.body(14, color: p.textoSecundario)),
              const SizedBox(height: 16),
              RetroCard(
                child: Column(
                  children: [
                    for (final (n, t, d, c) in passos)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: p.contorno, width: 2.5),
                              ),
                              child: Text(n, style: EmberText.display(17, color: EmberColors.tinta)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t, style: EmberText.body(14.5, weight: FontWeight.w800)),
                                  Text(d, style: EmberText.body(12.5, color: p.textoSecundario)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              EmberButton(
                label: 'Criar o primeiro rolê',
                icon: Icons.add_rounded,
                expand: true,
                onPressed: () => context.push('/create-plan'),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/connections'),
                  style: TextButton.styleFrom(foregroundColor: p.texto, minimumSize: const Size(44, 44)),
                  child: Text(
                    'Ou adicione sua galera nas Conexões',
                    style: EmberText.body(13, weight: FontWeight.w700).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
