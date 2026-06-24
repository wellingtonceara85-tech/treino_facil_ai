import 'package:supabase_flutter/supabase_flutter.dart';

import 'progression_engine.dart';

/// Persiste cada sugestão gerada — auditável, e é o que permitirá no
/// futuro medir "a IA acertou X% das vezes" e refinar as regras (ou
/// treinar um modelo de fato, com dados reais de aceite/rejeição).
class SuggestionRepository {
  SuggestionRepository(this._client);
  final SupabaseClient _client;

  Future<String> registrar({
    required String usuarioId,
    required String exercicioId,
    required String sessaoOrigemId,
    required Sugestao sugestao,
  }) async {
    final row = await _client
        .from('sugestoes_progressao')
        .insert({
          'usuario_id': usuarioId,
          'exercicio_id': exercicioId,
          'sessao_origem_id': sessaoOrigemId,
          'carga_anterior': sugestao.cargaAnterior,
          'carga_sugerida': sugestao.cargaSugerida,
          'tipo_sugestao': sugestao.tipo.name == 'aumentar'
              ? 'aumentar'
              : sugestao.tipo.name == 'reduzir'
                  ? 'reduzir'
                  : 'manter',
          'motivo': sugestao.motivo,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> responder(String sugestaoId, {required bool aceita}) async {
    await _client.from('sugestoes_progressao').update({'aceita': aceita}).eq('id', sugestaoId);
  }
}
