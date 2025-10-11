import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Auth service for user authentication
/// [REQ-AUTH-OTP-001, REQ-AUTH-OTP-002]
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Check if user is signed in
  bool get isSignedIn => _client.auth.currentUser != null;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  /// Send OTP to email
  /// [TC-AUTH-001]
  Future<void> sendEmailOTP(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
    );
  }

  /// Send OTP to phone
  /// [TC-AUTH-003]
  Future<void> sendPhoneOTP(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  /// Verify OTP
  Future<AuthResponse> verifyOTP({
    required String token,
    required OtpType type,
    String? email,
    String? phone,
  }) async {
    return await _client.auth.verifyOTP(
      token: token,
      type: type,
      email: email,
      phone: phone,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseProvider);
  return AuthService(client);
});

/// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});


