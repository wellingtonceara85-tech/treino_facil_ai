import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../workouts/presentation/workout_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final treinos = ref.watch(workoutListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Oi, ${user?.nome.split(' ').first ?? ''} 👋'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/perfil')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(workoutListProvider),
        child: treinos.when(
          data: (lista) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (lista.isNotEmpty) ...[
                  PrimaryButton(
                    label: 'Iniciar treino · ${lista.first.nome}',
                    icon: Icons.play_arrow,
                    onPressed: () => context.push('/treinos/${lista.first.id}/executar'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text('Meus treinos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                if (lista.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          const Text('Você ainda não tem treinos.'),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton(
                            onPressed: () => context.push('/treinos/novo'),
                            child: const Text('Criar meu primeiro treino'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: lista.length + 1,
                    itemBuilder: (context, index) {
                      if (index == lista.length) {
                        return _CardNovoTreino(onTap: () => context.push('/treinos/novo'));
                      }
                      final treino = lista[index];
                      return _CardTreino(
                        nome: treino.nome,
                        quantidade: treino.exercicios.length,
                        onTap: () => context.push('/treinos/${treino.id}/executar'),
                      );
                    },
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro ao carregar treinos: $e')),
        ),
      ),
    );
  }
}

class _CardTreino extends StatelessWidget {
  const _CardTreino({required this.nome, required this.quantidade, required this.onTap});
  final String nome;
  final int quantidade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('$quantidade exercícios', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardNovoTreino extends StatelessWidget {
  const _CardNovoTreino({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.background,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.primary),
              SizedBox(height: 4),
              Text('Novo treino'),
            ],
          ),
        ),
      ),
    );
  }
}
