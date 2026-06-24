import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/exercicio.dart';
import 'exercise_providers.dart';

/// Tela "Meus exercícios" — lista apenas exercícios criados pela própria
/// usuária (o catálogo global do sistema não é editável aqui).
class MyExercisesScreen extends ConsumerWidget {
  const MyExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercicios = ref.watch(customExerciseListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus exercícios')),
      body: exercicios.when(
        data: (lista) {
          if (lista.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'Você ainda não criou exercícios personalizados.\n'
                  'Eles aparecem aqui quando você cria um novo exercício '
                  'ao montar um treino.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final ex = lista[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(ex.nome),
                  subtitle: Text('${ex.grupoMuscular}${ex.equipamento != null ? ' · ${ex.equipamento}' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editar(context, ref, ex),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _confirmarExclusao(context, ref, ex),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar exercícios: $e')),
      ),
    );
  }

  Future<void> _editar(BuildContext context, WidgetRef ref, Exercicio exercicio) async {
    final nomeController = TextEditingController(text: exercicio.nome);
    String grupo = exercicio.grupoMuscular;

    final salvar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Editar exercício'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do exercício'),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: grupo,
                items: gruposMusculares
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setStateDialog(() => grupo = v ?? grupo),
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (salvar != true || nomeController.text.trim().isEmpty) return;

    await ref.read(exerciseRepositoryProvider).atualizar(
          Exercicio(
            id: exercicio.id,
            usuarioId: exercicio.usuarioId,
            nome: nomeController.text.trim(),
            grupoMuscular: grupo,
            equipamento: exercicio.equipamento,
            observacoes: exercicio.observacoes,
          ),
        );
    ref.invalidate(customExerciseListProvider);
    ref.invalidate(exerciseListProvider);
  }

  Future<void> _confirmarExclusao(BuildContext context, WidgetRef ref, Exercicio exercicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover exercício?'),
        content: Text(
          'Remover "${exercicio.nome}" da sua lista. Treinos e histórico que já '
          'usam este exercício continuam intactos.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await ref.read(exerciseRepositoryProvider).desativar(exercicio.id);
    ref.invalidate(customExerciseListProvider);
    ref.invalidate(exerciseListProvider);
  }
}
