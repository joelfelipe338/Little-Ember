import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
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

  // Step 1
  final _tituloController = TextEditingController();

  // Step 2
  final List<TimeOption> _timeOptions = [];

  // Step 3
  DateTime _prazoVotacao = DateTime.now().add(const Duration(days: 3));

  static const _totalSteps = 3;

  @override
  void dispose() {
    _pageController.dispose();
    _tituloController.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_currentStep) {
        0 => _tituloController.text.trim().isNotEmpty,
        1 => _timeOptions.isNotEmpty,
        2 => true,
        _ => false,
      };

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
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

  Future<void> _addTimeOption() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _timeOptions.add(TimeOption(
        inicioUtc: DateTime(date.year, date.month, date.day, time.hour, time.minute),
      ));
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
      await ref.read(planRepositoryProvider).createPlan(
            titulo: _tituloController.text.trim(),
            prazoVotacao: _prazoVotacao,
            timeOptions: _timeOptions,
          );
      ref.invalidate(myPlansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rolê criado com sucesso!')),
        );
        context.pop();
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
                  onAdd: _addTimeOption,
                  onRemove: (i) => setState(() => _timeOptions.removeAt(i)),
                ),
                _StepRevisao(
                  titulo: _tituloController.text,
                  timeOptions: _timeOptions,
                  prazoVotacao: _prazoVotacao,
                  onPickPrazo: _pickPrazo,
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
    required this.onAdd,
    required this.onRemove,
  });

  final List<TimeOption> timeOptions;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);
    final dateFormat = DateFormat("EEE, d 'de' MMM", 'pt_BR');
    final timeFormat = DateFormat('HH:mm', 'pt_BR');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OPÇÕES DE HORÁRIO', style: EmberText.mono(10, color: tokens.textSecondary)),
                const SizedBox(height: 10),
                Text(
                  'Adicione datas e horários para a galera votar.',
                  style: EmberText.body(14, color: tokens.textSecondary),
                ),
                const SizedBox(height: 14),
                if (timeOptions.isNotEmpty) ...[
                  ...List.generate(timeOptions.length, (i) {
                    final opt = timeOptions[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RetroCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: tokens.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFormat.format(opt.inicioUtc),
                                    style: EmberText.body(15, color: tokens.textPrimary, weight: FontWeight.w600),
                                  ),
                                  Text(
                                    timeFormat.format(opt.inicioUtc),
                                    style: EmberText.body(13, color: tokens.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            RetroButton.icon(
                              onPressed: () => onRemove(i),
                              semanticLabel: 'Remover opção',
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
                  onPressed: onAdd,
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
    required this.onPickPrazo,
  });

  final String titulo;
  final List<TimeOption> timeOptions;
  final DateTime prazoVotacao;
  final VoidCallback onPickPrazo;

  @override
  Widget build(BuildContext context) {
    final tokens = RetroTokens.of(context);
    final dateFormat = DateFormat("EEE, d 'de' MMM – HH:mm", 'pt_BR');
    final prazoFormat = DateFormat("d 'de' MMM, HH:mm", 'pt_BR');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prazo de votação
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Resumo
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
