import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../exercises/presentation/exercise_picker_sheet.dart';
import '../domain/treino.dart';
import 'workout_providers.dart';

/// Formulário de treino. Se [treinoId] for informado, carrega o treino
/// existente para edição; caso contrário, cria um novo.
class WorkoutFormScreen extends ConsumerStatefulWidget {
  const WorkoutFormScreen({super.key, this.treinoId});

  final String? treinoId;

  @override
  ConsumerState<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends ConsumerState<WorkoutFormScreen> {
  final _nomeController = TextEditingController();
  final List<TreinoExercicio> _exercicios = [];
  bool _carregado = false;
  bool _salvando = false;

  bool get _editando => widget.treinoId != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      Future.microtask(() async {
        final treino = await ref.read(workoutByIdProvider(widget.treinoId!).future);
        _nomeController.text = treino.nome;
        setState(() {
          _exercicios.addAll(treino.exercicios);
          _carregado = true;
        });
      });
    } else {
      _carregado = true;
    }
  }

  Future<void> _adicionarExercicio() async {
    final exercicio = await ExercisePickerSheet.show(context);
    if (exercicio == null) return;

    setState(() {
      _exercicios.add(TreinoExercicio(
        id: '',
        treinoId: widget.treinoId ?? '',
        exercicio: exercicio,
        ordem: _exercicios.length,
      ));
    });
  }

  Future<void> _editarMetasExercicio(int index) async {
    final atual = _exercicios[index];
    final seriesController = TextEditingController(text: atual.seriesAlvo.toString());
    final repMinController = TextEditingController(text: atual.repeticoesAlvoMin.toString());
    final repMaxController = TextEditingController(text: atual.repeticoesAlvoMax.toString());
    final cargaController = TextEditingController(text: (atual.cargaInicial ?? 0).toString());
    final descansoController = TextEditingController(text: atual.tempoDescansoSegundos.toString());

    final salvar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(atual.exercicio.nome),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Séries'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps mín.'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: repMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps máx.'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: cargaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Carga inicial (kg)'),
              ),
              TextField(
                controller: descansoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Descanso (segundos)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salvar')),
        ],
      ),
    );

    if (salvar != true) return;

    setState(() {
      _exercicios[index] = TreinoExercicio(
        id: atual.id,
        treinoId: atual.treinoId,
        exercicio: atual.exercicio,
        ordem: atual.ordem,
        seriesAlvo: int.tryParse(seriesController.text) ?? atual.seriesAlvo,
        repeticoesAlvoMin: int.tryParse(repMinController.text) ?? atual.repeticoesAlvoMin,
        repeticoesAlvoMax: int.tryParse(repMaxController.text) ?? atual.repeticoesAlvoMax,
        cargaInicial: double.tryParse(cargaController.text) ?? atual.cargaInicial,
        incrementoSugerido: atual.incrementoSugerido,
        tempoDescansoSegundos: int.tryParse(descansoController.text) ?? atual.tempoDescansoSegundos,
        observacoes: atual.observacoes,
      );
    });
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome para o treino.')),
      );
      return;
    }
    if (_exercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um exercício.')),
      );
      return;
    }

    final usuarioId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (usuarioId == null) return;

    setState(() => _salvando = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      if (_editando) {
        await repo.atualizar(
          Treino(id: widget.treinoId!, usuarioId: usuarioId, nome: _nomeController.text.trim()),
          _exercicios,
        );
      } else {
        await repo.criar(
          Treino(id: '', usuarioId: usuarioId, nome: _nomeController.text.trim()),
          _exercicios,
        );
      }
      ref.invalidate(workoutListProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar treino' : 'Novo treino')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do treino'),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Exercícios', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _exercicios.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _exercicios.removeAt(oldIndex);
                    _exercicios.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final e = _exercicios[index];
                  return Card(
                    key: ValueKey(e.exercicio.id + index.toString()),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(e.exercicio.nome),
                      subtitle: Text(
                        '${e.seriesAlvo} séries · ${e.repeticoesAlvoMin}-${e.repeticoesAlvoMax} reps'
                        '${e.cargaInicial != null ? ' · ${e.cargaInicial}kg' : ''}',
                      ),
                      onTap: () => _editarMetasExercicio(index),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _exercicios.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: _adicionarExercicio,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar exercício'),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(label: 'Salvar treino', isLoading: _salvando, onPressed: _salvar),
          ],
        ),
      ),
    );
  }
}
