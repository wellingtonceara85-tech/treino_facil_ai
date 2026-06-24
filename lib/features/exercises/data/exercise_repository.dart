import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/exercicio.dart';

abstract class ExerciseRepository {
  Future<List<Exercicio>> listar({String? grupoMuscular, String? busca});

  /// Lista apenas os exercícios criados pela própria usuária (exclui o
  /// catálogo global do sistema) — usado na tela "Meus exercícios".
  Future<List<Exercicio>> listarCustom(String usuarioId);

  Future<Exercicio> criar(Exercicio exercicio, {required String usuarioId});
  Future<void> atualizar(Exercicio exercicio);

  /// Soft delete — preserva o histórico de séries já registradas com
  /// este exercício, apenas o remove das listas/buscas futuras.
  Future<void> desativar(String exercicioId);
}

class SupabaseExerciseRepository implements ExerciseRepository {
  SupabaseExerciseRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Exercicio>> listar({String? grupoMuscular, String? busca}) async {
    var query = _client.from('exercicios').select().eq('ativo', true);

    if (grupoMuscular != null && grupoMuscular.isNotEmpty) {
      query = query.eq('grupo_muscular', grupoMuscular);
    }
    if (busca != null && busca.isNotEmpty) {
      query = query.ilike('nome', '%$busca%');
    }

    final rows = await query.order('nome');
    return rows.map((row) => Exercicio.fromMap(row)).toList();
  }

  @override
  Future<List<Exercicio>> listarCustom(String usuarioId) async {
    final rows = await _client
        .from('exercicios')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('ativo', true)
        .order('nome');
    return rows.map((row) => Exercicio.fromMap(row)).toList();
  }

  @override
  Future<Exercicio> criar(Exercicio exercicio, {required String usuarioId}) async {
    final row = await _client
        .from('exercicios')
        .insert(exercicio.toInsertMap(usuarioId: usuarioId))
        .select()
        .single();
    return Exercicio.fromMap(row);
  }

  @override
  Future<void> atualizar(Exercicio exercicio) async {
    await _client.from('exercicios').update({
      'nome': exercicio.nome,
      'grupo_muscular': exercicio.grupoMuscular,
      'equipamento': exercicio.equipamento,
      'observacoes': exercicio.observacoes,
    }).eq('id', exercicio.id);
  }

  @override
  Future<void> desativar(String exercicioId) async {
    await _client.from('exercicios').update({'ativo': false}).eq('id', exercicioId);
  }
}
