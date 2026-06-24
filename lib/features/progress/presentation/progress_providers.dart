import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/progress_repository.dart';
import '../domain/sessao_treino.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return SupabaseProgressRepository(ref.watch(supabaseClientProvider));
});

final historyProvider = FutureProvider<List<SessaoTreino>>((ref) async {
  final usuarioId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (usuarioId == null) return [];
  return ref.watch(progressRepositoryProvider).historico(usuarioId);
});

final exerciseHistoryProvider =
    FutureProvider.family<List<RegistroHistorico>, String>((ref, exercicioId) async {
  final usuarioId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (usuarioId == null) return [];
  return ref.watch(progressRepositoryProvider).historicoPorExercicio(usuarioId, exercicioId, limite: 50);
});
