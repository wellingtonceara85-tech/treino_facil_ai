import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'workout_providers.dart';

class WorkoutsListScreen extends ConsumerWidget {
  const WorkoutsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinos = ref.watch(workoutListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus treinos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/treinos/novo'),
          ),
        ],
      ),
      body: treinos.when(
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Você ainda não tem treinos cadastrados.'),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => context.push('/treinos/novo'),
                      child: const Text('Criar meu primeiro treino'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final treino = lista[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(treino.nome,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${treino.exercicios.length} exercícios',
                                style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push('/treinos/${treino.id}/editar'),
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => context.push('/treinos/${treino.id}/executar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar treinos: $e')),
      ),
    );
  }
}
