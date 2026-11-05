import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // 1. If Supabase is initialized and connected
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final currentSession = SupabaseService.client!.auth.currentSession;
        if (currentSession != null) {
          final res = await SupabaseService.client!
              .from('profiles')
              .select()
              .eq('id', currentSession.user.id)
              .maybeSingle();

          if (res != null) {
            final profile = UserProfile.fromMap(res);
            state = state.copyWith(
              status: AuthStatus.authenticated,
              user: profile,
            );
            return;
          }
        }
      }

      // 2. Check local persistence / demo session
      final prefs = await SharedPreferences.getInstance();
      final hasCached = prefs.getBool('nexora_is_logged_in') ?? false;
      if (hasCached) {
        final email = prefs.getString('nexora_user_email') ?? 'alex.morgan@nexora.finance';
        final name = prefs.getString('nexora_user_name') ?? 'Alex Morgan';
        final currency = prefs.getString('nexora_currency') ?? 'USD';

        final profile = UserProfile(
          id: 'user-cached-${email.hashCode}',
          email: email,
          fullName: name,
          preferredCurrency: currency,
          monthlyIncome: 6500.0,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: profile,
        );
        return;
      }

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final response = await SupabaseService.client!.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );

        if (response.user != null) {
          final profileData = await SupabaseService.client!
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          final profile = profileData != null
              ? UserProfile.fromMap(profileData)
              : UserProfile(
                  id: response.user!.id,
                  email: response.user!.email ?? email,
                  fullName: response.user!.userMetadata?['full_name'] ?? 'Fintech User',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: profile,
          );
          _cacheSession(profile);
          return true;
        }
      }

      // Local / Offline authentication handling
      await Future.delayed(const Duration(milliseconds: 600)); // smooth natural feel
      final profile = UserProfile(
        id: 'usr-${email.hashCode.abs()}',
        email: email.trim(),
        fullName: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
        preferredCurrency: 'USD',
        monthlyIncome: 6500.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: profile,
      );
      _cacheSession(profile);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> registerWithEmail(String fullName, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final response = await SupabaseService.client!.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName.trim()},
        );

        if (response.user != null) {
          final profile = UserProfile(
            id: response.user!.id,
            email: email.trim(),
            fullName: fullName.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await SupabaseService.client!.from('profiles').upsert(profile.toMap());

          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: profile,
          );
          _cacheSession(profile);
          return true;
        }
      }

      // Local / Offline Registration
      await Future.delayed(const Duration(milliseconds: 600));
      final profile = UserProfile(
        id: 'usr-${email.hashCode.abs()}',
        email: email.trim(),
        fullName: fullName.trim(),
        preferredCurrency: 'USD',
        monthlyIncome: 6000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: profile,
      );
      _cacheSession(profile);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final profile = UserProfile.defaultDemoProfile();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: profile,
      );
      _cacheSession(profile);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google Sign In failed: $e',
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        await SupabaseService.client!.auth.resetPasswordForEmail(email.trim());
      }
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to send password reset: $e',
      );
      return false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? preferredCurrency,
    double? monthlyIncome,
    bool? notificationEnabled,
    bool? biometricEnabled,
    bool? isDarkMode,
    bool? hideBalance,
  }) async {
    if (state.user == null) return;

    final updated = state.user!.copyWith(
      fullName: fullName,
      avatarUrl: avatarUrl,
      preferredCurrency: preferredCurrency,
      monthlyIncome: monthlyIncome,
      notificationEnabled: notificationEnabled,
      biometricEnabled: biometricEnabled,
      isDarkMode: isDarkMode,
      hideBalance: hideBalance,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(user: updated);
    _cacheSession(updated);

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from('profiles')
            .update(updated.toMap())
            .eq('id', updated.id);
      } catch (e) {
        debugPrint('Error syncing profile update to Supabase: $e');
      }
    }
  }

  Future<void> signOut() async {
    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.auth.signOut();
      } catch (e) {
        debugPrint('Error signing out from Supabase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nexora_is_logged_in');
    await prefs.remove('nexora_user_email');
    await prefs.remove('nexora_user_name');

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _cacheSession(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nexora_is_logged_in', true);
    await prefs.setString('nexora_user_email', profile.email);
    await prefs.setString('nexora_user_name', profile.fullName);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
