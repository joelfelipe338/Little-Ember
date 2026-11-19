import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../connections/providers/connections_providers.dart';
import '../../places/domain/place.dart';
import '../../profile/providers/preferences_provider.dart';
import '../../subscription/domain/subscription.dart';
import '../../subscription/presentation/plus_sheet.dart';
import '../../subscription/providers/subscription_providers.dart';
import '../domain/invite_message.dart';
import '../domain/invited_person.dart';
import '../domain/time_option.dart';
import '../providers/plan_providers.dart';
import 'create_plan/create_plan_widgets.dart';
import 'create_plan/plan_rules.dart';
import 'create_plan/step_oque.dart';
import 'create_plan/step_quando.dart';
import 'create_plan/step_quem.dart';
import 'create_plan/step_revisar.dart';

/// Novo rolê em 4 passos curtos: O quê → Quando → Quem → Revisar e mandar.
///
/// Local do rolê: hoje é só um espaço "em breve" no passo 1. Quando o mapa
/// entrar, o passo 1 abre a escolha no mapa e o local vai em `plans.lugar_final_id`.
class CreatePlanScreen extends ConsumerStatefulWidget {
  const CreatePlanScreen({super.key, this.initialConvidados = const []});

  /// Convidados que já chegam marcados (ex.: escolhidos na tela de Conexões).
  final List<InvitedPerson> initialConvidados;

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  static const _steps = ['O quê', 'Quando', 'Quem', 'Revisar'];

  final _pageController = PageController();
  final _tituloController = TextEditingController();
  int _step = 0;
  bool _creating = false;

  final List<TimeOption> _options = [];
  late List<InvitedPerson> _convidados = [...widget.initialConvidados];
  bool _linkAberto = true;

  /// Modo pronto (Normal / Rápido / Secreto). Null = personalizado em [_customRules].
  /// Nos modos prontos as regras acompanham o número de convidados (mínimo de votos).
  late RuleMode? _mode = _initialMode();

  /// Local escolhido no mapa (opcional).
  PlaceDraft? _local;

  RuleMode _initialMode() {
    final preferido = ref.read(defaultRuleModeProvider);
    // Rápido e Secreto são do CHAMMA+: no grátis começa no Normal.
    if (preferido != RuleMode.normal && !ref.read(subscriptionProvider).modosAvancados) return RuleMode.normal;
    return preferido;
  }

  Subscription get _sub => ref.read(subscriptionProvider);

  void _plus(String titulo, String motivo) => showPlusSheet(context, titulo: titulo, motivo: motivo);
  PlanRules _customRules = const PlanRules();

  PlanRules get _rules =>
      _mode == null ? _customRules : PlanRules.preset(_mode!, convidados: _convidados.length);

  DateTime _prazo = DateTime.now().add(const Duration(days: 2));

  /// O usuário escolheu o prazo na mão: não mexe mais sozinho.
  bool _prazoTocado = false;

  @override
  void initState() {
    super.initState();
    _tituloController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tituloController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- regras do fluxo

  DateTime? get _firstOption => _options.isEmpty ? null : _options.first.inicioUtc;

  String? get _prazoError {
    if (!_prazo.isAfter(DateTime.now())) return 'Esse prazo já passou. Escolha outro.';
    final first = _firstOption;
    if (first != null && !_prazo.isBefore(first)) {
      return 'A votação precisa fechar antes do primeiro horário.';
    }
    return null;
  }

  bool get _canAdvance => switch (_step) {
        0 => _tituloController.text.trim().isNotEmpty,
        1 => _options.isNotEmpty,
        2 => _convidados.isNotEmpty || _linkAberto,
        _ => _prazoError == null,
      };

  bool get _hasData =>
      _tituloController.text.trim().isNotEmpty || _options.isNotEmpty || _convidados.isNotEmpty;

  List<PrazoSuggestion> get _suggestions {
    final first = _firstOption;
    if (first == null) return const [];
    final now = DateTime.now();
    final minimo = now.add(const Duration(minutes: 30));
    final amanha = DateUtils.dateOnly(now).add(const Duration(days: 1, hours: 20));
    final list = <PrazoSuggestion>[
      PrazoSuggestion('1 dia antes', first.subtract(const Duration(days: 1))),
      PrazoSuggestion('Amanhã 20h', amanha),
      PrazoSuggestion('2h antes', first.subtract(const Duration(hours: 2))),
    ];
    final seen = <DateTime>{};
    return [
      for (final s in list)
        if (s.when.isAfter(minimo) && s.when.isBefore(first) && seen.add(s.when)) s,
    ];
  }

  /// Sugere um prazo enquanto o usuário não escolher um.
  void _fitPrazo() {
    if (_prazoTocado) return;
    final s = _suggestions;
    if (s.isNotEmpty) {
      _prazo = s.first.when;
      return;
    }
    final first = _firstOption;
    if (first != null) {
      final candidate = first.subtract(const Duration(minutes: 30));
      if (candidate.isAfter(DateTime.now())) _prazo = candidate;
    }
  }

  // ---------------------------------------------------------------- navegação

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      if (_step == _steps.length - 1) _fitPrazo();
    });
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  void _next() {
    if (_step < _steps.length - 1) _goTo(_step + 1);
  }

  Future<void> _back() async {
    if (_step > 0) {
      _goTo(_step - 1);
      return;
    }
    await _close();
  }

  Future<void> _close() async {
    if (_hasData) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Descartar o rolê?'),
          content: const Text('O que você preencheu até aqui vai ser perdido.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: RetroPalette.of(ctx).erroTexto),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  // ---------------------------------------------------------------- ações

  void _toggleOption(DateTime dt) {
    setState(() {
      final i = _options.indexWhere((o) => o.inicioUtc == dt);
      if (i >= 0) {
        _options.removeAt(i);
      } else {
        final max = _sub.limit(PlanFeature.horariosPorRole);
        if (_options.length >= max) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _plus(
                'Limite de horários',
                'No plano grátis cada rolê tem até $max horários. Com o CHAMMA+ são até '
                    '${Subscription.plusPadrao[PlanFeature.horariosPorRole]}.',
              ));
          return;
        }
        _options.add(TimeOption(inicioUtc: dt));
        _options.sort((a, b) => a.inicioUtc.compareTo(b.inicioUtc));
      }
    });
  }

  void _removeOption(DateTime dt) => setState(() => _options.removeWhere((o) => o.inicioUtc == dt));

  Future<void> _pickPlace() async {
    FocusScope.of(context).unfocus();
    final d = await context.push<PlaceDraft>('/map-picker', extra: _local);
    if (d != null && mounted) setState(() => _local = d);
  }

  void _setConvidados(List<InvitedPerson> list) {
    final max = _sub.limit(PlanFeature.pessoasPorRole);
    if (list.length > max && list.length > _convidados.length) {
      _plus('Limite de pessoas', 'No plano grátis cada rolê tem até $max pessoas. Com o CHAMMA+ a galera não tem limite.');
      return;
    }
    setState(() => _convidados = list);
  }

  void _setMode(RuleMode m) {
    if (m != RuleMode.normal && !_sub.modosAvancados) {
      _plus('Modo ${m.titulo}', 'Os modos Rápido e Secreto fazem parte do CHAMMA+.');
      return;
    }
    setState(() => _mode = m);
  }

  void _setRules(PlanRules r) {
    final avancado = r.autoFechar || r.votoAnonimo || r.limitePosso > 0;
    if (avancado && !_sub.modosAvancados) {
      _plus('Recurso do CHAMMA+', 'Fechar sozinho, voto secreto e limite de "Posso" fazem parte do CHAMMA+.');
      return;
    }
    setState(() {
      _customRules = r;
      _mode = r.modeFor(_convidados.length);
    });
  }

  Future<void> _customPrazo() async {
    final now = DateTime.now();
    final last = _firstOption ?? now.add(const Duration(days: 60));
    final date = await showDatePicker(
      context: context,
      initialDate: _prazo.isAfter(now) && _prazo.isBefore(last) ? _prazo : now,
      firstDate: now,
      lastDate: last.isAfter(now) ? last : now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_prazo));
    if (time == null || !mounted) return;
    setState(() {
      _prazoTocado = true;
      _prazo = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _create() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final r = _rules;
      final plan = await ref.read(planRepositoryProvider).createPlan(
            titulo: _tituloController.text.trim(),
            prazoVotacao: _prazo,
            timeOptions: _options,
            convidados: _convidados,
            votosVisiveis: !r.votoAnonimo,
            quorumMinimo: r.quorumMinimo,
            essencialVisivel: r.essencialVisivel,
            autoFechar: r.autoFechar && r.quorumMinimo > 0,
            permitirSugestoes: r.permitirSugestoes,
            votoAnonimo: r.votoAnonimo,
            limitePosso: r.limitePosso,
            lembreteHoras: r.lembreteHoras,
            linkAberto: _linkAberto,
            local: _local,
          );

      // Pessoas novas entram nas conexões.
      if (_convidados.any((c) => c.existingContactId == null)) {
        ref.read(connectionsRepositoryProvider).saveContacts(_convidados).catchError((_) {});
      }
      ref.invalidate(myContactsProvider);
      ref.invalidate(myPlansProvider);

      if (!mounted) return;
      final organizer = ref.read(profileProvider).valueOrNull?.nome;
      final texto = buildInviteMessage(
        plan: plan,
        options: _options,
        organizerName: organizer,
        local: _local?.nome,
      );
      context.pushReplacement('/plan/${plan.id}');

      // Já abre o compartilhar com o link pra galera.
      _shareLink(texto, plan.titulo);
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      final limit = LimitError.from(e);
      if (limit != null) {
        _plus('Limite do plano grátis', limit.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não deu pra criar o rolê. Confere a internet e tenta de novo.')),
        );
      }
    }
  }

  static Future<void> _shareLink(String texto, String assunto) async {
    try {
      await Share.share(texto, subject: assunto);
    } catch (_) {
      // Sem compartilhar no aparelho: o painel do rolê tem o botão Copiar.
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final organizer = ref.watch(profileProvider).valueOrNull?.nome.trim();
    final organizerName =
        (organizer == null || organizer.isEmpty) ? 'Você' : organizer.split(' ').first;
    final isLast = _step == _steps.length - 1;

    Widget page(Widget child) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: child,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: RetroScaffold(
        top: RetroTopBar(
          left: 'NOVO',
          right: 'ROLÊ',
          leading: RetroButton.icon(
            onPressed: _close,
            shape: RetroButtonShape.circle,
            semanticLabel: 'Fechar',
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        panelPadding: EdgeInsets.zero,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: StepProgress(step: _step, total: _steps.length, name: _steps[_step]),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  page(StepOQue(
                    controller: _tituloController,
                    organizerName: organizerName,
                    local: _local,
                    onPickPlace: _pickPlace,
                    onClearPlace: () => setState(() => _local = null),
                  )),
                  page(StepQuando(
                    options: _options,
                    onToggle: _toggleOption,
                    onRemove: _removeOption,
                    maxOptions: ref.watch(subscriptionProvider).limit(PlanFeature.horariosPorRole),
                  )),
                  page(StepQuem(
                    convidados: _convidados,
                    onChanged: _setConvidados,
                    linkAberto: _linkAberto,
                    onLinkAbertoChanged: (v) => setState(() => _linkAberto = v),
                  )),
                  page(StepRevisar(
                    titulo: _tituloController.text.trim(),
                    options: _options,
                    convidados: _convidados,
                    linkAberto: _linkAberto,
                    prazo: _prazo,
                    prazoError: _prazoError,
                    suggestions: _suggestions,
                    onPrazo: (d) => setState(() {
                      _prazoTocado = true;
                      _prazo = d;
                    }),
                    onCustomPrazo: _customPrazo,
                    mode: _mode,
                    onMode: _setMode,
                    plusLiberado: ref.watch(subscriptionProvider).modosAvancados,
                    local: _local,
                    rules: _rules,
                    onRules: _setRules,
                    onEditStep: _goTo,
                  )),
                ],
              ),
            ),

            // ------------------------------------------------ rodapé
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_step == 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _convidados.isEmpty
                            ? (_linkAberto
                                ? 'Pode pular: quem tiver o link entra.'
                                : 'Chame alguém ou deixe o link aberto.')
                            : '${_convidados.length} ${_convidados.length == 1 ? 'pessoa' : 'pessoas'}'
                                '${_linkAberto ? ' + quem entrar pelo link' : ''}',
                        style: EmberText.body(12.5, color: p.textoSecundario),
                      ),
                    ),
                  Row(
                    children: [
                      if (_step > 0) ...[
                        RetroButton(
                          onPressed: _creating ? null : _back,
                          color: p.botaoSecundario,
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          semanticLabel: 'Passo anterior',
                          child: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: RetroButton(
                          onPressed: !_canAdvance ? null : (isLast ? _create : _next),
                          height: 52,
                          color: isLast ? EmberColors.brasa : EmberColors.sol,
                          foregroundColor: isLast ? Colors.white : null,
                          child: _creating
                              ? const RetroButtonSpinner()
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        switch (_step) {
                                          0 => 'Escolher horários',
                                          1 => 'Chamar a galera',
                                          2 => 'Revisar',
                                          _ => 'Criar e mandar o link',
                                        },
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!isLast) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
