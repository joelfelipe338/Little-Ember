import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plan_repository.dart';
import '../domain/plan.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

final myPlansProvider = FutureProvider<List<Plan>>((ref) {
  return ref.watch(planRepositoryProvider).getMyPlans();
});
