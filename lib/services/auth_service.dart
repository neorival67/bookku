import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../utils/app_exceptions.dart';
import 'supabase_service.dart';

class AuthService {
  // Stream controller untuk memantau perubahan status autentikasi
  static final _authStateController = StreamController<app_user.User?>.broadcast();
  
  // Stream untuk mendengarkan perubahan status autentikasi
  static Stream<app_user.User?> get authStateChanges => _authStateController.stream;

  // Mendapatkan user yang sedang login
  static app_user.User? _currentUser;
  static app_user.User? get currentUser => _currentUser;

  // Inisialisasi service
  static Future<void> initialize() async {
    // Listen to Supabase auth changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        final user = await SupabaseService.getCurrentUser();
        _currentUser = user;
        _authStateController.add(user);
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _authStateController.add(null);
      }
    });

    // Check initial auth state
    final user = await SupabaseService.getCurrentUser();
    _currentUser = user;
    _authStateController.add(user);
  }

  // Sign Up
  static Future<app_user.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await SupabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );
      _currentUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      throw AppAuthException(e.toString());
    }
  }

  // Sign In
  static Future<app_user.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      _currentUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      throw AppAuthException(e.toString());
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      _currentUser = null;
      _authStateController.add(null);
    } catch (e) {
      throw AppAuthException(e.toString());
    }
  }

  // Update Profile
  static Future<app_user.User> updateProfile({
    String? name,
    String? profileImage,
  }) async {
    try {
      final user = await SupabaseService.updateProfile(
        name: name,
        profileImage: profileImage,
      );
      _currentUser = user;
      _authStateController.add(user);
      return user;
    } catch (e) {
      throw AppAuthException(e.toString());
    }
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AppAuthException('Failed to send reset password email: ${e.toString()}');
    }
  }

  // Update Password
  static Future<void> updatePassword(String newPassword) async {
    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      throw AppAuthException('Failed to update password: ${e.toString()}');
    }
  }

  // Dispose
  static void dispose() {
    _authStateController.close();
  }
}
