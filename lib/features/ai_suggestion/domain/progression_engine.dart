import '../../progress/data/progress_repository.dart';

enum TipoSugestao { aumentar, manter, reduzir }

/// Resultado do motor de progressão: o que sugerir, para qual carga, e
/// por quê (a explicação é parte do produto — a usuária precisa confiar
/// na sugestão, não só obedecer).
class Sugestao {
  const Sugestao({
    required this.tipo,
    required this.cargaAnterior,
    required this.cargaSugerida,
    required this.motivo,
  });

  final TipoSugestao tipo;
  final double cargaAnterior;
  final double cargaSugerida;
  final String motivo;
}

/// Motor de regras que decide se a carga de um exercício deve subir,
/// manter ou cair — a "IA" da v1 do Treino Fácil AI.
///
/// Por quê regras e não um modelo treinado? Ver docs/01_ARQUITETURA.md,
/// seção 6: é determinístico, explicável, funciona offline e custa zero
/// de inferência. A interface abaixo foi pensada para, na v2, ser
/// decorada/substituída por uma chamada a um modelo de linguagem (ex.
/// via Supabase Edge Function) sem que `WorkoutSessionScreen` precise
/// mudar — ela só conhece `ProgressionEngine.sugerir(...)`.
class ProgressionEngine {
  /// [historicoRecente] deve vir ordenado do mais recente para o mais
  /// antigo (é o que [ProgressRepository.historicoPorExercicio] retorna).
  static Sugestao sugerir({
    required List<RegistroHistorico> historicoRecente,
    required int repeticoesAlvoMin,
    required int repeticoesAlvoMax,
    required double incrementoSugerido,
  }) {
    if (historicoRecente.isEmpty) {
      return const Sugestao(
        tipo: TipoSugestao.manter,
        cargaAnterior: 0,
        cargaSugerida: 0,
        motivo: 'Ainda não há histórico suficiente para sugerir uma progressão.',
      );
    }

    final cargaAtual = historicoRecente.first.carga;
    final ultimaSessaoId = historicoRecente.first.sessaoId;
    final ultimaSessao = historicoRecente.where((r) => r.sessaoId == ultimaSessaoId).toList();

    final houveFalha = ultimaSessao.any((s) => s.feedback == 'falhou');
    final houveDificil = ultimaSessao.any((s) => s.feedback == 'dificil');
    final repAbaixoDoMin = ultimaSessao.any((s) => s.repeticoes < repeticoesAlvoMin);

    // --- Regra 1: queda de performance → reduzir carga ---
    if (houveFalha || (houveDificil && repAbaixoDoMin)) {
      final reducao = (cargaAtual * 0.10).clamp(incrementoSugerido, cargaAtual);
      final novaCarga = _arredondarParaIncremento(cargaAtual - reducao, incrementoSugerido);
      return Sugestao(
        tipo: TipoSugestao.reduzir,
        cargaAnterior: cargaAtual,
        cargaSugerida: novaCarga.clamp(0, cargaAtual).toDouble(),
        motivo: houveFalha
            ? 'Você não conseguiu completar uma série no peso atual. Vamos reduzir um pouco para manter a técnica.'
            : 'As séries ficaram difíceis e abaixo da meta de repetições. Reduzir a carga ajuda a recuperar a consistência.',
      );
    }

    // --- Regra 2: teto batido com folga, 2 sessões seguidas → aumentar ---
    final bateuTetoNaUltima = ultimaSessao.every(
      (s) => s.repeticoes >= repeticoesAlvoMax && (s.feedback == 'facil' || s.feedback == 'muito_facil'),
    );

    final sessoesAnteriores = historicoRecente
        .where((r) => r.sessaoId != ultimaSessaoId)
        .toList();
    final sessaoAnteriorId = sessoesAnteriores.isNotEmpty ? sessoesAnteriores.first.sessaoId : null;
    final sessaoAnterior = sessaoAnteriorId == null
        ? <RegistroHistorico>[]
        : sessoesAnteriores.where((r) => r.sessaoId == sessaoAnteriorId).toList();
    final bateuTetoNaAnterior = sessaoAnterior.isNotEmpty &&
        sessaoAnterior.every(
          (s) => s.repeticoes >= repeticoesAlvoMax && (s.feedback == 'facil' || s.feedback == 'muito_facil'),
        );

    if (bateuTetoNaUltima && bateuTetoNaAnterior) {
      final novaCarga = _arredondarParaIncremento(cargaAtual + incrementoSugerido, incrementoSugerido);
      return Sugestao(
        tipo: TipoSugestao.aumentar,
        cargaAnterior: cargaAtual,
        cargaSugerida: novaCarga,
        motivo:
            'Você bateu o topo da faixa de repetições com facilidade nas últimas 2 sessões. Hora de subir a carga.',
      );
    }

    if (bateuTetoNaUltima) {
      return Sugestao(
        tipo: TipoSugestao.manter,
        cargaAnterior: cargaAtual,
        cargaSugerida: cargaAtual,
        motivo: 'Boa série! Bata o topo da faixa de repetições mais uma vez com folga para subirmos a carga.',
      );
    }

    // --- Regra 3: dentro da faixa, sem folga clara → manter ---
    return Sugestao(
      tipo: TipoSugestao.manter,
      cargaAnterior: cargaAtual,
      cargaSugerida: cargaAtual,
      motivo: 'Você está dentro da faixa de repetições alvo. Mantenha a carga e foque na execução.',
    );
  }

  static double _arredondarParaIncremento(double valor, double incremento) {
    if (incremento <= 0) return valor;
    return (valor / incremento).round() * incremento;
  }
}
