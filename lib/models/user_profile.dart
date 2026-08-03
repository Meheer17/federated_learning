class StyleProfile {
  final double avgSentenceLength;
  final double avgMessageLength;
  final double vocabularyRichness;
  final double formalityScore;
  final List<String> topEmojis;
  final String preferredGreeting;

  StyleProfile({
    this.avgSentenceLength = 12.0,
    this.avgMessageLength = 25.0,
    this.vocabularyRichness = 0.6,
    this.formalityScore = 0.5,
    this.topEmojis = const ['👍', '😊'],
    this.preferredGreeting = 'Hey',
  });

  Map<String, String> toMap() {
    return {
      'avg_sentence_length': avgSentenceLength.toString(),
      'avg_message_length': avgMessageLength.toString(),
      'vocabulary_richness': vocabularyRichness.toString(),
      'formality_score': formalityScore.toString(),
      'top_emojis': topEmojis.join(','),
      'preferred_greeting': preferredGreeting,
    };
  }

  factory StyleProfile.fromMap(Map<String, String> map) {
    return StyleProfile(
      avgSentenceLength: double.tryParse(map['avg_sentence_length'] ?? '') ?? 12.0,
      avgMessageLength: double.tryParse(map['avg_message_length'] ?? '') ?? 25.0,
      vocabularyRichness: double.tryParse(map['vocabulary_richness'] ?? '') ?? 0.6,
      formalityScore: double.tryParse(map['formality_score'] ?? '') ?? 0.5,
      topEmojis: map['top_emojis']?.split(',') ?? ['👍', '😊'],
      preferredGreeting: map['preferred_greeting'] ?? 'Hey',
    );
  }
}
