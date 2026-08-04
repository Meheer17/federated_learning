class AppConstants {
  static const String appName = 'FedChat';

  // LLM Configurations
  static const String defaultModelName = 'gemma-3-270m-it-Q4_K_M.gguf';
  static const String defaultModelUrl =
      'https://huggingface.co/unsloth/gemma-3-270m-it-GGUF/resolve/main/gemma-3-270m-it-Q4_K_M.gguf';
  static const int defaultContextSize = 2048;
  static const double defaultTemperature = 0.7;
  static const double defaultTopP = 0.9;
  static const int defaultMaxTokens = 512;

  // Storage Keys
  static const String dbName = 'fedchat_encrypted.db';
  static const String dbPassphraseKey = 'fedchat_sqlite_sec_key';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String flConsentKey = 'fl_consent_opted_in';
  static const String currentModelNameKey = 'current_model_name';

  // FL Default Configs
  static const String defaultFlServerUrl = 'https://fl.fedchat.app/api/v1';
  static const double defaultDpEpsilon = 1.0;
  static const double defaultDpClipNorm = 1.0;
  static const double minBatteryForTraining = 0.5; // 50%
}
