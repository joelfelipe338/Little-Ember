import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plan_repository.dart';
import '../domain/plan.dart';
import '../domain/plan_member.dart';
import '../domain/time_option.dart';
import '../domain/time_vote.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

final myPlansProvider = FutureProvider<List<Plan>>((ref) {
  return ref.watch(planRepositoryProvider).getMyPlans();
});

final planProvider = FutureProvider.autoDispose.family<Plan?, String>((ref, planId) {
  return ref.watch(planRepositoryProvider).getPlan(planId);
});

final planOptionsProvider = FutureProvider.autoDispose.family<List<TimeOption>, String>((ref, planId) {
  return ref.watch(planRepositoryProvider).getTimeOptions(planId);
});

final myMemberProvider = FutureProvider.autoDispose.family<PlanMember?, String>((ref, planId) {
  return ref.watch(planRepositoryProvider).getMyMemberIfAny(planId);
});

/// Rolê pelo código do link, para a página do convidado.
final planBySlugProvider = FutureProvider.autoDispose.family<Plan?, String>((ref, slug) {
  return ref.watch(planRepositoryProvider).getPlanBySlug(slug);
});

/// Galera do rolê, atualizada ao vivo.
final planMembersProvider = StreamProvider.autoDispose.family<List<PlanMember>, String>((ref, planId) {
  return ref.watch(planRepositoryProvider).watchMembers(planId);
});

/// Votos de todas as opções do rolê, atualizados ao vivo.
final planVotesProvider = StreamProvider.autoDispose.family<List<TimeVote>, String>((ref, planId) async* {
  final options = await ref.watch(planOptionsProvider(planId).future);
  yield* ref.watch(planRepositoryProvider).watchVotes([for (final o in options) o.id!]);
});
