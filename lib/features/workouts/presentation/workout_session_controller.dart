import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_suggestion/domain/progression_engine.dart';
import '../../ai_suggestion/presentation/suggestion_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../progress/domain/sessao_treino.dart';
import '../../progress/presentation/progress_providers.dart';
import '../domain/treino.dart';

enum FaseSessao { executando, descansando, finalizada }

class SugestaoComContexto {
  const SugestaoComContexto({
    required this.sugestaoId,
    required this.nomeExercicio,
    required this.sugestao,
  });

  final String sugestaoId;
  final String nomeExercicio;
  final Sugestao sugestao;
}

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.treino,
    this.sessaoId,
    this.exercicioIndex = 0,
    this.numeroSerie = 1,
    this.carga = 0,
    this.repeticoes = 8,
    this.feedback = FeedbackSerie.normal,
    this.fase = FaseSessao.executando,
    this.sugestoes = const [],
    this.carregando = true,
  });

  final Treino treino;
  final String? sessaoId;
  final int exercicioIndex;
  final int numeroSerie;
  final double carga;
  final int repeticoes;
  final FeedbackSerie feedback;
  final FaseSessao fase;
  final List<SugestaoComContexto> sugestoes;
  final bool carregando;

  TreinoExercicio get exercicioAtual => treino.exercicios[exercicioIndex];
  bool get ultimoExercicio => exercicioIndex == treino.exercicios.length - 1;

  WorkoutSessionState copyWith({
    String? sessaoId,
    int? exercicioIndex,
    int? numeroSerie,
    double? carga,
    int? repeticoes,
    FeedbackSerie? feedback,
    FaseSessao? fase,
    List<SugestaoComContexto>? sugestoes,
    bool? carregando,
  }) {
    return WorkoutSessionState(
      treino: treino,
      sessaoId: sessaoId ?? this.sessaoId,
      exercicioIndex: exercicioIndex ?? this.exercicioIndex,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      carga: carga ?? this.carga,
      repeticoes: repeticoes ?? this.repeticoes,
      feedback: feedback ?? this.feedback,
      fase: fase ?? this.fase,
      sugestoes: sugestoes ?? this.sugestoes,
      carregando: carregando ?? this.carregando,
    );
  }
}

class WorkoutSessionController extends StateNotifier<WorkoutSessionState> {
  WorkoutSessionController(this._ref, Treino treino) : super(WorkoutSessionState(treino: treino)) {
    _iniciar();
  }

  final Ref _ref;

  Future<void> _iniciar() async {
    final usuarioId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (usuarioId == null) return;

    final sessao = await _ref
        .read(progressRepositoryProvider)
        .iniciarSessao(usuarioId: usuarioId, treinoId: state.treino.id);

    state = state.copyWith(
      sessaoId: sessao.id,
      carga: state.exercicioAtual.cargaInicial ?? 0,
      repeticoes: state.exercicioAtual.repeticoesAlvoMin,
      carregando: false,
    );
  }

  void ajustarCarga(double delta) {
    state = state.copyWith(carga: (state.carga + delta).clamp(0, 999).toDouble());
  }

  void ajustarRepeticoes(int delta) {
    state = state.copyWith(repeticoes: (state.repeticoes + delta).clamp(0, 99).toInt());
  }

  void definirFeedback(FeedbackSerie feedback) {
    state = state.copyWith(feedback: feedback);
  }

  Future<void> concluirSerie() async {
    final sessaoId = state.sessaoId;
    if (sessaoId == null) return;

    await _ref.read(progressRepositoryProvider).registrarSerie(
          SerieRegistrada(
            id: '',
            sessaoId: sessaoId,
            treinoExercicioId: state.exercicioAtual.id,
            exercicioId: state.exercicioAtual.exercicio.id,
            numeroSerie: state.numeroSerie,
            carga: state.carga,
            repeticoes: state.repeticoes,
            feedback: state.feedback,
            falhouSerie: state.feedback == FeedbackSerie.falhou,
          ),
        );

    final aindaTemSerie = state.numeroSerie < state.exercicioAtual.seriesAlvo;

    if (aindaTemSerie) {
      state = state.copyWith(numeroSerie: state.numeroSerie + 1, fase: FaseSessao.descansando);
    } else if (!state.ultimoExercicio) {
      final proximoExercicio = state.treino.exercicios[state.exercicioIndex + 1];
      state = state.copyWith(
        exercicioIndex: state.exercicioIndex + 1,
        numeroSerie: 1,
        carga: proximoExercicio.cargaInicial ?? state.carga,
        repeticoes: proximoExercicio.repeticoesAlvoMin,
        feedback: FeedbackSerie.normal,
        fase: FaseSessao.descansando,
      );
    } else {
      await _finalizarSessao();
    }
  }

  void finalizarDescanso() {
    if (state.fase == FaseSessao.descansando) {
      state = state.copyWith(fase: FaseSessao.executando);
    }
  }

  Future<void> _finalizarSessao() async {
    final sessaoId = state.sessaoId;
    final usuarioId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (sessaoId == null || usuarioId == null) return;

    await _ref.read(progressRepositoryProvider).concluirSessao(sessaoId);

    final sugestoes = <SugestaoComContexto>[];
    for (final treinoExercicio in state.treino.exercicios) {
      final historico = await _ref.read(progressRepositoryProvider).historicoPorExercicio(
            usuarioId,
            treinoExercicio.exercicio.id,
          );

      final sugestao = ProgressionEngine.sugerir(
        historicoRecente: historico,
        repeticoesAlvoMin: treinoExercicio.repeticoesAlvoMin,
        repeticoesAlvoMax: treinoExercicio.repeticoesAlvoMax,
        incrementoSugerido: treinoExercicio.incrementoSugerido,
      );

      final sugestaoId = await _ref.read(suggestionRepositoryProvider).registrar(
            usuarioId: usuarioId,
            exercicioId: treinoExercicio.exercicio.id,
            sessaoOrigemId: sessaoId,
            sugestao: sugestao,
          );

      sugestoes.add(SugestaoComContexto(
        sugestaoId: sugestaoId,
        nomeExercicio: treinoExercicio.exercicio.nome,
        sugestao: sugestao,
      ));
    }

    state = state.copyWith(fase: FaseSessao.finalizada, sugestoes: sugestoes);
  }

  Future<void> responderSugestao(String sugestaoId, bool aceita) async {
    await _ref.read(suggestionRepositoryProvider).responder(sugestaoId, aceita: aceita);
  }

  Future<void> abandonar() async {
    final sessaoId = state.sessaoId;
    if (sessaoId != null) {
      await _ref.read(progressRepositoryProvider).abandonarSessao(sessaoId);
    }
  }
}

final workoutSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<WorkoutSessionController, WorkoutSessionState, Treino>((ref, treino) {
  return WorkoutSessionController(ref, treino);
});
