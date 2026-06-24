class Exercicio {
  const Exercicio({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
    this.usuarioId,
    this.equipamento,
    this.videoUrl,
    this.observacoes,
    this.ativo = true,
  });

  final String id;
  final String? usuarioId; // null = catálogo global do sistema
  final String nome;
  final String grupoMuscular;
  final String? equipamento;
  final String? videoUrl;
  final String? observacoes;
  final bool ativo;

  bool get isCustom => usuarioId != null;

  factory Exercicio.fromMap(Map<String, dynamic> map) {
    return Exercicio(
      id: map['id'] as String,
      usuarioId: map['usuario_id'] as String?,
      nome: map['nome'] as String,
      grupoMuscular: map['grupo_muscular'] as String,
      equipamento: map['equipamento'] as String?,
      videoUrl: map['video_url'] as String?,
      observacoes: map['observacoes'] as String?,
      ativo: map['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap({required String usuarioId}) {
    return {
      'usuario_id': usuarioId,
      'nome': nome,
      'grupo_muscular': grupoMuscular,
      'equipamento': equipamento,
      'observacoes': observacoes,
    };
  }
}

/// Grupos musculares padrão — usados em filtros e no formulário de
/// criação de exercício customizado.
const List<String> gruposMusculares = [
  'peito',
  'dorsal',
  'ombro',
  'biceps',
  'triceps',
  'perna',
  'gluteo',
  'core',
];
