import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final isLoggedInProvider = Provider<bool>((ref) {
  final session = ref.watch(authRepositoryProvider).currentSession;
  return session != null;
});

final profileProvider = AsyncNotifierProvider<ProfileNotifier, AppUser?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final authRepo = ref.watch(authRepositoryProvider);

    ref.listen(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn ||
            authState.event == AuthChangeEvent.tokenRefreshed) {
          ref.invalidateSelf();
        }
        if (authState.event == AuthChangeEvent.signedOut) {
          state = const AsyncData(null);
        }
      });
    });

    return authRepo.getProfile();
  }

  Future<void> updateProfile({
    String? nome,
    String? avatarUrl,
    String? fuso,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.updateProfile(nome: nome, avatarUrl: avatarUrl, fuso: fuso);
    ref.invalidateSelf();
  }
}
