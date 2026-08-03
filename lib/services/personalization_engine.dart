import '../models/user_profile.dart';
import 'style_analyzer.dart';

class PersonalizationEngine {
  final StyleAnalyzer _styleAnalyzer;
  bool _isPersonalizationEnabled = true;

  PersonalizationEngine({StyleAnalyzer? styleAnalyzer})
      : _styleAnalyzer = styleAnalyzer ?? StyleAnalyzer();

  bool get isPersonalizationEnabled => _isPersonalizationEnabled;

  void setPersonalizationEnabled(bool enabled) {
    _isPersonalizationEnabled = enabled;
  }

  Future<StyleProfile> fetchUserProfile() async {
    return await _styleAnalyzer.getProfile();
  }

  String buildPersonalizedSystemPrompt(StyleProfile profile) {
    final tone = profile.formalityScore > 0.6 ? 'formal and professional' : 'casual and conversational';
    final emojiHint = profile.topEmojis.isNotEmpty
        ? "Occasionally use emojis like ${profile.topEmojis.join(' ')}."
        : '';

    return "You are FedChat, a privacy-first AI chat assistant. "
        "Match the user's preferred style: $tone. "
        "Start greeting with '${profile.preferredGreeting}'. "
        "$emojiHint Keep responses direct and helpful.";
  }
}
