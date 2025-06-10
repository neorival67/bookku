import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../models/auth_user.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,   
      password: password,
      data: {
        'name': name,
      },
    );
    
    if (response.user != null) {
      final now = DateTime.now().toUtc();
      
      // Create profile after signup
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'created_at': now,
        'updated_at': now,
      });
    }
    
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthUser?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return AuthUser.fromJson(profile);
  }
}
