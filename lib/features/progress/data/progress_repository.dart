import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/sessao_treino.dart';

/// Ponto de uma série antiga, usado tanto pelo gráfico de evolução quanto
/// pelo motor de sugestão de progressão (ai_suggestion).
class RegistroHistorico {
  const RegistroHistorico({
    required this.sessaoId,
    required this.data,
    required this.carga,
    required this.repeticoes,
    required this.feedback,
  });

  final String sessaoId;
  final DateTime data;
  final double carga;
  final int repeticoes;
  final String feedback;
}

abstract class ProgressRepository {
  Future<SessaoTreino> iniciarSessao({required String usuarioId, required String treinoId});
  Future<SerieRegistrada> registrarSerie(SerieRegistrada serie);
  Future<void> concluirSessao(String sessaoId);
  Future<void> abandonarSessao(String sessaoId);

  Future<List<SessaoTreino>> historico(String usuarioId, {int limite = 30});

  /// Últimas N séries de um exercício específico, mais recente primeiro.
  /// É o dado de entrada do [ProgressionEngine].
  Future<List<RegistroHistorico>> historicoPorExercicio(
    String usuarioId,
    String exercicioId, {
    int limite = 12,
  });
}

class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<SessaoTreino> iniciarSessao({required String usuarioId, required String treinoId}) async {
    final row = await _client
        .from('sessoes_treino')
        .insert({'usuario_id': usuarioId, 'treino_id': treinoId})
        .select()
        .single();
    return SessaoTreino.fromMap(row);
  }

  @override
  Future<SerieRegistrada> registrarSerie(SerieRegistrada serie) async {
    final row = await _client
        .from('series_registradas')
        .insert(serie.toInsertMap())
        .select()
        .single();
    return SerieRegistrada.fromMap(row);
  }

  @override
  Future<void> concluirSessao(String sessaoId) async {
    await _client.from('sessoes_treino').update({
      'status': 'concluida',
      'data_fim': DateTime.now().toIso8601String(),
    }).eq('id', sessaoId);
  }

  @override
  Future<void> abandonarSessao(String sessaoId) async {
    await _client.from('sessoes_treino').update({
      'status': 'abandonada',
      'data_fim': DateTime.now().toIso8601String(),
    }).eq('id', sessaoId);
  }

  @override
  Future<List<SessaoTreino>> historico(String usuarioId, {int limite = 30}) async {
    final rows = await _client
        .from('sessoes_treino')
        .select('*, treinos(nome), series_registradas(*)')
        .eq('usuario_id', usuarioId)
        .eq('status', 'concluida')
        .order('data_inicio', ascending: false)
        .limit(limite);
    return rows.map((r) => SessaoTreino.fromMap(r)).toList();
  }

  @override
  Future<List<RegistroHistorico>> historicoPorExercicio(
    String usuarioId,
    String exercicioId, {
    int limite = 12,
  }) async {
    final rows = await _client
        .from('series_registradas')
        .select('sessao_id, carga, repeticoes, feedback, criado_em, sessoes_treino!inner(usuario_id)')
        .eq('exercicio_id', exercicioId)
        .eq('sessoes_treino.usuario_id', usuarioId)
        .order('criado_em', ascending: false)
        .limit(limite);

    return rows
        .map((r) => RegistroHistorico(
              sessaoId: r['sessao_id'] as String,
              data: DateTime.parse(r['criado_em'] as String),
              carga: (r['carga'] as num).toDouble(),
              repeticoes: r['repeticoes'] as int,
              feedback: r['feedback'] as String,
            ))
        .toList();
  }
}
