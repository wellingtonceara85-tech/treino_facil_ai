import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/number_stepper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../ai_suggestion/presentation/suggestion_card_widget.dart';
import '../../progress/domain/sessao_treino.dart';
import '../../timer/presentation/rest_timer_widget.dart';
import '../domain/treino.dart';
import 'workout_session_controller.dart';

class WorkoutSessionScreen extends ConsumerWidget {
  const WorkoutSessionScreen({super.key, required this.treino});

  final Treino treino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutSessionControllerProvider(treino));
    final controller = ref.read(workoutSessionControllerProvider(treino).notifier);

    if (state.carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.fase == FaseSessao.finalizada) {
      return _TelaConclusao(state: state, controller: controller);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sair do treino?'),
            content: const Text('O progresso desta sessão será descartado.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Continuar treino')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sair')),
            ],
          ),
        );
        if (confirmar == true) {
          await controller.abandonar();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(treino.nome)),
        body: Stack(
          children: [
            _TelaExecucao(state: state, controller: controller),
            if (state.fase == FaseSessao.descansando)
              RestTimerOverlay(
                segundosIniciais: state.exercicioAtual.tempoDescansoSegundos,
                onFinalizado: controller.finalizarDescanso,
              ),
          ],
        ),
      ),
    );
  }
}

class _TelaExecucao extends StatelessWidget {
  const _TelaExecucao({required this.state, required this.controller});

  final WorkoutSessionState state;
  final WorkoutSessionController controller;

  @override
  Widget build(BuildContext context) {
    final exercicio = state.exercicioAtual;
    final progressoTreino = (state.exercicioIndex + 1) / state.treino.exercicios.length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exercício ${state.exercicioIndex + 1} de ${state.treino.exercicios.length}',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progressoTreino, minHeight: 6),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(exercicio.exercicio.nome,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Meta: ${exercicio.seriesAlvo}x${exercicio.repeticoesAlvoMin}-${exercicio.repeticoesAlvoMax}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Série ${state.numeroSerie} de ${exercicio.seriesAlvo}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.lg),
          NumberStepper(
            label: 'Carga (kg)',
            value: state.carga,
            onIncrement: () => controller.ajustarCarga(2.5),
            onDecrement: () => controller.ajustarCarga(-2.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          NumberStepper(
            label: 'Repetições',
            value: state.repeticoes.toDouble(),
            valueFormatter: (v) => v.toInt().toString(),
            onIncrement: () => controller.ajustarRepeticoes(1),
            onDecrement: () => controller.ajustarRepeticoes(-1),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Como foi essa série?', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: FeedbackSerie.values.map((f) {
              final selecionado = state.feedback == f;
              return ChoiceChip(
                label: Text('${f.emoji} ${f.label}'),
                selected: selecionado,
                onSelected: (_) => controller.definirFeedback(f),
              );
            }).toList(),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Concluir série',
            icon: Icons.check,
            onPressed: controller.concluirSerie,
          ),
        ],
      ),
    );
  }
}

class _TelaConclusao extends StatelessWidget {
  const _TelaConclusao({required this.state, required this.controller});

  final WorkoutSessionState state;
  final WorkoutSessionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const Text('Treino concluído! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.lg),
              const Text('Sugestões para a próxima vez', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: state.sugestoes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final s = state.sugestoes[index];
                    return SuggestionCard(
                      nomeExercicio: s.nomeExercicio,
                      sugestao: s.sugestao,
                      onAceitar: () => controller.responderSugestao(s.sugestaoId, true),
                      onIgnorar: () => controller.responderSugestao(s.sugestaoId, false),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () => context.go('/'),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
