/// Configuração central de acesso ao Supabase.
///
/// IMPORTANTE: substitua os valores abaixo pelos do seu projeto Supabase
/// (Project Settings → API). Nunca commite a `service_role key` — apenas a
/// `anon key`, que é segura para uso no cliente (a segurança real vem do RLS).
class SupabaseConfig {
  static const String supabaseUrl = 'https://bihfnohyhexxomqrwqeq.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_YhMeNi3yU3S1hiPT5_plYg_zgESGUUR';

  /// Client ID OAuth do Google (Web), necessário para o fluxo de
  /// `google_sign_in` no Android/iOS funcionar junto com o Supabase Auth.
  static const String googleWebClientId = '';
}
