/// Representa o perfil da usuária (tabela `profiles` no Supabase).
///
/// Já inclui `tipoUsuario` mesmo a v1 sendo de usuária única — é o gancho
/// para a v2 (plataforma de personal trainers) sem precisar de migração
/// de schema depois. Ver docs/01_ARQUITETURA.md, seção 5.
class AppUser {
  const AppUser({
    required this.id,
    required this.nome,
    required this.email,
    this.avatarUrl,
    this.tipoUsuario = 'aluno',
    this.unidadeCarga = 'kg',
  });

  final String id;
  final String nome;
  final String email;
  final String? avatarUrl;
  final String tipoUsuario; // 'aluno' | 'personal' | 'admin'
  final String unidadeCarga; // 'kg' | 'lb'

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
      tipoUsuario: map['tipo_usuario'] as String? ?? 'aluno',
      unidadeCarga: map['unidade_carga'] as String? ?? 'kg',
    );
  }
}
