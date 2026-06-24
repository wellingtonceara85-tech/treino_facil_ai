import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../exercises/domain/exercicio.dart';
import '../../exercises/presentation/exercise_providers.dart';
import 'progress_providers.dart';

class EvolutionScreen extends ConsumerStatefulWidget {
  const EvolutionScreen({super.key, this.exercicioIdInicial});

  final String? exercicioIdInicial;

  @override
  ConsumerState<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends ConsumerState<EvolutionScreen> {
  String? _exercicioSelecionadoId;
  Exercicio? _exercicioSelecionado;

  @override
  void initState() {
    super.initState();
    _exercicioSelecionadoId = widget.exercicioIdInicial;
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(exerciseListProvider(const ExerciseFilter()));

    return Scaffold(
      appBar: AppBar(title: const Text('Evolução')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            exerciciosAsync.when(
              data: (exercicios) {
                _exercicioSelecionado ??= exercicios.firstWhere(
                  (e) => e.id == _exercicioSelecionadoId,
                  orElse: () => exercicios.first,
                );
                return DropdownButtonFormField<Exercicio>(
                  initialValue: _exercicioSelecionado,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Exercício'),
                  items: exercicios
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.nome)))
                      .toList(),
                  onChanged: (v) => setState(() => _exercicioSelecionado = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erro: $e'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_exercicioSelecionado != null)
              Expanded(child: _GraficoEvolucao(exercicioId: _exercicioSelecionado!.id)),
          ],
        ),
      ),
    );
  }
}

class _GraficoEvolucao extends ConsumerWidget {
  const _GraficoEvolucao({required this.exercicioId});
  final String exercicioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historicoAsync = ref.watch(exerciseHistoryProvider(exercicioId));

    return historicoAsync.when(
      data: (historico) {
        if (historico.isEmpty) {
          return const Center(child: Text('Ainda não há registros para este exercício.'));
        }

        // historico vem do mais recente para o mais antigo — inverte para o gráfico.
        final pontos = historico.reversed.toList();
        final recorde = historico.reduce((a, b) => a.carga >= b.carga ? a : b);
        final formatoData = DateFormat('dd/MM');

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Carga ao longo do tempo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (pontos.length / 4).clamp(1, pontos.length).floorToDouble(),
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= pontos.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(formatoData.format(pontos[i].data),
                                  style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < pontos.length; i++)
                            FlSpot(i.toDouble(), pontos[i].carga),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recorde pessoal', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              '${recorde.carga.toStringAsFixed(1)} kg · ${recorde.repeticoes} reps',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Text(formatoData.format(recorde.data)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar evolução: $e')),
    );
  }
}
