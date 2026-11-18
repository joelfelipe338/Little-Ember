import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/retro_empty_state.dart';
import '../../../shared/widgets/retro_top_bar.dart';
import '../../../theme/ember_retro_theme.dart';
import '../domain/contact.dart';
import '../providers/connections_providers.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  static const tipoLabels = {
    ConnectionType.amigos: 'Amigo',
    ConnectionType.casal: 'Casal',
    ConnectionType.familia: 'Família',
    ConnectionType.trabalho: 'Trabalho',
    ConnectionType.outro: 'Outro',
  };

  static const tipoCores = {
    ConnectionType.amigos: EmberColors.lavanda,
    ConnectionType.casal: EmberColors.brasa,
    ConnectionType.familia: EmberColors.menta,
    ConnectionType.trabalho: EmberColors.sol,
    ConnectionType.outro: EmberColors.neblina,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(myContactsProvider);

    return RetroScaffold(
      top: const RetroTopBar(
        left: 'SUAS',
        right: 'CONEXÕES',
        emblem: Icon(Icons.people_alt_rounded, size: 22),
      ),
      panelPadding: EdgeInsets.zero,
      body: Stack(
        children: [
          contactsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: RetroErrorBox('Erro ao carregar contatos: $e'),
              ),
            ),
            data: (contacts) {
              if (contacts.isEmpty) {
                return RetroEmptyState(
                  illustration: const Icon(
                    Icons.diversity_3_rounded,
                    size: 72,
                    color: EmberColors.lavanda,
                  ),
                  title: 'Nenhuma conexão',
                  message:
                      'Adicione pessoas aqui ou nos rolês — elas aparecem automaticamente.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                itemCount: contacts.length,
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  return Dismissible(
                    key: ValueKey(c.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: EmberColors.brasa,
                        borderRadius:
                            BorderRadius.circular(EmberRetro.raioCard),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.white, size: 24),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) {
                      if (c.id != null) {
                        ref
                            .read(connectionsRepositoryProvider)
                            .deleteContact(c.id!);
                      }
                      ref.invalidate(myContactsProvider);
                    },
                    child: _ContactRow(
                      contact: c,
                      tipoLabel: tipoLabels[c.tipo] ?? 'Outro',
                      tipoCor: tipoCores[c.tipo] ?? EmberColors.neblina,
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: RetroButton(
              shape: RetroButtonShape.pill,
              onPressed: () => _showAddSheet(context, ref),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Nova conexão', style: EmberText.body(14, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final p = RetroPalette.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberRetro.raioCard),
          side: BorderSide(color: p.contorno, width: 3),
        ),
        title: Text('Remover conexão?', style: EmberText.display(20)),
        content: Text(
          'Essa pessoa será removida da sua lista de conexões.',
          style: EmberText.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: EmberText.body(14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remover',
                style: EmberText.body(14, color: EmberColors.brasaTexto)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddContactSheet(
        onSaved: () => ref.invalidate(myContactsProvider),
      ),
    );
  }
}

class _AddContactSheet extends ConsumerStatefulWidget {
  const _AddContactSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _nameCtrl = TextEditingController();
  ConnectionType _tipo = ConnectionType.amigos;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nome = _nameCtrl.text.trim();
    if (nome.isEmpty) {
      setState(() => _error = 'Digite um nome');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(connectionsRepositoryProvider)
          .createContact(nome: nome, tipo: _tipo);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: p.superficie,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: p.contorno, width: 3),
          left: BorderSide(color: p.contorno, width: 3),
          right: BorderSide(color: p.contorno, width: 3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.textoSecundario.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Nova conexão', style: EmberText.display(22)),
          const SizedBox(height: 16),
          RetroFieldLabel('Nome'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Ex.: Maria'),
          ),
          const SizedBox(height: 16),
          RetroFieldLabel('Tipo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ConnectionType.values.map((t) {
              final selected = t == _tipo;
              final label = ConnectionsScreen.tipoLabels[t] ?? t.name;
              final cor =
                  ConnectionsScreen.tipoCores[t] ?? EmberColors.neblina;
              return GestureDetector(
                onTap: () => setState(() => _tipo = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? cor : p.superficie,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? p.contorno : p.linhaSuave,
                      width: selected ? 3 : 2,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: p.contorno,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: EmberText.body(13,
                        color:
                            selected ? EmberColors.tinta : p.textoSecundario,
                        weight:
                            selected ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            RetroErrorBox(_error!),
          ],
          const SizedBox(height: 20),
          RetroButton(
            onPressed: _saving ? null : _save,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  _saving ? 'Salvando...' : 'Adicionar',
                  style: EmberText.body(14, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.tipoLabel,
    required this.tipoCor,
  });

  final Contact contact;
  final String tipoLabel;
  final Color tipoCor;

  @override
  Widget build(BuildContext context) {
    final p = RetroPalette.of(context);
    final initial =
        contact.nome.isNotEmpty ? contact.nome[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RetroCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tipoCor.withAlpha(60),
                shape: BoxShape.circle,
                border: Border.all(color: p.contorno, width: 2),
              ),
              child: Text(
                initial,
                style: EmberText.body(14,
                    color: EmberColors.tinta, weight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                contact.nome,
                style: EmberText.body(15, weight: FontWeight.w700),
              ),
            ),
            RetroTag(tipoLabel, color: tipoCor),
          ],
        ),
      ),
    );
  }
}
