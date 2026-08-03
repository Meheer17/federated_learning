import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/constants.dart';
import '../models/model_info.dart';
import '../services/adapter_manager.dart';
import '../services/federated_client.dart';
import '../services/model_manager.dart';
import '../services/privacy_guard.dart';

final modelManagerProvider = Provider<ModelManager>((ref) => ModelManager());
final privacyGuardProvider = Provider<PrivacyGuard>((ref) => PrivacyGuard());
final adapterManagerProvider = Provider<AdapterManager>((ref) => AdapterManager());
final federatedClientProvider = Provider<FederatedClient>((ref) => FederatedClient());

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);
    state = true;
  }
}

final flConsentProvider = StateNotifierProvider<FlConsentNotifier, bool>((ref) {
  return FlConsentNotifier();
});

class FlConsentNotifier extends StateNotifier<bool> {
  FlConsentNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppConstants.flConsentKey) ?? false;
  }

  Future<void> toggleConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.flConsentKey, value);
    state = value;
  }
}

final modelInfoProvider = FutureProvider<ModelInfo>((ref) async {
  final manager = ref.watch(modelManagerProvider);
  return await manager.getModelInfo();
});
