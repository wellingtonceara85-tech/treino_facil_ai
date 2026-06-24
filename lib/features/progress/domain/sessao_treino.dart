/// Feedback subjetivo da usuária sobre como foi a série — entrada
/// principal do motor de sugestão de progressão (ver ai_suggestion).
enum FeedbackSerie { muitoFacil, facil, normal, dificil, falhou }

extension FeedbackSerieX on FeedbackSerie {
  String get valorBanco => switch (this) {
        FeedbackSerie.muitoFacil => 'muito_facil',
        FeedbackSerie.facil => 'facil',
        FeedbackSerie.normal => 'normal',
        FeedbackSerie.dificil => 'dificil',
        FeedbackSerie.falhou => 'falhou',
      };

  String get emoji => switch (this) {
        FeedbackSerie.muitoFacil => '😎',
        FeedbackSerie.facil => '🙂',
        FeedbackSerie.normal => '😐',
        FeedbackSerie.dificil => '😅',
        FeedbackSerie.falhou => '💥',
      };

  String get label => switch (this) {
        FeedbackSerie.muitoFacil => 'Muito fácil',
        FeedbackSerie.facil => 'Fácil',
        FeedbackSerie.normal => 'Normal',
        FeedbackSerie.dificil => 'Difícil',
        FeedbackSerie.falhou => 'Falhei',
      };

  static FeedbackSerie fromBanco(String valor) {
    return FeedbackSerie.values.firstWhere(
      (f) => f.valorBanco == valor,
      orElse: () => FeedbackSerie.normal,
    );
  }
}

class SerieRegistrada {
  const SerieRegistrada({
    required this.id,
    required this.sessaoId,
    required this.treinoExercicioId,
    required this.exercicioId,
    required this.numeroSerie,
    required this.carga,
    required this.repeticoes,
    required this.feedback,
    this.falhouSerie = false,
    this.criadoEm,
  });

  final String id;
  final String sessaoId;
  final String treinoExercicioId;
  final String exercicioId;
  final int numeroSerie;
  final double carga;
  final int repeticoes;
  final FeedbackSerie feedback;
  final bool falhouSerie;
  final DateTime? criadoEm;

  factory SerieRegistrada.fromMap(Map<String, dynamic> map) {
    return SerieRegistrada(
      id: map['id'] as String,
      sessaoId: map['sessao_id'] as String,
      treinoExercicioId: map['treino_exercicio_id'] as String,
      exercicioId: map['exercicio_id'] as String,
      numeroSerie: map['numero_serie'] as int,
      carga: (map['carga'] as num).toDouble(),
      repeticoes: map['repeticoes'] as int,
      feedback: FeedbackSerieX.fromBanco(map['feedback'] as String),
      falhouSerie: map['falhou_serie'] as bool? ?? false,
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'sessao_id': sessaoId,
      'treino_exercicio_id': treinoExercicioId,
      'exercicio_id': exercicioId,
      'numero_serie': numeroSerie,
      'carga': carga,
      'repeticoes': repeticoes,
      'feedback': feedback.valorBanco,
      'falhou_serie': falhouSerie,
    };
  }
}

class SessaoTreino {
  const SessaoTreino({
    required this.id,
    required this.usuarioId,
    required this.treinoId,
    required this.dataInicio,
    this.dataFim,
    this.status = 'em_andamento',
    this.series = const [],
    this.nomeTreino,
  });

  final String id;
  final String usuarioId;
  final String treinoId;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String status; // em_andamento | concluida | abandonada
  final List<SerieRegistrada> series;
  final String? nomeTreino;

  Duration? get duracao =>
      dataFim != null ? dataFim!.difference(dataInicio) : null;

  double get volumeTotal =>
      series.fold(0, (total, s) => total + (s.carga * s.repeticoes));

  factory SessaoTreino.fromMap(Map<String, dynamic> map) {
    final seriesRaw = map['series_registradas'] as List<dynamic>? ?? [];
    return SessaoTreino(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String,
      treinoId: map['treino_id'] as String,
      dataInicio: DateTime.parse(map['data_inicio'] as String),
      dataFim: map['data_fim'] != null ? DateTime.parse(map['data_fim'] as String) : null,
      status: map['status'] as String? ?? 'em_andamento',
      series: seriesRaw.map((s) => SerieRegistrada.fromMap(s as Map<String, dynamic>)).toList(),
      nomeTreino: (map['treinos'] as Map<String, dynamic>?)?['nome'] as String?,
    );
  }
}
