import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/connections_repository.dart';
import '../domain/contact.dart';

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository();
});

final myContactsProvider = FutureProvider<List<Contact>>((ref) {
  return ref.watch(connectionsRepositoryProvider).getMyContacts();
});
