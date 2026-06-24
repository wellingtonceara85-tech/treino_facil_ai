import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import 'progress_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historico = ref.watch(historyProvider);
    final formatoData = DateFormat('EEE, dd/MMM', 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Ver evolução',
            onPressed: () => context.push('/evolucao'),
          ),
        ],
      ),
      body: historico.when(
        data: (sessoes) {
          if (sessoes.isEmpty) {
            return const Center(child: Text('Nenhum treino concluído ainda.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: sessoes.length,
            itemBuilder: (context, index) {
              final s = sessoes[index];
              final duracaoMin = s.duracao?.inMinutes ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(s.nomeTreino ?? 'Treino'),
                  subtitle: Text(formatoData.format(s.dataInicio)),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$duracaoMin min', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${s.volumeTotal.toStringAsFixed(0)} kg',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar histórico: $e')),
      ),
    );
  }
}
