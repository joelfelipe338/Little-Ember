import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/retro_top_bar.dart';
import '../../../../theme/ember_retro_theme.dart';
import '../../domain/brasa.dart';
import '../../domain/contact.dart';
import '../../domain/contact_group.dart';
import '../../providers/connections_providers.dart';
import 'connection_ui.dart';

/// Abre um bottom sheet no estilo retrô (fundo transparente, ajusta ao teclado).
Future<T?> showRetroSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Moldura do sheet: superfície, contorno grosso em cima e alça.
class RetroSheet extends StatelessWidget {
  const RetroSheet({super.key, required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: p.contorno, width: 3),
          left: BorderSide(color: p.contorno, width: 3),
          right: BorderSide(color: p.contorno, width: 3),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: p.textoSecundario.withAlpha(90),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text(title, style: EmberText.display(23))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Fechar',
                  icon: Icon(Icons.close_rounded, color: p.texto),
                ),
              ],
            ),
            if (subtitle != null) ...[
              Text(subtitle!, style: EmberText.body(13, color: p.textoSecundario)),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Adicionar / editar pessoa
// ===========================================================================

class ContactFormResult {
  const ContactFormResult({required this.contact, this.callNow = false});

  final Contact contact;

  /// Usuário tocou em "Salvar e chamar": abrir a seleção pro rolê com ela.
  final bool callNow;
}

class ContactFormSheet extends ConsumerStatefulWidget {
  const ContactFormSheet({
    super.key,
    required this.contacts,
    required this.groups,
    this.initial,
  });

  /// Todas as conexões, para avisar de nome repetido.
  final List<Contact> contacts;
  final List<ContactGroup> groups;

  /// Preenchido = edição.
  final Contact? initial;

  @override
  ConsumerState<ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends ConsumerState<ContactFormSheet> {
  late final _nameCtrl = TextEditingController(text: widget.initial?.nome ?? '');
  late ConnectionType _tipo = widget.initial?.tipo ?? ConnectionType.amigos;
  final Set<String> _groupIds = {};
  final Set<String> _initialGroupIds = {};
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
    for (final g in widget.groups) {
      if (g.contains(widget.initial?.id)) _groupIds.add(g.id);
    }
    _initialGroupIds.addAll(_groupIds);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Contact? get _duplicate {
    final n = normalizeName(_nameCtrl.text);
    if (n.isEmpty) return null;
    for (final c in widget.contacts) {
      if (c.id != widget.initial?.id && normalizeName(c.nome) == n) return c;
    }
    return null;
  }

  Future<void> _save({bool callNow = false}) async {
    final nome = _nameCtrl.text.trim();
    if (nome.isEmpty) {
      setState(() => _error = 'Digite o nome da pessoa.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(connectionsRepositoryProvider);
    try {
      final Contact contact = _isEdit
          ? await repo.updateContact(id: widget.initial!.id!, nome: nome, tipo: _tipo)
          : await repo.createContact(nome: nome, tipo: _tipo);
      final groupsChanged = _groupIds.length != _initialGroupIds.length || !_groupIds.containsAll(_initialGroupIds);
      if (groupsChanged && contact.id != null) {
        await repo.setContactGroups(contact.id!, _groupIds);
      }
      if (mounted) Navigator.pop(context, ContactFormResult(contact: contact, callNow: callNow));
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não deu pra salvar. Confere a internet e tenta de novo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final dup = _duplicate;
    final hasName = _nameCtrl.text.trim().isNotEmpty;

    return RetroSheet(
      title: _isEdit ? 'Editar conexão' : 'Adicionar pessoa',
      children: [
        const RetroFieldLabel('Nome'),
        TextField(
          controller: _nameCtrl,
          autofocus: !_isEdit,
          enabled: !_saving,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: const InputDecoration(hintText: 'Ex.: Maria Clara', counterText: ''),
        ),
        if (dup != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
              border: Border.all(color: p.textoSecundario.withAlpha(120), width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: p.textoSecundario),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Já existe "${dup.nome}" nas suas conexões.',
                    style: EmberText.body(13, color: p.textoSecundario),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const RetroFieldLabel('Quem é pra você?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in ConnectionType.values)
              RetroChoiceChip(
                label: t.label,
                icon: t.icon,
                color: t.color,
                selected: t == _tipo,
                onTap: () => setState(() => _tipo = t),
              ),
          ],
        ),
        if (widget.groups.isNotEmpty) ...[
          const SizedBox(height: 16),
          const RetroFieldLabel('Grupos (opcional)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in widget.groups)
                RetroChoiceChip(
                  label: g.nome,
                  dotColor: g.cor.color,
                  color: g.cor.color,
                  icon: _groupIds.contains(g.id) ? Icons.check_rounded : null,
                  selected: _groupIds.contains(g.id),
                  onTap: () => setState(() {
                    if (!_groupIds.remove(g.id)) _groupIds.add(g.id);
                  }),
                ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          RetroErrorBox(_error!),
        ],
        const SizedBox(height: 20),
        if (_isEdit)
          RetroButton(
            onPressed: _saving || !hasName ? null : () => _save(),
            expand: true,
            child: _saving ? const RetroButtonSpinner() : const Text('Salvar alterações'),
          )
        else
          Row(
            children: [
              Expanded(
                flex: 2,
                child: RetroButton(
                  onPressed: _saving || !hasName ? null : () => _save(),
                  color: p.botaoSecundario,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: RetroButton(
                  onPressed: _saving || !hasName ? null : () => _save(callNow: true),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _saving
                      ? const RetroButtonSpinner()
                      : const Text('Salvar e chamar', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ===========================================================================
// Criar / editar grupo
// ===========================================================================

class GroupFormSheet extends ConsumerStatefulWidget {
  const GroupFormSheet({super.key, required this.contacts, this.initial});

  final List<Contact> contacts;
  final ContactGroup? initial;

  @override
  ConsumerState<GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends ConsumerState<GroupFormSheet> {
  late final _nameCtrl = TextEditingController(text: widget.initial?.nome ?? '');
  late GroupColor _cor = widget.initial?.cor ?? GroupColor.lavanda;
  late final Set<String> _members = {...?widget.initial?.memberIds};
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nome = _nameCtrl.text.trim();
    if (nome.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(connectionsRepositoryProvider);
    // Só IDs de conexões que ainda existem.
    final ids = {
      for (final c in widget.contacts)
        if (c.id != null && _members.contains(c.id)) c.id!,
    };
    try {
      if (_isEdit) {
        await repo.updateGroup(id: widget.initial!.id, nome: nome, cor: _cor, memberIds: ids);
      } else {
        await repo.createGroup(nome: nome, cor: _cor, memberIds: ids);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não deu pra salvar o grupo. Tenta de novo.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar o grupo?'),
        content: Text('"${widget.initial!.nome}" some da lista. As pessoas continuam nas suas conexões.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: RetroPalette.of(ctx).erroTexto),
            child: const Text('Apagar grupo'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(connectionsRepositoryProvider).deleteGroup(widget.initial!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não deu pra apagar o grupo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final sorted = sortContacts(widget.contacts, ContactSort.nome, const {});
    final hasName = _nameCtrl.text.trim().isNotEmpty;

    return RetroSheet(
      title: _isEdit ? 'Editar grupo' : 'Novo grupo',
      subtitle: 'Junte quem sempre sai junto e chame todo mundo de uma vez.',
      children: [
        const RetroFieldLabel('Nome do grupo'),
        TextField(
          controller: _nameCtrl,
          autofocus: !_isEdit,
          enabled: !_saving,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: Galera do vôlei', counterText: ''),
        ),
        const SizedBox(height: 14),
        const RetroFieldLabel('Cor'),
        Row(
          children: [
            for (final c in GroupColor.values)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Semantics(
                  button: true,
                  selected: c == _cor,
                  label: 'Cor ${c.name}',
                  child: GestureDetector(
                    onTap: () => setState(() => _cor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.contorno, width: c == _cor ? 3.5 : 2.5),
                        boxShadow: c == _cor ? null : [BoxShadow(color: p.contorno, offset: const Offset(0, 3))],
                      ),
                      child: c == _cor ? const Icon(Icons.check_rounded, color: EmberColors.tinta, size: 22) : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SectionLabel(
          'Quem está no grupo · ${_members.length}',
          trailing: sorted.isEmpty
              ? null
              : GestureDetector(
                  onTap: () => setState(() {
                    if (_members.length == sorted.length) {
                      _members.clear();
                    } else {
                      _members.addAll([for (final c in sorted) if (c.id != null) c.id!]);
                    }
                  }),
                  child: Text(
                    _members.length == sorted.length ? 'LIMPAR' : 'TODOS',
                    style: EmberText.mono(10.5).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text('Adicione pessoas nas conexões primeiro.', style: EmberText.body(13, color: p.textoSecundario))
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              border: Border.all(color: p.contorno, width: 2.5),
              borderRadius: BorderRadius.circular(EmberRetro.raioBotao),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: p.linhaSuave),
              itemBuilder: (_, i) {
                final c = sorted[i];
                final on = _members.contains(c.id);
                return CheckboxListTile(
                  value: on,
                  dense: true,
                  activeColor: EmberColors.menta,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: ContactAvatar(contact: c, size: 30),
                  title: Text(c.nome, style: EmberText.body(14, weight: FontWeight.w700)),
                  onChanged: c.id == null
                      ? null
                      : (_) => setState(() {
                            if (!_members.remove(c.id)) _members.add(c.id!);
                          }),
                );
              },
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          RetroErrorBox(_error!),
        ],
        const SizedBox(height: 20),
        RetroButton(
          onPressed: _saving || !hasName ? null : _save,
          expand: true,
          child: _saving
              ? const RetroButtonSpinner()
              : Text(_isEdit ? 'Salvar grupo' : 'Criar grupo'),
        ),
        if (_isEdit) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _saving ? null : _delete,
              style: TextButton.styleFrom(foregroundColor: p.erroTexto, minimumSize: const Size(44, 44)),
              child: const Text('Apagar grupo'),
            ),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// Ações de uma pessoa
// ===========================================================================

enum ContactAction { chamar, editar, remover }

class ContactActionsSheet extends StatelessWidget {
  const ContactActionsSheet({super.key, required this.contact, this.lastPlan, this.groups = const []});

  final Contact contact;
  final LastPlan? lastPlan;
  final List<ContactGroup> groups;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final inGroups = [for (final g in groups) if (g.contains(contact.id)) g.nome];

    Widget action(ContactAction a, IconData icon, String label, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RetroButton(
            onPressed: () => Navigator.pop(context, a),
            expand: true,
            color: color ?? p.botaoSecundario,
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Text(label),
              ],
            ),
          ),
        );

    return RetroSheet(
      title: contact.nome,
      subtitle: [
        contact.tipo.label,
        brasaSubtitle(lastPlan),
        if (inGroups.isNotEmpty) inGroups.join(', '),
      ].join(' · '),
      children: [
        action(ContactAction.chamar, Icons.campaign_rounded, 'Chamar pro rolê', color: EmberColors.sol),
        action(ContactAction.editar, Icons.edit_rounded, 'Editar nome, tipo e grupos'),
        action(ContactAction.remover, Icons.delete_outline_rounded, 'Remover das conexões',
            color: p.erroFundo),
      ],
    );
  }
}

// ===========================================================================
// Ordenar
// ===========================================================================

class SortSheet extends StatelessWidget {
  const SortSheet({super.key, required this.current});

  final ContactSort current;

  static const _icons = {
    ContactSort.nome: Icons.sort_by_alpha_rounded,
    ContactSort.brasa: Icons.ac_unit_rounded,
    ContactSort.ultimoRole: Icons.event_rounded,
    ContactSort.recentes: Icons.schedule_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    return RetroSheet(
      title: 'Ordenar por',
      children: [
        for (final s in ContactSort.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RetroButton(
              onPressed: () => Navigator.pop(context, s),
              expand: true,
              color: s == current ? EmberColors.sol : p.botaoSecundario,
              child: Row(
                children: [
                  Icon(_icons[s], size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.label)),
                  if (s == current) const Icon(Icons.check_rounded, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
