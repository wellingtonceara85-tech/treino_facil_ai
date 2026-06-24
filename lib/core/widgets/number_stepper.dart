import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stepper numérico de toque único, usado para ajustar carga e repetições
/// durante a execução do treino. Deliberadamente grande: a usuária está
/// no meio da série, sem tempo/paciência para digitar em um teclado.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.suffix = '',
    this.valueFormatter,
  });

  final String label;
  final double value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String suffix;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final displayValue = valueFormatter?.call(value) ?? value.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            _StepButton(icon: Icons.remove, onTap: onDecrement),
            Expanded(
              child: Center(
                child: Text(
                  '$displayValue$suffix',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _StepButton(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 28),
        ),
      ),
    );
  }
}
