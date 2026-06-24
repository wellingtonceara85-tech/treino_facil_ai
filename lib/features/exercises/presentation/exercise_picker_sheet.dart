import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/exercicio.dart';
import 'exercise_providers.dart';

/// Bottom sheet de busca/seleção de exercício — usado no cadastro de
/// treino. Retorna o [Exercicio] escolhido via `Navigator.pop`.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({super.key});

  static Future<Exercicio?> show(BuildContext context) {
    return showModalBottomSheet<Exercicio>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ExercisePickerSheet(),
    );
  }

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  String _busca = '';
  String? _grupo;

  @override
  Widget build(BuildContext context) {
    final filter = ExerciseFilter(grupoMuscular: _grupo, busca: _busca);
    final exercicios = ref.watch(exerciseListProvider(filter));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adicionar exercício',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar exercício...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _busca = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _GrupoChip(label: 'Todos', selected: _grupo == null, onTap: () => setState(() => _grupo = null)),
                    ...gruposMusculares.map((g) => _GrupoChip(
                          label: g,
                          selected: _grupo == g,
                          onTap: () => setState(() => _grupo = g),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: exercicios.when(
                  data: (lista) => ListView.builder(
                    controller: scrollController,
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final ex = lista[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          title: Text(ex.nome),
                          subtitle: Text('${ex.grupoMuscular} · ${ex.equipamento ?? '—'}'),
                          trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                          onTap: () => Navigator.of(context).pop(ex),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erro ao carregar exercícios: $e')),
                ),
              ),
              TextButton.icon(
                onPressed: () => _criarExercicioCustom(context),
                icon: const Icon(Icons.add),
                label: const Text('Não achei, criar exercício novo'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _criarExercicioCustom(BuildContext context) async {
    final nomeController = TextEditingController();
    String grupo = gruposMusculares.first;

    final criar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Novo exercício'),
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
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Criar')),
          ],
        ),
      ),
    );

    if (criar != true || nomeController.text.trim().isEmpty) return;

    final usuarioId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (usuarioId == null) return;

    final novo = await ref.read(exerciseRepositoryProvider).criar(
          Exercicio(id: '', nome: nomeController.text.trim(), grupoMuscular: grupo),
          usuarioId: usuarioId,
        );

    ref.invalidate(exerciseListProvider);
    if (context.mounted) Navigator.of(context).pop(novo);
  }
}

class _GrupoChip extends StatelessWidget {
  const _GrupoChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
