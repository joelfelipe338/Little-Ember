import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../connections/domain/contact.dart';
import '../../connections/providers/connections_providers.dart';
import '../domain/invited_person.dart';
import '../domain/time_option.dart';
import '../providers/plan_providers.dart';

class CreatePlanScreen extends ConsumerStatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isCreating = false;

  // Step 0: Título
  final _tituloController = TextEditingController();

  // Step 1: Horários
  final List<TimeOption> _timeOptions = [];

  // Step 2: Convidados
  final List<InvitedPerson> _convidados = [];

  // Step 3: Regras
  bool _votosVisiveis = true;
  bool _essencialVisivel = false;
  int _quorumMinimo = 0;
  bool _autoFechar = false;
  bool _permitirSugestoes = false;
  bool _votoAnonimo = false;
  int _limitePosso = 0;
  int _lembreteHoras = 0;

  // Step 4: Revisão + Prazo
  DateTime _prazoVotacao = DateTime.now().add(const Duration(days: 3));

  static const _totalSteps = 5;

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

  DateTime? get _firstOption => _timeOptions.isEmpty
      ? null
      : _timeOptions.map((o) => o.inicioUtc).reduce((a, b) => a.isBefore(b) ? a : b);

  /// O prazo precisa estar no futuro e antes do primeiro horário.
  String? get _prazoError {
    if (!_prazoVotacao.isAfter(DateTime.now())) return 'O prazo já passou. Escolha outro.';
    final first = _firstOption;
    if (first != null && !_prazoVotacao.isBefore(first)) {
      return 'A votação precisa fechar antes do primeiro horário.';
    }
    return null;
  }

  bool get _canAdvance => switch (_currentStep) {
        0 => _tituloController.text.trim().isNotEmpty,
        1 => _timeOptions.isNotEmpty,
        2 => true,
        3 => true,
        4 => _prazoError == null,
        _ => false,
      };

  /// Ajusta o prazo padrão para fechar antes do primeiro horário (quando dá).
  void _fitPrazo() {
    final first = _firstOption;
    if (first == null || _prazoVotacao.isBefore(first)) return;
    final now = DateTime.now();
    var candidate = first.subtract(const Duration(hours: 2));
    if (!candidate.isAfter(now)) candidate = first.subtract(const Duration(minutes: 30));
    if (candidate.isAfter(now)) _prazoVotacao = candidate;
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        if (_currentStep == _totalSteps - 1) _fitPrazo();
      });
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _addTimeOptions() async {
    final now = DateTime.now();
    bool pickMore = true;

    while (pickMore && mounted) {
      final existingDays = _timeOptions
          .map((o) => DateUtils.dateOnly(o.inicioUtc))
          .toSet();

      var initialDate = DateUtils.dateOnly(now.add(const Duration(days: 1)));
      final lastDate = now.add(const Duration(days: 365));
      while (existingDays.contains(initialDate) &&
          initialDate.isBefore(lastDate)) {
        initialDate = initialDate.add(const Duration(days: 1));
      }

      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: lastDate,
        selectableDayPredicate: (d) =>
            !existingDays.contains(DateUtils.dateOnly(d)),
      );
      if (date == null || !mounted) return;

      final result = await showModalBottomSheet<({List<DateTime> times, bool anotherDay})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DayTimesSheet(date: date, existingOptions: _timeOptions),
      );
      if (result == null || !mounted) return;

      if (result.times.isNotEmpty) {
        setState(() {
          for (final dt in result.times) {
            _timeOptions.add(TimeOption(inicioUtc: dt));
          }
          _timeOptions.sort((a, b) => a.inicioUtc.compareTo(b.inicioUtc));
        });
      }

      pickMore = result.anotherDay;
    }
  }

  Future<void> _addTimeToDay(DateTime day) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(day.year, day.month, day.day, time.hour, time.minute);

    if (!dt.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse horário já passou.')),
        );
      }
      return;
    }

    if (_timeOptions.any((o) => o.inicioUtc == dt)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse horário já está na lista.')),
        );
      }
      return;
    }

    setState(() {
      _timeOptions.add(TimeOption(inicioUtc: dt));
      _timeOptions.sort((a, b) => a.inicioUtc.compareTo(b.inicioUtc));
    });
  }

  void _removeDay(DateTime day) {
    setState(() {
      _timeOptions.removeWhere(
        (o) => DateUtils.dateOnly(o.inicioUtc) == day,
      );
    });
  }

  Future<void> _pickPrazo() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _prazoVotacao,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_prazoVotacao),
    );
    if (time == null || !mounted) return;

    setState(() {
      _prazoVotacao = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createPlan() async {
    setState(() => _isCreating = true);
    try {
      final plan = await ref.read(planRepositoryProvider).createPlan(
            titulo: _tituloController.text.trim(),
            prazoVotacao: _prazoVotacao,
            timeOptions: _timeOptions,
            convidados: _convidados,
            votosVisiveis: _votosVisiveis,
            quorumMinimo: _quorumMinimo,
            essencialVisivel: _essencialVisivel,
            autoFechar: _autoFechar,
            permitirSugestoes: _permitirSugestoes,
            votoAnonimo: _votoAnonimo,
            limitePosso: _limitePosso,
            lembreteHoras: _lembreteHoras,
          );

      if (_convidados.isNotEmpty) {
        ref
            .read(connectionsRepositoryProvider)
            .saveContacts(_convidados)
            .catchError((_) {});
        ref.invalidate(myContactsProvider);
      }

      ref.invalidate(myPlansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rolê criado! Agora manda o link pra galera.')),
        );
        context.pushReplacement('/plan/${plan.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar rolê: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);

    return RetroScaffold(
      top: RetroTopBar(
        left: 'NOVO',
        right: 'ROLÊ',
        emblem: const Icon(Icons.local_fire_department_rounded, size: 24),
        leading: RetroButton.icon(
          onPressed: _prevStep,
          semanticLabel: _currentStep == 0 ? 'Voltar' : 'Passo anterior',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      panelPadding: EdgeInsets.zero,
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: List.generate(_totalSteps, (i) {
                final isActive = i <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isActive ? EmberColors.sol : tokens.border.withAlpha(60),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: tokens.border, width: 1.5),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepTitulo(controller: _tituloController),
                _StepHorarios(
                  timeOptions: _timeOptions,
                  onAddDay: _addTimeOptions,
                  onAddTimeToDay: _addTimeToDay,
                  onRemove: (i) => setState(() => _timeOptions.removeAt(i)),
                  onRemoveDay: _removeDay,
                ),
                _StepConvidados(
                  convidados: _convidados,
                  onAdd: (p) => setState(() => _convidados.add(p)),
                  onRemove: (i) => setState(() => _convidados.removeAt(i)),
                  onToggleEssencial: (i) => setState(() {
                    _convidados[i] = _convidados[i].copyWith(
                      essencial: !_convidados[i].essencial,
                    );
                  }),
                ),
                _StepRegras(
                  votosVisiveis: _votosVisiveis,
                  essencialVisivel: _essencialVisivel,
                  quorumMinimo: _quorumMinimo,
                  hasEssenciais: _convidados.any((c) => c.essencial),
                  autoFechar: _autoFechar,
                  permitirSugestoes: _permitirSugestoes,
                  votoAnonimo: _votoAnonimo,
                  limitePosso: _limitePosso,
                  lembreteHoras: _lembreteHoras,
                  onVotosVisiveisChanged: (v) =>
                      setState(() => _votosVisiveis = v),
                  onEssencialVisivelChanged: (v) =>
                      setState(() => _essencialVisivel = v),
                  onQuorumChanged: (v) =>
                      setState(() => _quorumMinimo = v),
                  onAutoFecharChanged: (v) =>
                      setState(() => _autoFechar = v),
                  onPermitirSugestoesChanged: (v) =>
                      setState(() => _permitirSugestoes = v),
                  onVotoAnonimoChanged: (v) =>
                      setState(() => _votoAnonimo = v),
                  onLimitePossoChanged: (v) =>
                      setState(() => _limitePosso = v),
                  onLembreteHorasChanged: (v) =>
                      setState(() => _lembreteHoras = v),
                ),
                _StepRevisao(
                  titulo: _tituloController.text,
                  timeOptions: _timeOptions,
                  prazoVotacao: _prazoVotacao,
                  prazoError: _prazoError,
                  onPickPrazo: _pickPrazo,
                  convidados: _convidados,
                  votosVisiveis: _votosVisiveis,
                  quorumMinimo: _quorumMinimo,
                ),
              ],
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _currentStep < _totalSteps - 1
                ? EmberButton(
                    label: 'Próximo',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _canAdvance ? _nextStep : null,
                    expand: true,
                  )
                : EmberButton(
                    label: 'Criar Rolê',
                    icon: Icons.check_rounded,
                    onPressed: _canAdvance ? _createPlan : null,
                    isLoading: _isCreating,
                    expand: true,
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 1: Título
// ---------------------------------------------------------------------------

class _StepTitulo extends StatelessWidget {
  const _StepTitulo({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: RetroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NOME DO ROLÊ', style: EmberText.mono(10, color: tokens.textSecondary)),
            const SizedBox(height: 10),
            Text(
              'Dê um nome que a galera reconheça de cara.',
              style: EmberText.body(14, color: tokens.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              style: EmberText.body(16, color: tokens.textPrimary),
              decoration: const InputDecoration(hintText: 'Ex: Churras de sábado'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 2: Horários
// ---------------------------------------------------------------------------

class _StepHorarios extends StatelessWidget {
  const _StepHorarios({
    required this.timeOptions,
    required this.onAddDay,
    required this.onAddTimeToDay,
    required this.onRemove,
    required this.onRemoveDay,
  });

  final List<TimeOption> timeOptions;
  final VoidCallback onAddDay;
  final ValueChanged<DateTime> onAddTimeToDay;
  final ValueChanged<int> onRemove;
  final ValueChanged<DateTime> onRemoveDay;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);
    final p = RetroPalette.of(context);
    final dateFormat = DateFormat("EEEE, d 'de' MMM", 'pt_BR');
    final timeFormat = DateFormat('HH:mm', 'pt_BR');

    final grouped = <DateTime, List<({TimeOption opt, int index})>>{};
    for (var i = 0; i < timeOptions.length; i++) {
      final day = DateUtils.dateOnly(timeOptions[i].inicioUtc);
      grouped.putIfAbsent(day, () => []).add((opt: timeOptions[i], index: i));
    }
    final sortedDays = grouped.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OPÇÕES DE HORÁRIO',
                    style: EmberText.mono(10, color: tokens.textSecondary)),
                const SizedBox(height: 10),
                Text(
                  'Adicione dias e horários para a galera votar.',
                  style: EmberText.body(14, color: tokens.textSecondary),
                ),
              ],
            ),
          ),

          if (sortedDays.isNotEmpty) const SizedBox(height: 14),

          for (final day in sortedDays) ...[
            RetroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: EmberColors.sol),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dateFormat.format(day),
                          style: EmberText.body(15, weight: FontWeight.w700),
                        ),
                      ),
                      RetroButton.icon(
                        onPressed: () => onAddTimeToDay(day),
                        semanticLabel: 'Adicionar horário',
                        icon: const Icon(Icons.add_rounded, size: 16),
                      ),
                      const SizedBox(width: 6),
                      RetroButton.icon(
                        onPressed: () => onRemoveDay(day),
                        semanticLabel: 'Remover dia',
                        color: EmberColors.brasa.withAlpha(30),
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 16, color: EmberColors.brasaTexto),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final entry in grouped[day]!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const SizedBox(width: 28),
                          Icon(Icons.schedule_rounded,
                              size: 16, color: p.textoSecundario),
                          const SizedBox(width: 8),
                          Text(
                            timeFormat.format(entry.opt.inicioUtc),
                            style: EmberText.body(15, weight: FontWeight.w600),
                          ),
                          const Spacer(),
                          RetroButton.icon(
                            onPressed: () => onRemove(entry.index),
                            semanticLabel: 'Remover horário',
                            color: EmberColors.brasa.withAlpha(30),
                            icon: Icon(Icons.close_rounded,
                                size: 14, color: EmberColors.brasaTexto),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (sortedDays.isNotEmpty) const SizedBox(height: 4),

          RetroButton(
            onPressed: onAddDay,
            color: EmberColors.sol,
            expand: true,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18),
                SizedBox(width: 6),
                Text('Adicionar dia'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 3: Prazo + Revisão
// ---------------------------------------------------------------------------

class _StepRevisao extends StatelessWidget {
  const _StepRevisao({
    required this.titulo,
    required this.timeOptions,
    required this.prazoVotacao,
    required this.prazoError,
    required this.onPickPrazo,
    required this.convidados,
    required this.votosVisiveis,
    required this.quorumMinimo,
  });

  final String titulo;
  final List<TimeOption> timeOptions;
  final DateTime prazoVotacao;
  final String? prazoError;
  final VoidCallback onPickPrazo;
  final List<InvitedPerson> convidados;
  final bool votosVisiveis;
  final int quorumMinimo;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);
    final dateFormat = DateFormat("EEE, d 'de' MMM – HH:mm", 'pt_BR');
    final prazoFormat = DateFormat("d 'de' MMM, HH:mm", 'pt_BR');
    final essenciais = convidados.where((c) => c.essencial).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRAZO DE VOTAÇÃO', style: EmberText.mono(10, color: tokens.textSecondary)),
                const SizedBox(height: 10),
                Text(
                  'Até quando a galera pode votar?',
                  style: EmberText.body(14, color: tokens.textSecondary),
                ),
                const SizedBox(height: 14),
                RetroButton(
                  onPressed: onPickPrazo,
                  color: tokens.cardBg,
                  expand: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_rounded, size: 18, color: tokens.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        prazoFormat.format(prazoVotacao),
                        style: EmberText.body(15, color: tokens.textPrimary, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (prazoError != null) ...[
                  const SizedBox(height: 12),
                  RetroErrorBox(prazoError!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          RetroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RESUMO', style: EmberText.mono(10, color: tokens.textSecondary)),
                const SizedBox(height: 14),
                _resumeRow(Icons.local_fire_department_rounded, 'Rolê', titulo, tokens),
                const SizedBox(height: 10),
                _resumeRow(Icons.how_to_vote_rounded, 'Opções',
                    '${timeOptions.length} horário${timeOptions.length != 1 ? 's' : ''}', tokens),
                const SizedBox(height: 10),
                _resumeRow(Icons.timer_rounded, 'Prazo', prazoFormat.format(prazoVotacao), tokens),
                if (convidados.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _resumeRow(Icons.people_alt_rounded, 'Convidados',
                      '${convidados.length} pessoa${convidados.length != 1 ? 's' : ''}', tokens),
                ],
                if (essenciais > 0) ...[
                  const SizedBox(height: 10),
                  _resumeRow(Icons.local_fire_department_rounded, 'Essenciais',
                      '$essenciais', tokens),
                ],
                const SizedBox(height: 10),
                _resumeRow(Icons.visibility_rounded, 'Votos',
                    votosVisiveis ? 'Visíveis' : 'Ocultos', tokens),
                if (quorumMinimo > 0) ...[
                  const SizedBox(height: 10),
                  _resumeRow(Icons.group_rounded, 'Quórum',
                      '$quorumMinimo pessoa${quorumMinimo != 1 ? 's' : ''}', tokens),
                ],
                if (timeOptions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(color: tokens.divider, height: 2),
                  const SizedBox(height: 14),
                  ...timeOptions.map((opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 16, color: tokens.textSecondary),
                            const SizedBox(width: 8),
                            Text(dateFormat.format(opt.inicioUtc),
                                style: EmberText.body(14, color: tokens.textPrimary)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeRow(IconData icon, String label, String value, RetroTokens tokens) {
    return Row(
      children: [
        Icon(icon, size: 18, color: EmberColors.sol),
        const SizedBox(width: 8),
        Text('$label: ', style: EmberText.body(14, color: tokens.textSecondary)),
        Expanded(
          child: Text(value,
              style: EmberText.body(14, color: tokens.textPrimary, weight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 3: Convidados
// ---------------------------------------------------------------------------

class _StepConvidados extends ConsumerWidget {
  const _StepConvidados({
    required this.convidados,
    required this.onAdd,
    required this.onRemove,
    required this.onToggleEssencial,
  });

  final List<InvitedPerson> convidados;
  final ValueChanged<InvitedPerson> onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onToggleEssencial;

  static const _tipoLabels = {
    ConnectionType.amigos: 'Amigo',
    ConnectionType.casal: 'Casal',
    ConnectionType.familia: 'Família',
    ConnectionType.trabalho: 'Trabalho',
    ConnectionType.outro: 'Outro',
  };

  static const _tipoCores = {
    ConnectionType.amigos: EmberColors.lavanda,
    ConnectionType.casal: EmberColors.brasa,
    ConnectionType.familia: EmberColors.menta,
    ConnectionType.trabalho: EmberColors.sol,
    ConnectionType.outro: EmberColors.neblina,
  };

  Future<void> _showAddSheet(BuildContext context) async {
    final result = await showModalBottomSheet<InvitedPerson>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddPersonSheet(),
    );
    if (result != null) onAdd(result);
  }

  Future<void> _showContactsSheet(BuildContext context, List<Contact> contacts) async {
    final existing = convidados.map((c) => c.nome.toLowerCase()).toSet();
    final available = contacts.where((c) => !existing.contains(c.nome.toLowerCase())).toList();
    if (available.isEmpty) return;

    final picked = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickContactSheet(contacts: available),
    );
    if (picked != null) {
      onAdd(InvitedPerson(
        nome: picked.nome,
        tipo: picked.tipo,
        existingContactId: picked.id,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = RetroTokens.of(context);
    final p = RetroPalette.of(context);
    final contactsAsync = ref.watch(myContactsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONVIDADOS', style: EmberText.mono(10, color: tokens.textSecondary)),
                const SizedBox(height: 10),
                Text(
                  'Adicione quem vai participar. Você pode marcar quem é essencial.',
                  style: EmberText.body(14, color: tokens.textSecondary),
                ),
                const SizedBox(height: 14),

                if (convidados.isNotEmpty) ...[
                  ...List.generate(convidados.length, (i) {
                    final person = convidados[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RetroCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.nome,
                                    style: EmberText.body(15, weight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  RetroTag(
                                    _tipoLabels[person.tipo] ?? 'Outro',
                                    color: _tipoCores[person.tipo] ?? EmberColors.neblina,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => onToggleEssencial(i),
                              tooltip: person.essencial ? 'Remover essencial' : 'Marcar essencial',
                              icon: Icon(
                                Icons.local_fire_department_rounded,
                                color: person.essencial
                                    ? EmberColors.brasa
                                    : p.textoSecundario.withAlpha(100),
                                size: 22,
                              ),
                            ),
                            RetroButton.icon(
                              onPressed: () => onRemove(i),
                              semanticLabel: 'Remover',
                              color: EmberColors.brasa.withAlpha(30),
                              icon: Icon(Icons.close_rounded, size: 16, color: EmberColors.brasaTexto),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                RetroButton(
                  onPressed: () => _showAddSheet(context),
                  color: EmberColors.sol,
                  expand: true,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Adicionar pessoa'),
                    ],
                  ),
                ),

                contactsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (contacts) {
                    if (contacts.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: RetroButton(
                        onPressed: () => _showContactsSheet(context, contacts),
                        color: p.superficie,
                        expand: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.contacts_rounded, size: 18, color: p.texto),
                            const SizedBox(width: 6),
                            Text('Buscar nos contatos', style: TextStyle(color: p.texto)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(
            'Pule se preferir que qualquer pessoa entre pelo link.',
            style: EmberText.body(13, color: tokens.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 4: Regras
// ---------------------------------------------------------------------------

class _StepRegras extends StatelessWidget {
  const _StepRegras({
    required this.votosVisiveis,
    required this.essencialVisivel,
    required this.quorumMinimo,
    required this.hasEssenciais,
    required this.autoFechar,
    required this.permitirSugestoes,
    required this.votoAnonimo,
    required this.limitePosso,
    required this.lembreteHoras,
    required this.onVotosVisiveisChanged,
    required this.onEssencialVisivelChanged,
    required this.onQuorumChanged,
    required this.onAutoFecharChanged,
    required this.onPermitirSugestoesChanged,
    required this.onVotoAnonimoChanged,
    required this.onLimitePossoChanged,
    required this.onLembreteHorasChanged,
  });

  final bool votosVisiveis;
  final bool essencialVisivel;
  final int quorumMinimo;
  final bool hasEssenciais;
  final bool autoFechar;
  final bool permitirSugestoes;
  final bool votoAnonimo;
  final int limitePosso;
  final int lembreteHoras;
  final ValueChanged<bool> onVotosVisiveisChanged;
  final ValueChanged<bool> onEssencialVisivelChanged;
  final ValueChanged<int> onQuorumChanged;
  final ValueChanged<bool> onAutoFecharChanged;
  final ValueChanged<bool> onPermitirSugestoesChanged;
  final ValueChanged<bool> onVotoAnonimoChanged;
  final ValueChanged<int> onLimitePossoChanged;
  final ValueChanged<int> onLembreteHorasChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REGRAS DO ROLÊ', style: EmberText.mono(10, color: tokens.textSecondary)),
                const SizedBox(height: 10),
                Text(
                  'Configure como a votação vai funcionar.',
                  style: EmberText.body(14, color: tokens.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Votos visíveis
          _RuleCard(
            icon: Icons.visibility_rounded,
            title: 'Votos visíveis',
            description: 'A galera pode ver os votos dos outros?',
            trailing: _RetroToggle(
              value: votosVisiveis,
              onChanged: onVotosVisiveisChanged,
            ),
          ),

          const SizedBox(height: 10),

          // Essencial visível
          if (hasEssenciais) ...[
            _RuleCard(
              icon: Icons.local_fire_department_rounded,
              title: 'Mostrar essenciais',
              description: 'Convidados veem quem é essencial?',
              trailing: _RetroToggle(
                value: essencialVisivel,
                onChanged: onEssencialVisivelChanged,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Quórum
          _RuleCard(
            icon: Icons.group_rounded,
            title: 'Quórum mínimo',
            description: 'Mínimo de votos pra fechar',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RetroButton.icon(
                  onPressed: quorumMinimo > 0
                      ? () => onQuorumChanged(quorumMinimo - 1)
                      : null,
                  semanticLabel: 'Diminuir',
                  icon: const Icon(Icons.remove_rounded, size: 16),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    quorumMinimo == 0 ? 'Sem' : '$quorumMinimo',
                    style: EmberText.display(18),
                  ),
                ),
                RetroButton.icon(
                  onPressed: () => onQuorumChanged(quorumMinimo + 1),
                  semanticLabel: 'Aumentar',
                  icon: const Icon(Icons.add_rounded, size: 16),
                ),
              ],
            ),
          ),

          // Auto-fechar (só aparece se quórum > 0)
          if (quorumMinimo > 0) ...[
            const SizedBox(height: 10),
            _RuleCard(
              icon: Icons.lock_clock_rounded,
              title: 'Auto-fechar',
              description: 'Fechar votação quando o quórum bater',
              trailing: _RetroToggle(
                value: autoFechar,
                onChanged: onAutoFecharChanged,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Permitir sugestões
          _RuleCard(
            icon: Icons.add_comment_rounded,
            title: 'Sugestões de horário',
            description: 'Convidados podem sugerir horários',
            trailing: _RetroToggle(
              value: permitirSugestoes,
              onChanged: onPermitirSugestoesChanged,
            ),
          ),

          const SizedBox(height: 10),

          // Voto anônimo
          _RuleCard(
            icon: Icons.visibility_off_rounded,
            title: 'Voto anônimo',
            description: 'Ninguém vê quem votou o quê',
            trailing: _RetroToggle(
              value: votoAnonimo,
              onChanged: onVotoAnonimoChanged,
            ),
          ),

          const SizedBox(height: 10),

          // Limite de Posso
          _RuleCard(
            icon: Icons.confirmation_number_rounded,
            title: 'Limite de "Posso"',
            description: 'Máximo de vezes que pode votar "Posso"',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RetroButton.icon(
                  onPressed: limitePosso > 0
                      ? () => onLimitePossoChanged(limitePosso - 1)
                      : null,
                  semanticLabel: 'Diminuir',
                  icon: const Icon(Icons.remove_rounded, size: 16),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    limitePosso == 0 ? 'Sem' : '$limitePosso',
                    style: EmberText.display(18),
                  ),
                ),
                RetroButton.icon(
                  onPressed: () => onLimitePossoChanged(limitePosso + 1),
                  semanticLabel: 'Aumentar',
                  icon: const Icon(Icons.add_rounded, size: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Lembrete
          _RuleCard(
            icon: Icons.notifications_active_rounded,
            title: 'Lembrete',
            description: 'Avisar quem não votou antes do prazo',
            trailing: _LembreteSelector(
              value: lembreteHoras,
              onChanged: onLembreteHorasChanged,
            ),
          ),

        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return RetroCard(
      child: Row(
        children: [
          Icon(icon, size: 20, color: p.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: EmberText.body(14, weight: FontWeight.w600)),
                Text(description, style: EmberText.body(12, color: p.textoSecundario)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _RetroToggle extends StatelessWidget {
  const _RetroToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? EmberColors.menta : p.superficie,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.contorno, width: 2.5),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? EmberColors.tinta : p.textoSecundario,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _LembreteSelector extends StatelessWidget {
  const _LembreteSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _opcoes = [0, 2, 6, 12, 24];

  String get _label {
    if (value == 0) return 'Não';
    return '${value}h';
  }

  @override
  Widget build(BuildContext context) {
    final idx = _opcoes.indexOf(value).clamp(0, _opcoes.length - 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RetroButton.icon(
          onPressed: idx > 0 ? () => onChanged(_opcoes[idx - 1]) : null,
          semanticLabel: 'Diminuir',
          icon: const Icon(Icons.remove_rounded, size: 16),
        ),
        Container(
          width: 44,
          alignment: Alignment.center,
          child: Text(_label, style: EmberText.display(16)),
        ),
        RetroButton.icon(
          onPressed: idx < _opcoes.length - 1
              ? () => onChanged(_opcoes[idx + 1])
              : null,
          semanticLabel: 'Aumentar',
          icon: const Icon(Icons.add_rounded, size: 16),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: adicionar pessoa
// ---------------------------------------------------------------------------

class _AddPersonSheet extends StatefulWidget {
  const _AddPersonSheet();

  @override
  State<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<_AddPersonSheet> {
  final _nomeController = TextEditingController();
  ConnectionType _tipo = ConnectionType.amigos;
  bool _essencial = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _submit() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;
    Navigator.pop(
      context,
      InvitedPerson(nome: nome, essencial: _essencial, tipo: _tipo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: p.tela,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: p.contorno, width: 3),
          left: BorderSide(color: p.contorno, width: 3),
          right: BorderSide(color: p.contorno, width: 3),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: p.textoSecundario.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text('Adicionar pessoa', style: EmberText.display(20)),
            const SizedBox(height: 16),

            const RetroFieldLabel('Nome'),
            TextField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Ex: Maria'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),

            const RetroFieldLabel('Relação'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ConnectionType.values.map((t) {
                final isActive = _tipo == t;
                final label = _StepConvidados._tipoLabels[t] ?? t.name;
                return RetroButton(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onPressed: () => setState(() => _tipo = t),
                  color: isActive ? EmberColors.sol : p.superficie,
                  foregroundColor: isActive ? EmberColors.tinta : p.texto,
                  child: Text(label, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: () => setState(() => _essencial = !_essencial),
              child: RetroCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: _essencial ? EmberColors.brasa : p.textoSecundario,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pessoa essencial',
                        style: EmberText.body(14, weight: FontWeight.w600),
                      ),
                    ),
                    _RetroToggle(
                      value: _essencial,
                      onChanged: (v) => setState(() => _essencial = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            RetroButton(
              onPressed: _nomeController.text.trim().isNotEmpty ? _submit : null,
              color: EmberColors.sol,
              expand: true,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Adicionar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: escolher contato salvo
// ---------------------------------------------------------------------------

class _PickContactSheet extends StatelessWidget {
  const _PickContactSheet({required this.contacts});
  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: p.tela,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: p.contorno, width: 3),
          left: BorderSide(color: p.contorno, width: 3),
          right: BorderSide(color: p.contorno, width: 3),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: p.textoSecundario.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Seus contatos', style: EmberText.display(20)),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: contacts.length,
              itemBuilder: (_, i) {
                final c = contacts[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RetroCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, c),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(c.nome, style: EmberText.body(15, weight: FontWeight.w600)),
                          ),
                          RetroTag(
                            _StepConvidados._tipoLabels[c.tipo] ?? 'Outro',
                            color: _StepConvidados._tipoCores[c.tipo] ?? EmberColors.neblina,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: horários de um dia
// ---------------------------------------------------------------------------

class _DayTimesSheet extends StatefulWidget {
  const _DayTimesSheet({required this.date, required this.existingOptions});
  final DateTime date;
  final List<TimeOption> existingOptions;

  @override
  State<_DayTimesSheet> createState() => _DayTimesSheetState();
}

class _DayTimesSheetState extends State<_DayTimesSheet> {
  final List<DateTime> _times = [];

  Future<void> _addTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(
      widget.date.year, widget.date.month, widget.date.day,
      time.hour, time.minute,
    );

    if (!dt.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse horário já passou.')),
        );
      }
      return;
    }

    final allExisting = [
      ...widget.existingOptions.map((o) => o.inicioUtc),
      ..._times,
    ];
    if (allExisting.contains(dt)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse horário já está na lista.')),
        );
      }
      return;
    }

    setState(() {
      _times.add(dt);
      _times.sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final dateLabel = DateFormat("EEEE, d 'de' MMM", 'pt_BR').format(widget.date);
    final timeFmt = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: p.tela,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: p.contorno, width: 3),
          left: BorderSide(color: p.contorno, width: 3),
          right: BorderSide(color: p.contorno, width: 3),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: p.textoSecundario.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: EmberColors.sol),
                const SizedBox(width: 10),
                Expanded(child: Text(dateLabel, style: EmberText.display(20))),
              ],
            ),
            const SizedBox(height: 16),

            if (_times.isNotEmpty) ...[
              for (var i = 0; i < _times.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RetroCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 18, color: p.textoSecundario),
                        const SizedBox(width: 10),
                        Text(timeFmt.format(_times[i]),
                            style: EmberText.body(16, weight: FontWeight.w700)),
                        const Spacer(),
                        RetroButton.icon(
                          onPressed: () => setState(() => _times.removeAt(i)),
                          semanticLabel: 'Remover',
                          color: EmberColors.brasa.withAlpha(30),
                          icon: Icon(Icons.close_rounded, size: 16, color: EmberColors.brasaTexto),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
            ],

            RetroButton(
              onPressed: _addTime,
              color: EmberColors.sol,
              expand: true,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Adicionar horário'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: RetroButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (times: _times, anotherDay: true),
                    ),
                    color: p.superficie,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Outro dia'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RetroButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (times: _times, anotherDay: false),
                    ),
                    color: EmberColors.sol,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Concluir'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
