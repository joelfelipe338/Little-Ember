import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/ember_button.dart';
import '../../../shared/widgets/retro_empty_state.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../domain/brasa.dart';
import '../domain/contact.dart';
import '../domain/contact_group.dart';
import '../domain/link_request.dart';
import '../providers/connections_providers.dart';
import '../../subscription/domain/subscription.dart';
import '../../subscription/presentation/plus_sheet.dart';
import '../../subscription/providers/subscription_providers.dart';
import 'select_people_screen.dart';
import 'widgets/connection_sheets.dart';
import 'widgets/connection_ui.dart';
import 'widgets/contact_tile.dart';

/// Conexões: a galera do usuário, agrupada pelos grupos que ele criou.
///
/// - "Chamar" (na pessoa, no grupo ou no destaque) abre a seleção pro rolê.
/// - Tocar na pessoa abre as ações (chamar, editar, remover).
/// - Segurar na pessoa também abre a seleção, já com ela marcada.
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

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

  // ---------------------------------------------------------------- navegação

  void _openSelect({String? contactId, String? groupId}) {
    context.push(
      '/connections/select',
      extra: SelectPeopleArgs(
        contactIds: {if (contactId != null) contactId},
        groupId: groupId,
      ),
    );
  }

  Future<void> _addContact(List<Contact> contacts, List<ContactGroup> groups) async {
    final result = await showRetroSheet<ContactFormResult>(
      context,
      (_) => ContactFormSheet(contacts: contacts, groups: groups),
    );
    if (result == null || !mounted) return;
    refreshConnections(ref);
    if (result.callNow) {
      _openSelect(contactId: result.contact.id);
    } else {
      _snack('${result.contact.nome} entrou nas suas conexões.');
    }
  }

  Future<void> _editContact(Contact c, List<Contact> contacts, List<ContactGroup> groups) async {
    final result = await showRetroSheet<ContactFormResult>(
      context,
      (_) => ContactFormSheet(contacts: contacts, groups: groups, initial: c),
    );
    if (result != null && mounted) refreshConnections(ref);
  }

  Future<void> _removeContact(Contact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover conexão?'),
        content: Text('${c.nome} sai das suas conexões e dos seus grupos. Os rolês antigos continuam.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: RetroPalette.of(ctx).erroTexto),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true || c.id == null) return;
    try {
      await ref.read(connectionsRepositoryProvider).deleteContact(c.id!);
      refreshConnections(ref);
    } catch (_) {
      if (mounted) _snack('Não deu pra remover. Tenta de novo.');
    }
  }

  Future<void> _contactActions(
    Contact c,
    LastPlan? last,
    List<Contact> contacts,
    List<ContactGroup> groups,
  ) async {
    final action = await showRetroSheet<ContactAction>(
      context,
      (_) => ContactActionsSheet(contact: c, lastPlan: last, groups: groups),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case ContactAction.chamar:
        _openSelect(contactId: c.id);
      case ContactAction.editar:
        await _editContact(c, contacts, groups);
      case ContactAction.remover:
        await _removeContact(c);
    }
  }

  Future<void> _groupForm(List<Contact> contacts, [ContactGroup? group]) async {
    if (group == null) {
      final total = ref.read(contactGroupsProvider).valueOrNull?.length ?? 0;
      final max = ref.read(subscriptionProvider).limit(PlanFeature.grupos);
      if (total >= max) {
        await showPlusSheet(
          context,
          titulo: 'Limite de grupos',
          motivo: 'No plano grátis dá pra ter até $max grupos. Com o CHAMMA+ não tem limite.',
        );
        return;
      }
    }
    final changed = await showRetroSheet<bool>(
      context,
      (_) => GroupFormSheet(contacts: contacts, initial: group),
    );
    if (changed == true && mounted) ref.invalidate(contactGroupsProvider);
  }

  Future<void> _pickSort() async {
    final current = ref.read(contactSortProvider);
    final s = await showRetroSheet<ContactSort>(context, (_) => SortSheet(current: current));
    if (s != null) ref.read(contactSortProvider.notifier).state = s;
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(myContactsProvider);
    final groups = ref.watch(contactGroupsProvider).valueOrNull ?? const <ContactGroup>[];

    return RetroScaffold(
      top: RetroTopBar(
        left: 'SUAS',
        right: 'CONEXÕES',
        trailing: RetroButton.icon(
          onPressed: () => setState(() {
            _searching = !_searching;
            if (!_searching) _searchCtrl.clear();
          }),
          shape: RetroButtonShape.circle,
          semanticLabel: _searching ? 'Fechar busca' : 'Buscar',
          icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
        ),
      ),
      panelPadding: EdgeInsets.zero,
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RetroErrorBox('Não deu pra carregar suas conexões.'),
                const SizedBox(height: 16),
                EmberButton(label: 'Tentar de novo', onPressed: () => refreshConnections(ref)),
              ],
            ),
          ),
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return RetroEmptyState(
              illustration: const Icon(Icons.diversity_3_rounded, size: 72, color: EmberColors.lavanda),
              title: 'Sua galera começa aqui',
              message: 'Adicione quem sai com você. Depois é só chamar pro rolê com um toque.',
              action: EmberButton(
                label: 'Adicionar pessoa',
                icon: Icons.person_add_rounded,
                onPressed: () => _addContact(contacts, groups),
              ),
            );
          }
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  refreshConnections(ref);
                  await ref.read(myContactsProvider.future);
                },
                child: _buildList(contacts, groups),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: RetroButton(
                  onPressed: () => _addContact(contacts, groups),
                  shape: RetroButtonShape.pill,
                  height: 50,
                  semanticLabel: 'Adicionar pessoa',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.person_add_rounded), SizedBox(width: 8), Text('Adicionar')],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Contact> contacts, List<ContactGroup> groups) {
    final p = RetroPalette.of(context);
    final lastPlans = ref.watch(contactLastPlansProvider).valueOrNull ?? const <String, LastPlan>{};
    final sort = ref.watch(contactSortProvider);
    final filter = ref.watch(contactTypeFilterProvider);
    final query = normalizeName(_searchCtrl.text);
    final filtering = filter != null || query.isNotEmpty;

    final visible = sortContacts(
      contacts.where((c) =>
          (filter == null || c.tipo == filter) && (query.isEmpty || normalizeName(c.nome).contains(query))),
      sort,
      lastPlans,
    );

    // Destaque: quem está há mais tempo sem rolê (passou do limite de esfriar).
    Contact? coldest;
    var coldestDays = diasParaEsfriar;
    if (!filtering) {
      for (final c in contacts) {
        final d = daysSince(lastPlans[c.id]);
        if (d != null && d > coldestDays) {
          coldest = c;
          coldestDays = d;
        }
      }
    }

    final cold = coldest;
    final ungrouped = [for (final c in visible) if (!groups.any((g) => g.contains(c.id))) c];
    final counts = <ConnectionType, int>{};
    for (final c in contacts) {
      counts[c.tipo] = (counts[c.tipo] ?? 0) + 1;
    }

    Widget tile(Contact c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ContactTile(
            contact: c,
            lastPlan: lastPlans[c.id],
            onTap: () => _contactActions(c, lastPlans[c.id], contacts, groups),
            onLongPress: () => _openSelect(contactId: c.id),
            onCall: () => _openSelect(contactId: c.id),
          ),
        );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 26, 14, 100),
      children: [
        // ------------------------------------------------ título + ordenar
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sua galera', style: EmberText.display(29)),
                  const SizedBox(height: 2),
                  Text(
                    '${contacts.length} ${contacts.length == 1 ? 'PESSOA' : 'PESSOAS'}'
                    '${groups.isEmpty ? '' : ' · ${groups.length} ${groups.length == 1 ? 'GRUPO' : 'GRUPOS'}'}',
                    style: EmberText.mono(10.5, color: p.textoSecundario),
                  ),
                ],
              ),
            ),
            RetroButton(
              onPressed: _pickSort,
              height: 38,
              shape: RetroButtonShape.pill,
              color: p.botaoSecundario,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              semanticLabel: 'Ordenar por ${sort.label}',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text(sort.short, style: EmberText.mono(10.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ------------------------------------------------ pedidos de vínculo
        const _LinkRequestsSection(),

        // ------------------------------------------------ busca
        if (_searching) ...[
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Buscar pelo nome',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ------------------------------------------------ filtros por tipo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              RetroChoiceChip(
                label: 'Todos',
                trailing: '${contacts.length}',
                selected: filter == null,
                onTap: () => ref.read(contactTypeFilterProvider.notifier).state = null,
              ),
              for (final t in ConnectionType.values)
                if ((counts[t] ?? 0) > 0) ...[
                  const SizedBox(width: 8),
                  RetroChoiceChip(
                    label: t.labelPlural,
                    trailing: '${counts[t]}',
                    selected: filter == t,
                    onTap: () => ref.read(contactTypeFilterProvider.notifier).state = filter == t ? null : t,
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------ brasa esfriando
        if (cold != null) ...[
          _ColdCard(
            contact: cold,
            days: coldestDays,
            onCall: () => _openSelect(contactId: cold.id),
          ),
          const SizedBox(height: 18),
        ],

        // ------------------------------------------------ grupos
        if (groups.isEmpty && !filtering) ...[
          _GroupsTip(onCreate: () => _groupForm(contacts)),
          const SizedBox(height: 18),
        ],

        for (final g in groups)
          ..._groupSection(g, visible, filtering, contacts, tile),

        // ------------------------------------------------ sem grupo
        if (ungrouped.isNotEmpty) ...[
          if (groups.isNotEmpty) ...[
            SectionLabel('Sem grupo · ${ungrouped.length}'),
            const SizedBox(height: 8),
          ],
          for (final c in ungrouped) tile(c),
        ],

        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Ninguém encontrado.',
              textAlign: TextAlign.center,
              style: EmberText.body(15, color: p.textoSecundario, weight: FontWeight.w600),
            ),
          ),

        if (groups.isNotEmpty && !filtering) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              RetroButton(
                onPressed: () => _groupForm(contacts),
                height: 40,
                color: p.botaoSecundario,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.group_add_rounded, size: 18), SizedBox(width: 8), Text('Novo grupo')],
                ),
              ),
              const Spacer(),
              Builder(builder: (context) {
                final ids = [for (final g in groups) g.id];
                final allClosed = ids.every(ref.watch(collapsedGroupsProvider).contains);
                return TextButton.icon(
                  onPressed: () => ref.read(collapsedGroupsProvider.notifier).setAll(ids, collapsed: !allClosed),
                  style: TextButton.styleFrom(foregroundColor: p.texto, minimumSize: const Size(44, 44)),
                  icon: Icon(allClosed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded, size: 18),
                  label: Text(
                    allClosed ? 'ABRIR TODOS' : 'MINIMIZAR TODOS',
                    style: EmberText.mono(10.5).copyWith(decoration: TextDecoration.underline),
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _groupSection(
    ContactGroup g,
    List<Contact> visible,
    bool filtering,
    List<Contact> contacts,
    Widget Function(Contact) tile,
  ) {
    final members = [for (final c in visible) if (g.contains(c.id)) c];
    if (members.isEmpty && filtering) return const [];
    final p = RetroPalette.of(context);
    // Buscando ou filtrando, mostra tudo aberto pra não esconder resultado.
    final collapsed = !filtering && ref.watch(collapsedGroupsProvider).contains(g.id);
    if (collapsed) {
      return [
        _GroupHeader(
          group: g,
          count: members.length,
          collapsed: true,
          onToggle: () => ref.read(collapsedGroupsProvider.notifier).toggle(g.id),
          onCall: members.isEmpty ? null : () => _openSelect(groupId: g.id),
          onEdit: () => _groupForm(contacts, g),
        ),
        const SizedBox(height: 12),
      ];
    }
    return [
      _GroupHeader(
        group: g,
        count: members.length,
        collapsed: false,
        onToggle: filtering ? null : () => ref.read(collapsedGroupsProvider.notifier).toggle(g.id),
        onCall: members.isEmpty ? null : () => _openSelect(groupId: g.id),
        onEdit: () => _groupForm(contacts, g),
      ),
      const SizedBox(height: 10),
      if (members.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            'Grupo vazio. Toque no lápis pra adicionar gente.',
            style: EmberText.body(13, color: p.textoSecundario),
          ),
        ),
      for (final c in members) tile(c),
      const SizedBox(height: 10),
    ];
  }
}

// ===========================================================================
// Pedaços da tela
// ===========================================================================

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.count,
    required this.collapsed,
    required this.onToggle,
    required this.onCall,
    required this.onEdit,
  });

  final ContactGroup group;
  final int count;
  final bool collapsed;

  /// Minimiza / abre o grupo. Null quando não dá pra minimizar (busca ativa).
  final VoidCallback? onToggle;
  final VoidCallback? onCall;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Semantics(
      button: onToggle != null,
      expanded: !collapsed,
      label: 'Grupo ${group.nome}, $count ${count == 1 ? 'pessoa' : 'pessoas'}',
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: group.cor.color.withAlpha(collapsed ? 110 : 60),
            borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
            border: Border.all(color: p.contorno, width: 2.5),
            boxShadow: collapsed ? [BoxShadow(color: p.contorno, offset: const Offset(0, 3))] : null,
          ),
          child: Row(
            children: [
              if (onToggle != null)
                AnimatedRotation(
                  turns: collapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(Icons.expand_more_rounded, size: 24, color: p.texto),
                )
              else
                const SizedBox(width: 6),
              const SizedBox(width: 4),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: group.cor.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.contorno, width: 2),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  group.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EmberText.display(18),
                ),
              ),
              Text(
                collapsed ? '$count ${count == 1 ? 'PESSOA' : 'PESSOAS'}' : '$count',
                style: EmberText.mono(11, color: p.textoSecundario),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Editar grupo',
                icon: Icon(Icons.edit_rounded, size: 19, color: p.texto),
              ),
              RetroButton(
                onPressed: onCall,
                height: 34,
                shape: RetroButtonShape.pill,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                semanticLabel: 'Chamar o grupo ${group.nome} pro rolê',
                child: Text('Chamar', style: EmberText.body(12.5, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColdCard extends StatelessWidget {
  const _ColdCard({required this.contact, required this.days, required this.onCall});

  final Contact contact;
  final int days;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return RetroCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE7ECF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.contorno, width: 2.5),
            ),
            child: const BrasaFlame(level: BrasaLevel.fria, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BRASA ESFRIANDO', style: EmberText.mono(10, color: p.textoSecundario)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$days dias sem rolê com '),
                      TextSpan(text: contact.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  style: EmberText.body(14, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RetroButton(
            onPressed: onCall,
            height: 38,
            color: EmberColors.brasa,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Chamar', style: EmberText.body(13, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _GroupsTip extends StatelessWidget {
  const _GroupsTip({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EmberRetro.raioCard),
        border: Border.all(color: p.textoSecundario.withAlpha(140), width: 2.5),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_rounded, size: 30, color: p.texto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crie grupos', style: EmberText.body(15, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  'Ex.: Galera do vôlei. Chame todo mundo de uma vez.',
                  style: EmberText.body(13, color: p.textoSecundario),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RetroButton(
            onPressed: onCreate,
            height: 38,
            color: EmberColors.lavanda,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Criar', style: EmberText.body(13, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// Pedidos de vínculo: alguém que você salvou nas conexões tem o app e quer
/// virar conexão real. Some sozinho quando não há pedidos.
class _LinkRequestsSection extends ConsumerStatefulWidget {
  const _LinkRequestsSection();

  @override
  ConsumerState<_LinkRequestsSection> createState() => _LinkRequestsSectionState();
}

class _LinkRequestsSectionState extends ConsumerState<_LinkRequestsSection> {
  final Set<String> _busy = {};

  Future<void> _respond(LinkRequest r, bool accept) async {
    setState(() => _busy.add(r.id));
    try {
      await ref.read(connectionsRepositoryProvider).respondLink(r.id, accept: accept);
      ref.invalidate(pendingLinkRequestsProvider);
      refreshConnections(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(accept
              ? 'Pronto! Você e ${r.requesterName} agora estão conectados no app.'
              : 'Pedido recusado.'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não deu pra responder o pedido. Tenta de novo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(pendingLinkRequestsProvider).valueOrNull ?? const <LinkRequest>[];
    if (requests.isEmpty) return const SizedBox.shrink();
    final p = RetroPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel('Pedidos de vínculo · ${requests.length}'),
          const SizedBox(height: 8),
          for (final r in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RetroCard(
                color: EmberColors.lavanda.withAlpha(50),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link_rounded, color: p.texto),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: r.requesterName, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const TextSpan(text: ' tem o CHAMMA e quer se conectar com você'),
                              if (normalizeName(r.contactName) != normalizeName(r.requesterName))
                                TextSpan(text: ' (você salvou como "${r.contactName}")'),
                              const TextSpan(text: '.'),
                            ]),
                            style: EmberText.body(13.5, color: p.texto),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Conectados, os próximos rolês chegam direto no app da outra pessoa.',
                      style: EmberText.body(12, color: p.textoSecundario),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: RetroButton(
                            onPressed: _busy.contains(r.id) ? null : () => _respond(r, false),
                            height: 40,
                            color: p.botaoSecundario,
                            child: const Text('Recusar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RetroButton(
                            onPressed: _busy.contains(r.id) ? null : () => _respond(r, true),
                            height: 40,
                            color: EmberColors.menta,
                            child: _busy.contains(r.id) ? const RetroButtonSpinner() : const Text('Aceitar'),
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
    );
  }
}
