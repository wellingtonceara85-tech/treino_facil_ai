import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/treino.dart';

abstract class WorkoutRepository {
  Future<List<Treino>> listar(String usuarioId);
  Future<Treino> buscarPorId(String treinoId);
  Future<Treino> criar(Treino treino, List<TreinoExercicio> exercicios);
  Future<void> atualizar(Treino treino, List<TreinoExercicio> exercicios);
  Future<void> excluir(String treinoId);
}

const _selectComExercicios = '*, treino_exercicios(*, exercicios(*))';

class SupabaseWorkoutRepository implements WorkoutRepository {
  SupabaseWorkoutRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Treino>> listar(String usuarioId) async {
    final rows = await _client
        .from('treinos')
        .select(_selectComExercicios)
        .eq('usuario_id', usuarioId)
        .eq('ativo', true)
        .order('ordem');
    return rows.map((r) => Treino.fromMap(r)).toList();
  }

  @override
  Future<Treino> buscarPorId(String treinoId) async {
    final row = await _client
        .from('treinos')
        .select(_selectComExercicios)
        .eq('id', treinoId)
        .single();
    return Treino.fromMap(row);
  }

  @override
  Future<Treino> criar(Treino treino, List<TreinoExercicio> exercicios) async {
    final treinoRow = await _client
        .from('treinos')
        .insert(treino.toInsertMap(usuarioId: treino.usuarioId))
        .select()
        .single();

    final treinoId = treinoRow['id'] as String;

    if (exercicios.isNotEmpty) {
      await _client.from('treino_exercicios').insert(
            exercicios.map((e) => e.toInsertMap(treinoId: treinoId)).toList(),
          );
    }

    return buscarPorId(treinoId);
  }

  @override
  Future<void> atualizar(Treino treino, List<TreinoExercicio> exercicios) async {
    await _client.from('treinos').update({
      'nome': treino.nome,
      'descricao': treino.descricao,
    }).eq('id', treino.id);

    // Estratégia simples e segura para v1: substitui todos os exercícios
    // do treino (delete + insert). Para listas grandes/edição frequente,
    // uma estratégia de diff seria mais eficiente — não necessária aqui.
    await _client.from('treino_exercicios').delete().eq('treino_id', treino.id);
    if (exercicios.isNotEmpty) {
      await _client.from('treino_exercicios').insert(
            exercicios.map((e) => e.toInsertMap(treinoId: treino.id)).toList(),
          );
    }
  }

  @override
  Future<void> excluir(String treinoId) async {
    // Soft delete — preserva histórico de sessões já realizadas com este treino.
    await _client.from('treinos').update({'ativo': false}).eq('id', treinoId);
  }
}
