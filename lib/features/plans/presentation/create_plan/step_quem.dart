import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/ember_retro_theme.dart';
import '../../../connections/domain/brasa.dart';
import '../../../connections/domain/contact.dart';
import '../../../connections/domain/contact_group.dart';
import '../../../connections/presentation/widgets/connection_ui.dart';
import '../../../connections/providers/connections_providers.dart';
import '../../domain/invited_person.dart';
import 'create_plan_widgets.dart';

/// Passo 3: quem vai. Grade das conexões (toque marca, segurar = essencial),
/// grupos, nome novo pela busca e o interruptor de link aberto.
class StepQuem extends ConsumerStatefulWidget {
  const StepQuem({
    super.key,
    required this.convidados,
    required this.onChanged,
    required this.linkAberto,
    required this.onLinkAbertoChanged,
  });

  final List<InvitedPerson> convidados;
  final ValueChanged<List<InvitedPerson>> onChanged;
  final bool linkAberto;
  final ValueChanged<bool> onLinkAbertoChanged;

  @override
  ConsumerState<StepQuem> createState() => _StepQuemState();
}

class _StepQuemState extends ConsumerState<StepQuem> {
  final _searchCtrl = TextEditingController();

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

  List<InvitedPerson> get _list => widget.convidados;

  int _indexOfContact(Contact c) => _list.indexWhere((p) => p.existingContactId != null && p.existingContactId == c.id);

  void _toggleContact(Contact c) {
    final i = _indexOfContact(c);
    final next = [..._list];
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add(InvitedPerson(nome: c.nome, tipo: c.tipo, existingContactId: c.id, linkedUserId: c.linkedUserId));
    }
    widget.onChanged(next);
  }

  /// Segurar: marca/desmarca como essencial (e já seleciona, se não estava).
  void _toggleEssencial(int index) {
    final next = [..._list];
    next[index] = next[index].copyWith(essencial: !next[index].essencial);
    widget.onChanged(next);
  }

  void _essencialContact(Contact c) {
    final i = _indexOfContact(c);
    if (i < 0) {
      final next = [..._list, InvitedPerson(nome: c.nome, tipo: c.tipo, existingContactId: c.id, linkedUserId: c.linkedUserId, essencial: true)];
      widget.onChanged(next);
      return;
    }
    _toggleEssencial(i);
  }

  void _toggleGroup(ContactGroup g, List<Contact> contacts) {
    final members = [for (final c in contacts) if (g.contains(c.id)) c];
    if (members.isEmpty) return;
    final allIn = members.every((c) => _indexOfContact(c) >= 0);
    final next = [..._list];
    if (allIn) {
      next.removeWhere((p) => p.existingContactId != null && g.contains(p.existingContactId));
    } else {
      for (final c in members) {
        if (_indexOfContact(c) < 0) {
          next.add(InvitedPerson(nome: c.nome, tipo: c.tipo, existingContactId: c.id, linkedUserId: c.linkedUserId));
        }
      }
    }
    widget.onChanged(next);
  }

  void _addNew(String nome) {
    widget.onChanged([..._list, InvitedPerson(nome: nome)]);
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final contacts = ref.watch(myContactsProvider).valueOrNull ?? const <Contact>[];
    final groups = ref.watch(contactGroupsProvider).valueOrNull ?? const <ContactGroup>[];
    final query = normalizeName(_searchCtrl.text);
    final typed = _searchCtrl.text.trim();

    final shownContacts = sortContacts(
      contacts.where((c) => query.isEmpty || normalizeName(c.nome).contains(query)),
      ContactSort.nome,
      const {},
    );
    // Pessoas novas (fora das conexões) que já estão na lista.
    final novos = [
      for (var i = 0; i < _list.length; i++)
        if (_list[i].existingContactId == null &&
            (query.isEmpty || normalizeName(_list[i].nome).contains(query)))
          i,
    ];
    final exists = contacts.any((c) => normalizeName(c.nome) == query) ||
        _list.any((x) => normalizeName(x.nome) == query);
    final canAddTyped = typed.isNotEmpty && !exists;
    final selectedCount = _list.length;
    final essenciais = _list.where((x) => x.essencial).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepQuestion('Quem você chama?'),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canAddTyped) _addNew(typed);
          },
          decoration: const InputDecoration(
            hintText: 'Buscar ou adicionar pelo nome',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        if (canAddTyped) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: RetroButton(
              onPressed: () => _addNew(typed),
              height: 40,
              color: EmberColors.lavanda,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_rounded, size: 18),
                  const SizedBox(width: 8),
                  Flexible(child: Text('Chamar "$typed"', overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        ],

        // ------------------------------------------------ grupos
        if (groups.isNotEmpty && query.isEmpty) ...[
          const SizedBox(height: 14),
          const SectionLabel('Grupos'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in groups)
                Builder(builder: (_) {
                  final members = [for (final c in contacts) if (g.contains(c.id)) c];
                  final picked = members.where((c) => _indexOfContact(c) >= 0).length;
                  final all = members.isNotEmpty && picked == members.length;
                  return RetroChoiceChip(
                    label: g.nome,
                    trailing: picked > 0 && !all ? '$picked/${members.length}' : '${members.length}',
                    dotColor: all ? null : g.cor.color,
                    icon: all ? Icons.check_rounded : (picked > 0 ? Icons.remove_rounded : null),
                    color: g.cor.color,
                    selected: picked > 0,
                    onTap: () => _toggleGroup(g, contacts),
                  );
                }),
            ],
          ),
        ],

        // ------------------------------------------------ grade
        const SizedBox(height: 16),
        SectionLabel(
          selectedCount == 0
              ? 'Toque pra chamar'
              : '$selectedCount ${selectedCount == 1 ? 'chamado' : 'chamados'}'
                  '${essenciais > 0 ? ' · $essenciais ${essenciais == 1 ? 'essencial' : 'essenciais'}' : ''}',
        ),
        const SizedBox(height: 10),
        if (shownContacts.isEmpty && novos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              contacts.isEmpty
                  ? 'Você ainda não tem conexões. Digite um nome acima pra chamar alguém.'
                  : 'Ninguém com esse nome nas conexões.',
              style: EmberText.body(13, color: p.textoSecundario),
            ),
          )
        else
          LayoutBuilder(builder: (context, box) {
            final cols = (box.maxWidth / 82).floor().clamp(3, 6);
            final w = (box.maxWidth - (cols - 1) * 6) / cols;
            return Wrap(
              spacing: 6,
              runSpacing: 14,
              children: [
                for (final c in shownContacts)
                  Builder(builder: (_) {
                    final i = _indexOfContact(c);
                    return _PersonBubble(
                      width: w,
                      nome: c.nome,
                      color: c.tipo.color,
                      selected: i >= 0,
                      essencial: i >= 0 && _list[i].essencial,
                      onTap: () => _toggleContact(c),
                      onLongPress: () => _essencialContact(c),
                    );
                  }),
                for (final i in novos)
                  _PersonBubble(
                    width: w,
                    nome: _list[i].nome,
                    color: _list[i].tipo.color,
                    selected: true,
                    essencial: _list[i].essencial,
                    isNew: true,
                    onTap: () => widget.onChanged([..._list]..removeAt(i)),
                    onLongPress: () => _toggleEssencial(i),
                  ),
              ],
            );
          }),
        const SizedBox(height: 16),

        // ------------------------------------------------ dica essencial
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: EmberColors.sol.withAlpha(60),
            borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
            border: Border.all(color: p.contorno, width: 2.5),
          ),
          child: Row(
            children: [
              const _StarBadge(size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: 'Essencial: ', style: TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: 'toque e segure na pessoa. Sem ela, o horário não rola.'),
                    ],
                  ),
                  style: EmberText.body(12.5, color: p.texto),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ------------------------------------------------ link aberto
        RetroCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 22, color: p.texto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qualquer um com o link entra', style: EmberText.body(14, weight: FontWeight.w800)),
                    Text(
                      widget.linkAberto ? 'Bom pra mandar no grupo' : 'Só quem você chamou aqui pode votar',
                      style: EmberText.body(12, color: p.textoSecundario),
                    ),
                  ],
                ),
              ),
              RetroToggle(
                value: widget.linkAberto,
                onChanged: widget.onLinkAbertoChanged,
                semanticLabel: 'Qualquer um com o link entra',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonBubble extends StatelessWidget {
  const _PersonBubble({
    required this.width,
    required this.nome,
    required this.color,
    required this.selected,
    required this.essencial,
    required this.onTap,
    required this.onLongPress,
    this.isNew = false,
  });

  final double width;
  final String nome;
  final Color color;
  final bool selected;
  final bool essencial;
  final bool isNew;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final first = nome.trim().split(' ').first;
    return Semantics(
      button: true,
      selected: selected,
      label: '$nome${essencial ? ', essencial' : ''}',
      hint: 'Toque pra ${selected ? 'tirar' : 'chamar'}. Segure pra marcar como essencial.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              SizedBox(
                width: 66,
                height: 66,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? color : color.withAlpha(90),
                          shape: BoxShape.circle,
                          border: Border.all(color: p.contorno, width: 2.5),
                          boxShadow: selected
                              ? [
                                  BoxShadow(color: p.tela, spreadRadius: 3),
                                  const BoxShadow(color: EmberColors.menta, spreadRadius: 6),
                                ]
                              : null,
                        ),
                        child: Text(
                          first.isEmpty ? '?' : first.characters.first.toUpperCase(),
                          style: EmberText.body(21, color: EmberColors.tinta, weight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (essencial) const Positioned(top: -4, right: -2, child: _StarBadge(size: 24)),
                    if (selected)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: EmberColors.menta,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.contorno, width: 2.5),
                          ),
                          child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    if (isNew)
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: EmberColors.lavanda,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: p.contorno, width: 2),
                          ),
                          child: Text('NOVO', style: EmberText.mono(8, color: EmberColors.tinta)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: EmberText.body(12.5, weight: selected ? FontWeight.w800 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EmberColors.sol,
        shape: BoxShape.circle,
        border: Border.all(color: p.contorno, width: 2.5),
      ),
      child: Icon(Icons.star_rounded, size: size * 0.6, color: EmberColors.tinta),
    );
  }
}
