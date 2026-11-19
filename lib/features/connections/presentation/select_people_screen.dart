import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../../plans/domain/invited_person.dart';
import '../domain/brasa.dart';
import '../domain/contact.dart';
import '../domain/contact_group.dart';
import '../providers/connections_providers.dart';
import 'widgets/connection_ui.dart';
import 'widgets/contact_tile.dart';

/// O que vem marcado ao abrir a seleção.
class SelectPeopleArgs {
  const SelectPeopleArgs({this.contactIds = const {}, this.groupId});

  final Set<String> contactIds;
  final String? groupId;
}

/// Escolhe quem chamar pro rolê: por grupo (chips) ou pessoa a pessoa.
/// "Criar rolê" abre o Novo rolê com essa galera já na lista de convidados.
class SelectPeopleScreen extends ConsumerStatefulWidget {
  const SelectPeopleScreen({super.key, this.args = const SelectPeopleArgs()});

  final SelectPeopleArgs args;

  @override
  ConsumerState<SelectPeopleScreen> createState() => _SelectPeopleScreenState();
}

class _SelectPeopleScreenState extends ConsumerState<SelectPeopleScreen> {
  late final Set<String> _selected = {...widget.args.contactIds};
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    final groupId = widget.args.groupId;
    if (groupId != null) {
      // Marca o grupo assim que ele carregar.
      ref.read(contactGroupsProvider.future).then((groups) {
        if (!mounted) return;
        for (final g in groups) {
          if (g.id == groupId) setState(() => _selected.addAll(g.memberIds));
        }
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/connections');
    }
  }

  void _toggle(String? id) {
    if (id == null) return;
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _toggleGroup(ContactGroup g, Set<String> existingIds) {
    final ids = g.memberIds.intersection(existingIds);
    setState(() {
      if (_selected.containsAll(ids)) {
        _selected.removeAll(ids);
      } else {
        _selected.addAll(ids);
      }
    });
  }

  void _createPlan(List<Contact> contacts) {
    final people = sortContacts(
      contacts.where((c) => _selected.contains(c.id)),
      ContactSort.nome,
      const {},
    );
    final invited = [
      for (final c in people) InvitedPerson(nome: c.nome, tipo: c.tipo, existingContactId: c.id, linkedUserId: c.linkedUserId),
    ];
    // Substitui a seleção: voltar do Novo rolê leva direto pras conexões.
    context.pushReplacement('/create-plan', extra: invited);
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final contactsAsync = ref.watch(myContactsProvider);

    return RetroScaffold(
      top: RetroTopBar(
        left: 'CHAMAR',
        right: 'GALERA',
        leading: RetroButton.icon(
          onPressed: _close,
          shape: RetroButtonShape.circle,
          semanticLabel: 'Fechar',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      panelPadding: EdgeInsets.zero,
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: RetroErrorBox('Não deu pra carregar suas conexões.'),
          ),
        ),
        data: (contacts) {
          final groups = ref.watch(contactGroupsProvider).valueOrNull ?? const <ContactGroup>[];
          final lastPlans = ref.watch(contactLastPlansProvider).valueOrNull ?? const <String, LastPlan>{};
          final sort = ref.watch(contactSortProvider);
          final existingIds = {for (final c in contacts) if (c.id != null) c.id!};
          // Ignora IDs que não existem mais.
          _selected.retainAll(existingIds);

          final query = normalizeName(_searchCtrl.text);
          final visible = sortContacts(
            contacts.where((c) => query.isEmpty || normalizeName(c.nome).contains(query)),
            sort,
            lastPlans,
          );
          final selectedPeople = [for (final c in contacts) if (_selected.contains(c.id)) c];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 26, 14, 110),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          _selected.isEmpty
                              ? 'Quem você chama?'
                              : '${_selected.length} ${_selected.length == 1 ? 'selecionado' : 'selecionados'}',
                          style: EmberText.display(27),
                        ),
                      ),
                      if (_selected.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(_selected.clear),
                          style: TextButton.styleFrom(foregroundColor: p.texto, minimumSize: const Size(44, 44)),
                          child: Text(
                            'LIMPAR',
                            style: EmberText.mono(11).copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar pelo nome',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  if (groups.isNotEmpty && query.isEmpty) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('Grupos'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in groups)
                          _GroupChip(
                            group: g,
                            total: g.memberIds.intersection(existingIds).length,
                            picked: g.memberIds.intersection(_selected).length,
                            onTap: () => _toggleGroup(g, existingIds),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SectionLabel('Pessoas · ${visible.length}'),
                  const SizedBox(height: 8),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        contacts.isEmpty ? 'Você ainda não tem conexões.' : 'Ninguém encontrado.',
                        textAlign: TextAlign.center,
                        style: EmberText.body(15, color: p.textoSecundario, weight: FontWeight.w600),
                      ),
                    ),
                  for (final c in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ContactTile(
                        contact: c,
                        lastPlan: lastPlans[c.id],
                        selected: _selected.contains(c.id),
                        onTap: () => _toggle(c.id),
                      ),
                    ),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _SelectionBar(
                  people: selectedPeople,
                  onCreate: selectedPeople.isEmpty ? null : () => _createPlan(contacts),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================================

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.group, required this.total, required this.picked, required this.onTap});

  final ContactGroup group;
  final int total;
  final int picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final all = total > 0 && picked == total;
    final some = picked > 0 && !all;
    return RetroChoiceChip(
      label: group.nome,
      trailing: some ? '$picked/$total' : '$total',
      dotColor: all ? null : group.cor.color,
      icon: all ? Icons.check_rounded : (some ? Icons.remove_rounded : null),
      color: group.cor.color,
      selected: all || some,
      onTap: total == 0 ? () {} : onTap,
    );
  }
}

/// Barra fixa embaixo: quem foi escolhido + "Criar rolê".
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.people, required this.onCreate});

  final List<Contact> people;
  final VoidCallback? onCreate;

  String get _summary {
    final names = [for (final c in people) c.nome.split(' ').first];
    if (names.isEmpty) return 'Toque nas pessoas ou nos grupos';
    if (names.length == 1) return names.first;
    if (names.length <= 3) return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
    return '${names.take(2).join(', ')} e mais ${names.length - 2}';
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final shown = people.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: p.invertido,
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        border: p.contornoBorda,
        boxShadow: [BoxShadow(color: p.contorno.withAlpha(90), offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          if (shown.isNotEmpty) ...[
            SizedBox(
              width: 26.0 + (shown.length - 1) * 18,
              height: 28,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(left: i * 18.0, child: ContactAvatar(contact: shown[i], size: 28)),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              _summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EmberText.body(13.5, color: p.noInvertido, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          RetroButton(
            onPressed: onCreate,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Criar rolê'), SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 18)],
            ),
          ),
        ],
      ),
    );
  }
}
