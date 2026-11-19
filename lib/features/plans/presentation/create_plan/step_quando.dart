import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/ember_retro_theme.dart';
import '../../../connections/presentation/widgets/connection_ui.dart';
import '../../domain/time_option.dart';
import 'create_plan_widgets.dart';

/// Passo 2: faixa de dias + horários prontos. Cada toque liga/desliga uma opção.
class StepQuando extends StatefulWidget {
  const StepQuando({
    super.key,
    required this.options,
    required this.onToggle,
    required this.onRemove,
    this.maxOptions = 5,
  });

  final List<TimeOption> options;

  /// Adiciona o horário se não existir; remove se já existir.
  final ValueChanged<DateTime> onToggle;
  final ValueChanged<DateTime> onRemove;

  /// Máximo de horários do plano (grátis: 5).
  final int maxOptions;

  @override
  State<StepQuando> createState() => _StepQuandoState();
}

class _StepQuandoState extends State<StepQuando> {
  static const _diasNaFaixa = 60;
  static const _larguraDia = 58.0;
  static const _horasProntas = [(12, 0), (15, 0), (19, 0), (20, 30)];

  final _scroll = ScrollController();
  late final DateTime _hoje = DateUtils.dateOnly(DateTime.now());
  late DateTime _dia;

  /// Mês mostrado no título: acompanha a faixa de dias enquanto ela rola.
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    // Começa no dia da primeira opção, ou amanhã.
    _dia = widget.options.isEmpty
        ? _hoje.add(const Duration(days: 1))
        : DateUtils.dateOnly(widget.options.first.inicioUtc);
    _mes = DateTime(_dia.year, _dia.month);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_dia, animate: false));
  }

  /// Atualiza o mês pelo primeiro dia que aparece na faixa.
  void _onScroll() {
    final index = ((_scroll.offset + _larguraDia / 2) / (_larguraDia + 6)).floor().clamp(0, _diasNaFaixa - 1);
    final day = _hoje.add(Duration(days: index));
    final mes = DateTime(day.year, day.month);
    if (mes != _mes) setState(() => _mes = mes);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _scrollTo(DateTime day, {bool animate = true}) {
    if (!_scroll.hasClients) return;
    final index = day.difference(_hoje).inDays;
    final target = (index * (_larguraDia + 6) - 60).clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
  }

  Future<void> _pickFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dia,
      firstDate: _hoje,
      lastDate: _hoje.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dia = DateUtils.dateOnly(picked);
      _mes = DateTime(_dia.year, _dia.month);
    });
    if (picked.difference(_hoje).inDays < _diasNaFaixa) _scrollTo(_dia);
  }

  Future<void> _pickOtherTime() async {
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 19, minute: 0));
    if (time == null || !mounted) return;
    final dt = DateTime(_dia.year, _dia.month, _dia.day, time.hour, time.minute);
    if (!dt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esse horário já passou.')));
      return;
    }
    if (widget.options.any((o) => o.inicioUtc == dt)) return;
    widget.onToggle(dt);
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final now = DateTime.now();
    final optionsOfDay = [
      for (final o in widget.options)
        if (DateUtils.isSameDay(o.inicioUtc, _dia)) o.inicioUtc,
    ];
    final prontas = [
      for (final (h, m) in _horasProntas) DateTime(_dia.year, _dia.month, _dia.day, h, m),
    ];
    // Horários escolhidos pelo "Outro" também aparecem como chip do dia.
    final extras = [for (final t in optionsOfDay) if (!prontas.contains(t)) t];
    final chips = [...prontas, ...extras]..sort();
    final n = widget.options.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepQuestion('Quando pode ser?'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                capitalize(DateFormat('MMMM y', 'pt_BR').format(_mes)),
                style: EmberText.body(15, weight: FontWeight.w800),
              ),
            ),
            MonoLink('Ver mês', icon: Icons.calendar_month_rounded, onTap: _pickFromCalendar),
          ],
        ),
        const SizedBox(height: 6),

        // ------------------------------------------------ faixa de dias
        SizedBox(
          height: 84,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: _diasNaFaixa,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final day = _hoje.add(Duration(days: i));
              final count = widget.options.where((o) => DateUtils.isSameDay(o.inicioUtc, day)).length;
              return _DayBox(
                day: day,
                count: count,
                selected: DateUtils.isSameDay(day, _dia),
                width: _larguraDia,
                onTap: () => setState(() => _dia = day),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ------------------------------------------------ horários do dia
        RetroCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capitalize(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_dia)),
                style: EmberText.body(15, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in chips)
                    if (t.isAfter(now) || optionsOfDay.contains(t))
                      RetroChoiceChip(
                        label: DateFormat('HH:mm').format(t),
                        icon: optionsOfDay.contains(t) ? Icons.check_rounded : null,
                        color: EmberColors.menta,
                        selected: optionsOfDay.contains(t),
                        onTap: () => widget.onToggle(t),
                      ),
                  RetroChoiceChip(
                    label: 'Outro',
                    icon: Icons.schedule_rounded,
                    selected: false,
                    onTap: _pickOtherTime,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------ opções escolhidas
        Row(
          children: [
            Expanded(child: SectionLabel('Suas opções · $n de ${widget.maxOptions}')),
            Text(
              switch (n) {
                0 => 'ESCOLHA PELO MENOS 1',
                1 => 'DICA: 2 A 5 É O IDEAL',
                <= 5 => 'BOA! IDEAL É 2 A 5',
                _ => 'MUITAS OPÇÕES CONFUNDEM',
              },
              style: EmberText.mono(9.5, color: n >= 2 && n <= 5 ? EmberColors.menta : p.textoSecundario),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (n == 0)
          Text(
            'Escolha um dia na faixa e toque nos horários.',
            style: EmberText.body(13, color: p.textoSecundario),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in widget.options)
                _OptionChip(
                  when: o.inicioUtc,
                  onTap: () {
                    setState(() => _dia = DateUtils.dateOnly(o.inicioUtc));
                    _scrollTo(_dia);
                  },
                  onRemove: () => widget.onRemove(o.inicioUtc),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayBox extends StatelessWidget {
  const _DayBox({
    required this.day,
    required this.count,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final DateTime day;
  final int count;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final weekday = DateFormat('EEE', 'pt_BR').format(day).replaceAll('.', '').toUpperCase();
    final fg = selected ? p.noInvertido : p.texto;
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(day) +
          (count > 0 ? ', $count ${count == 1 ? 'horário' : 'horários'}' : ''),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: width,
          decoration: BoxDecoration(
            color: selected ? p.invertido : p.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.contorno, width: 2.5),
            boxShadow: selected ? null : [BoxShadow(color: p.contorno, offset: const Offset(0, 3))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(weekday, style: EmberText.mono(9.5, color: selected ? EmberColors.sol : p.textoSecundario)),
              Text('${day.day}', style: EmberText.display(22, color: fg)),
              SizedBox(
                height: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < count.clamp(0, 3); i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: EmberColors.brasa,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.contorno, width: 1),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.when, required this.onTap, required this.onRemove});

  final DateTime when;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final dia = DateFormat("EEE d", 'pt_BR').format(when).replaceAll('.', '');
    final hora = DateFormat('HH:mm').format(when);
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: EmberColors.sol,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.contorno, width: 2.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: capitalize(dia),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' · $hora'),
                ],
              ),
              style: EmberText.body(13, color: EmberColors.tinta, weight: FontWeight.w600),
            ),
          ),
          Semantics(
            button: true,
            label: 'Remover $dia às $hora',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(6, 8, 10, 8),
                child: Icon(Icons.close_rounded, size: 16, color: EmberColors.tinta),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
