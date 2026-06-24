import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/exercise_repository.dart';
import '../domain/exercicio.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return SupabaseExerciseRepository(ref.watch(supabaseClientProvider));
});

class ExerciseFilter {
  const ExerciseFilter({this.grupoMuscular, this.busca});
  final String? grupoMuscular;
  final String? busca;
}

final exerciseListProvider =
    FutureProvider.family<List<Exercicio>, ExerciseFilter>((ref, filter) {
  return ref
      .watch(exerciseRepositoryProvider)
      .listar(grupoMuscular: filter.grupoMuscular, busca: filter.busca);
});

/// Exercícios criados pela própria usuária (tela "Meus exercícios").
final customExerciseListProvider = FutureProvider<List<Exercicio>>((ref) {
  final usuarioId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (usuarioId == null) return Future.value([]);
  return ref.watch(exerciseRepositoryProvider).listarCustom(usuarioId);
});
