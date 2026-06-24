import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/app_user.dart';

/// Contrato de autenticação. A camada `presentation` só conhece esta
/// interface — troca de backend de auth no futuro não toca nas telas.
abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> atualizarUnidadeCarga(String unidadeCarga);
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _mapSupabaseUser(user);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      // Busca o profile completo (nome, tipo_usuario, unidade_carga etc.)
      final profileRow = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profileRow != null) return AppUser.fromMap(profileRow);
      return _mapSupabaseUser(user);
    });
  }

  AppUser _mapSupabaseUser(User user) {
    return AppUser(
      id: user.id,
      nome: user.userMetadata?['full_name'] as String? ?? user.email ?? 'Usuária',
      email: user.email ?? '',
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    // Fluxo recomendado pelo supabase_flutter para Android/iOS:
    // google_sign_in obtém o idToken nativo, que é então trocado por uma
    // sessão Supabase via signInWithIdToken. Evita abrir um browser externo.
    final googleSignIn = GoogleSignIn(
      serverClientId: SupabaseConfig.googleWebClientId,
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Login com Google cancelado.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw AuthException('Não foi possível obter o token do Google.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _client.auth.signOut();
  }

  @override
  Future<void> atualizarUnidadeCarga(String unidadeCarga) async {
    final usuarioId = _client.auth.currentUser?.id;
    if (usuarioId == null) return;
    await _client.from('profiles').update({'unidade_carga': unidadeCarga}).eq('id', usuarioId);
  }
}
