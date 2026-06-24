import '../../exercises/domain/exercicio.dart';

/// Um exercício dentro de um treino, com as metas daquele exercício
/// (séries, faixa de repetições, carga inicial, descanso).
class TreinoExercicio {
  const TreinoExercicio({
    required this.id,
    required this.treinoId,
    required this.exercicio,
    required this.ordem,
    this.seriesAlvo = 3,
    this.repeticoesAlvoMin = 8,
    this.repeticoesAlvoMax = 12,
    this.cargaInicial,
    this.incrementoSugerido = 2.5,
    this.tempoDescansoSegundos = 90,
    this.observacoes,
  });

  final String id;
  final String treinoId;
  final Exercicio exercicio;
  final int ordem;
  final int seriesAlvo;
  final int repeticoesAlvoMin;
  final int repeticoesAlvoMax;
  final double? cargaInicial;
  final double incrementoSugerido;
  final int tempoDescansoSegundos;
  final String? observacoes;

  factory TreinoExercicio.fromMap(Map<String, dynamic> map) {
    return TreinoExercicio(
      id: map['id'] as String,
      treinoId: map['treino_id'] as String,
      exercicio: Exercicio.fromMap(map['exercicios'] as Map<String, dynamic>),
      ordem: map['ordem'] as int,
      seriesAlvo: map['series_alvo'] as int? ?? 3,
      repeticoesAlvoMin: map['repeticoes_alvo_min'] as int? ?? 8,
      repeticoesAlvoMax: map['repeticoes_alvo_max'] as int? ?? 12,
      cargaInicial: (map['carga_inicial'] as num?)?.toDouble(),
      incrementoSugerido: (map['incremento_sugerido'] as num?)?.toDouble() ?? 2.5,
      tempoDescansoSegundos: map['tempo_descanso_segundos'] as int? ?? 90,
      observacoes: map['observacoes'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap({required String treinoId}) {
    return {
      'treino_id': treinoId,
      'exercicio_id': exercicio.id,
      'ordem': ordem,
      'series_alvo': seriesAlvo,
      'repeticoes_alvo_min': repeticoesAlvoMin,
      'repeticoes_alvo_max': repeticoesAlvoMax,
      'carga_inicial': cargaInicial,
      'incremento_sugerido': incrementoSugerido,
      'tempo_descanso_segundos': tempoDescansoSegundos,
      'observacoes': observacoes,
    };
  }
}

/// Um treino cadastrado (ex: "Treino A — Peito/Tríceps"), com a lista de
/// exercícios e suas metas. É o "molde" — a execução real fica em
/// `SessaoTreino`.
class Treino {
  const Treino({
    required this.id,
    required this.usuarioId,
    required this.nome,
    this.descricao,
    this.ordem = 0,
    this.ativo = true,
    this.exercicios = const [],
  });

  final String id;
  final String usuarioId;
  final String nome;
  final String? descricao;
  final int ordem;
  final bool ativo;
  final List<TreinoExercicio> exercicios;

  factory Treino.fromMap(Map<String, dynamic> map) {
    final exerciciosRaw = map['treino_exercicios'] as List<dynamic>? ?? [];
    final exercicios = exerciciosRaw
        .map((e) => TreinoExercicio.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    return Treino(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      ordem: map['ordem'] as int? ?? 0,
      ativo: map['ativo'] as bool? ?? true,
      exercicios: exercicios,
    );
  }

  Map<String, dynamic> toInsertMap({required String usuarioId}) {
    return {
      'usuario_id': usuarioId,
      'criado_por': usuarioId,
      'nome': nome,
      'descricao': descricao,
      'ordem': ordem,
    };
  }
}
