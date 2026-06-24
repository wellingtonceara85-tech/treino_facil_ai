import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/workout_repository.dart';
import '../domain/treino.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return SupabaseWorkoutRepository(ref.watch(supabaseClientProvider));
});

final workoutListProvider = FutureProvider<List<Treino>>((ref) async {
  final usuarioId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (usuarioId == null) return [];
  return ref.watch(workoutRepositoryProvider).listar(usuarioId);
});

final workoutByIdProvider = FutureProvider.family<Treino, String>((ref, treinoId) {
  return ref.watch(workoutRepositoryProvider).buscarPorId(treinoId);
});
