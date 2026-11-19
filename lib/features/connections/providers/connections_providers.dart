import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/connections_repository.dart';
import '../domain/brasa.dart';
import '../domain/contact.dart';
import '../domain/contact_group.dart';
import '../domain/link_request.dart';

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository();
});

final myContactsProvider = FutureProvider<List<Contact>>((ref) {
  return ref.watch(connectionsRepositoryProvider).getMyContacts();
});

/// Grupos de conexões (ex.: "Galera do vôlei"), com os IDs de quem está em cada um.
final contactGroupsProvider = FutureProvider<List<ContactGroup>>((ref) {
  return ref.watch(connectionsRepositoryProvider).getMyGroups();
});

/// Último rolê com cada pessoa (brasa). Recalcula quando a lista de conexões muda.
final contactLastPlansProvider = FutureProvider<Map<String, LastPlan>>((ref) async {
  final contacts = await ref.watch(myContactsProvider.future);
  return ref.watch(connectionsRepositoryProvider).getLastPlans([
    for (final c in contacts)
      if (c.id != null) c.id!,
  ]);
});

/// Ordem escolhida na tela de conexões (vale também na seleção pro rolê).
final contactSortProvider = StateProvider<ContactSort>((ref) => ContactSort.nome);

/// Filtro por tipo de relação (null = todos).
final contactTypeFilterProvider = StateProvider<ConnectionType?>((ref) => null);

/// Atualiza tudo que depende das conexões.
void refreshConnections(WidgetRef ref) {
  ref.invalidate(myContactsProvider);
  ref.invalidate(contactGroupsProvider);
  ref.invalidate(pendingLinkRequestsProvider);
}

/// Grupos minimizados na tela de Conexões (fica salvo no aparelho).
final collapsedGroupsProvider =
    StateNotifierProvider<CollapsedGroupsNotifier, Set<String>>((ref) => CollapsedGroupsNotifier());

class CollapsedGroupsNotifier extends StateNotifier<Set<String>> {
  CollapsedGroupsNotifier() : super(const {}) {
    _load();
  }

  static const _key = 'conexoes_grupos_minimizados';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_key);
      if (saved != null && mounted) state = {...saved, ...state};
    } catch (_) {
      // Sem armazenamento local: só não lembra entre aberturas do app.
    }
  }

  bool isCollapsed(String groupId) => state.contains(groupId);

  void toggle(String groupId) {
    state = state.contains(groupId) ? ({...state}..remove(groupId)) : {...state, groupId};
    _save();
  }

  void setAll(Iterable<String> groupIds, {required bool collapsed}) {
    state = collapsed ? {...state, ...groupIds} : ({...state}..removeAll(groupIds));
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.toList());
    } catch (_) {}
  }
}

/// Pedidos de vínculo que chegaram pra mim (aparecem no topo das Conexões).
final pendingLinkRequestsProvider = FutureProvider.autoDispose<List<LinkRequest>>((ref) {
  return ref.watch(connectionsRepositoryProvider).getPendingLinkRequests();
});

/// Situação do meu pedido de vínculo para a conexão de um rolê.
final myLinkStatusProvider = FutureProvider.autoDispose.family<String?, String>((ref, connectionId) {
  return ref.watch(connectionsRepositoryProvider).getMyLinkStatus(connectionId);
});
