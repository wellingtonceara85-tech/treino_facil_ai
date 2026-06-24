import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/progression_engine.dart';

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.nomeExercicio,
    required this.sugestao,
    required this.onAceitar,
    required this.onIgnorar,
  });

  final String nomeExercicio;
  final Sugestao sugestao;
  final VoidCallback onAceitar;
  final VoidCallback onIgnorar;

  @override
  Widget build(BuildContext context) {
    final cor = switch (sugestao.tipo) {
      TipoSugestao.aumentar => AppColors.success,
      TipoSugestao.reduzir => AppColors.warning,
      TipoSugestao.manter => AppColors.textSecondary,
    };
    final icone = switch (sugestao.tipo) {
      TipoSugestao.aumentar => Icons.trending_up,
      TipoSugestao.reduzir => Icons.trending_down,
      TipoSugestao.manter => Icons.trending_flat,
    };

    final mudaCarga = sugestao.tipo != TipoSugestao.manter;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(nomeExercicio,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (mudaCarga)
              Text(
                '${sugestao.cargaAnterior.toStringAsFixed(1)} kg → ${sugestao.cargaSugerida.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cor),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(sugestao.motivo, style: const TextStyle(color: AppColors.textSecondary)),
            if (mudaCarga) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onIgnorar, child: const Text('Ignorar')),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton(onPressed: onAceitar, child: const Text('Aceitar')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
