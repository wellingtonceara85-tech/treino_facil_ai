import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Overlay de descanso entre séries. Deliberadamente NÃO é uma rota —
/// fica sobreposto à WorkoutSessionScreen para preservar o estado da
/// sessão (ver docs/03_FLUXO_NAVEGACAO.md, regra 2).
class RestTimerOverlay extends StatefulWidget {
  const RestTimerOverlay({
    super.key,
    required this.segundosIniciais,
    required this.onFinalizado,
  });

  final int segundosIniciais;
  final VoidCallback onFinalizado;

  @override
  State<RestTimerOverlay> createState() => _RestTimerOverlayState();
}

class _RestTimerOverlayState extends State<RestTimerOverlay> {
  late int _segundosRestantes;
  late int _segundosTotais;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _segundosRestantes = widget.segundosIniciais;
    _segundosTotais = widget.segundosIniciais;
    _iniciarContagem();
  }

  void _iniciarContagem() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes <= 0) {
        timer.cancel();
        widget.onFinalizado();
        return;
      }
      setState(() => _segundosRestantes--);
    });
  }

  void _ajustar(int delta) {
    setState(() {
      _segundosRestantes = (_segundosRestantes + delta).clamp(0, 600).toInt();
      _segundosTotais = (_segundosTotais + delta).clamp(_segundosRestantes, 600).toInt();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatar(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progresso = _segundosTotais == 0 ? 0.0 : _segundosRestantes / _segundosTotais;

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Descansa 😌', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: progresso,
                        strokeWidth: 8,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    Text(
                      _formatar(_segundosRestantes),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => _ajustar(-15),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(80, 48)),
                    child: const Text('-15s'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => _ajustar(15),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(80, 48)),
                    child: const Text('+15s'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  widget.onFinalizado();
                },
                child: const Text('Pular descanso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
