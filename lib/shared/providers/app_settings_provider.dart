import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class AppSettingsState {
  final ThemeMode themeMode;
  final bool hideBalance;
  final String currencyCode;
  final String currencySymbol;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final bool isOnboardingCompleted;

  const AppSettingsState({
    this.themeMode = ThemeMode.light,
    this.hideBalance = false,
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.isOnboardingCompleted = false,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    bool? hideBalance,
    String? currencyCode,
    String? currencySymbol,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    bool? isOnboardingCompleted,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      hideBalance: hideBalance ?? this.hideBalance,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(const AppSettingsState()) {
    _loadSettings();
  }

  static const String _keyThemeMode = 'nexora_theme_mode';
  static const String _keyHideBalance = 'nexora_hide_balance';
  static const String _keyCurrency = 'nexora_currency';
  static const String _keyNotifications = 'nexora_notifications';
  static const String _keyBiometrics = 'nexora_biometrics';
  static const String _keyOnboarding = 'nexora_onboarding_completed';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyThemeMode) ?? 0;
    final themeMode = ThemeMode.values[themeIndex];

    final hide = prefs.getBool(_keyHideBalance) ?? false;
    final code = prefs.getString(_keyCurrency) ?? 'USD';
    final notifs = prefs.getBool(_keyNotifications) ?? true;
    final bio = prefs.getBool(_keyBiometrics) ?? false;
    final onb = prefs.getBool(_keyOnboarding) ?? false;

    final symbol = _resolveSymbol(code);

    state = AppSettingsState(
      themeMode: themeMode,
      hideBalance: hide,
      currencyCode: code,
      currencySymbol: symbol,
      notificationsEnabled: notifs,
      biometricEnabled: bio,
      isOnboardingCompleted: onb,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> toggleHideBalance() async {
    final newHide = !state.hideBalance;
    state = state.copyWith(hideBalance: newHide);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHideBalance, newHide);
  }

  Future<void> setCurrency(String code) async {
    final symbol = _resolveSymbol(code);
    state = state.copyWith(currencyCode: code, currencySymbol: symbol);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, code);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    state = state.copyWith(biometricEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometrics, enabled);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isOnboardingCompleted: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, true);
  }

  String _resolveSymbol(String code) {
    for (final c in AppConstants.currencies) {
      if (c['code'] == code) {
        return c['symbol']!;
      }
    }
    return '\$';
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});

