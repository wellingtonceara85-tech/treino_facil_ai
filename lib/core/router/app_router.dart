import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/profile_screen.dart';
import '../../features/exercises/presentation/my_exercises_screen.dart';
import '../../features/progress/presentation/evolution_screen.dart';
import '../../features/progress/presentation/history_screen.dart';
import '../../features/workouts/presentation/workout_form_screen.dart';
import '../../features/workouts/presentation/workout_session_screen.dart';
import '../../features/workouts/presentation/workouts_list_screen.dart';
import '../../features/workouts/presentation/workout_providers.dart';

/// Provider do GoRouter. Reage ao [authStateProvider] para redirecionar
/// entre /login e o app autenticado (ver docs/03_FLUXO_NAVEGACAO.md).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final estaLogado = authState.valueOrNull != null;
      final vaiParaLogin = state.matchedLocation == '/login';

      if (!estaLogado && !vaiParaLogin) return '/login';
      if (estaLogado && vaiParaLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/treinos',
              builder: (context, state) => const WorkoutsListScreen(),
              routes: [
                GoRoute(
                  path: 'novo',
                  builder: (context, state) => const WorkoutFormScreen(),
                ),
                GoRoute(
                  path: ':id/editar',
                  builder: (context, state) =>
                      WorkoutFormScreen(treinoId: state.pathParameters['id']),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/historico', builder: (context, state) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/perfil',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'exercicios',
                  builder: (context, state) => const MyExercisesScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // Rotas fora da bottom nav (telas "presas"/de fluxo, ver docs):
      GoRoute(
        path: '/treinos/:id/executar',
        builder: (context, state) => _WorkoutSessionLoader(treinoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/evolucao',
        builder: (context, state) => const EvolutionScreen(),
      ),
      GoRoute(
        path: '/evolucao/:exercicioId',
        builder: (context, state) => EvolutionScreen(exercicioIdInicial: state.pathParameters['exercicioId']),
      ),
    ],
  );
});

/// Shell com bottom navigation — mantém o estado de cada aba ao trocar.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), label: 'Treinos'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

/// Carrega o Treino completo (com exercícios) antes de abrir a tela de
/// execução — go_router só nos dá o `id` pela URL.
class _WorkoutSessionLoader extends ConsumerWidget {
  const _WorkoutSessionLoader({required this.treinoId});
  final String treinoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinoAsync = ref.watch(workoutByIdProvider(treinoId));
    return treinoAsync.when(
      data: (treino) => WorkoutSessionScreen(treino: treino),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro ao carregar treino: $e'))),
    );
  }
}
