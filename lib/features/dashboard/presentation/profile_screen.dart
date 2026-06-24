import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _unidadeCarga;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    // Mantém a escolha local depois do primeiro toque — a stream de auth
    // não re-emite só porque a tabela `profiles` foi atualizada por aqui.
    _unidadeCarga ??= user?.unidadeCarga ?? 'kg';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
            child: user?.avatarUrl == null
                ? Text(
                    (user?.nome.isNotEmpty ?? false) ? user!.nome[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(user?.nome ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          Center(
            child: Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Meus exercícios'),
            subtitle: const Text('Editar ou remover exercícios que você criou'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/perfil/exercicios'),
          ),
          ListTile(
            leading: const Icon(Icons.scale),
            title: const Text('Unidade de carga'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kg', label: Text('Kg')),
                ButtonSegment(value: 'lb', label: Text('Lb')),
              ],
              selected: {_unidadeCarga!},
              onSelectionChanged: (selecionado) {
                final nova = selecionado.first;
                setState(() => _unidadeCarga = nova);
                ref.read(authControllerProvider.notifier).atualizarUnidadeCarga(nova);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o app'),
            onTap: () => _mostrarSobre(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Sair da conta', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _mostrarSobre(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Treino Fácil AI'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versão 0.1.0'),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Registre seus treinos, acompanhe sua evolução e receba '
              'sugestões automáticas de progressão de carga.',
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Suas sugestões de carga vêm de um motor de regras simples '
              'baseado no seu histórico — não de um modelo de IA externo.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
