import 'package:sqflite_sqlcipher/sqflite.dart';
import '../database/database_helper.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class StyleAnalyzer {
  final DatabaseHelper _dbHelper;

  StyleAnalyzer({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Analyze user messages to generate or update StyleProfile
  Future<StyleProfile> analyzeUserMessages(List<ChatMessage> userMessages) async {
    if (userMessages.isEmpty) {
      return StyleProfile();
    }

    final sentMessages = userMessages
        .where((m) => m.role == MessageRole.user)
        .map((m) => m.content.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    if (sentMessages.isEmpty) {
      return StyleProfile();
    }

    // 1. Calculate Average Message & Sentence Length
    int totalWords = 0;
    int totalSentences = 0;
    final Set<String> uniqueWords = {};
    final Map<String, int> emojiCounts = {};
    final Map<String, int> greetingCounts = {};

    final emojiRegExp = RegExp(
        r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

    for (final text in sentMessages) {
      final words = text.split(RegExp(r'\s+'));
      totalWords += words.length;

      for (var word in words) {
        final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        if (cleanWord.isNotEmpty) {
          uniqueWords.add(cleanWord);
        }
      }

      final sentences = text.split(RegExp(r'[.!?]+'));
      totalSentences += sentences.where((s) => s.trim().isNotEmpty).length;

      // Extract Emojis
      for (final match in emojiRegExp.allMatches(text)) {
        final emoji = match.group(0)!;
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      }

      // Check Greetings
      final lowerText = text.toLowerCase();
      if (lowerText.startsWith('hey')) greetingCounts['Hey'] = (greetingCounts['Hey'] ?? 0) + 1;
      if (lowerText.startsWith('hi')) greetingCounts['Hi'] = (greetingCounts['Hi'] ?? 0) + 1;
      if (lowerText.startsWith('hello')) greetingCounts['Hello'] = (greetingCounts['Hello'] ?? 0) + 1;
      if (lowerText.startsWith('yo')) greetingCounts['Yo'] = (greetingCounts['Yo'] ?? 0) + 1;
    }

    final avgMsgLength = totalWords / sentMessages.length;
    final avgSentenceLength = totalSentences > 0 ? totalWords / totalSentences : avgMsgLength;
    final vocabRichness = totalWords > 0 ? uniqueWords.length / totalWords : 0.6;

    // Determine Formality Score (higher punctuation & longer words = higher score)
    double formality = 0.5;
    if (avgSentenceLength > 18) formality += 0.2;
    if (avgSentenceLength < 8) formality -= 0.2;
    if (vocabRichness > 0.7) formality += 0.1;
    formality = formality.clamp(0.0, 1.0);

    // Top Emojis
    final sortedEmojis = emojiCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEmojis = sortedEmojis.take(3).map((e) => e.key).toList();
    if (topEmojis.isEmpty) topEmojis.addAll(['👍', '😊']);

    // Preferred Greeting
    String preferredGreeting = 'Hey';
    if (greetingCounts.isNotEmpty) {
      final sortedGreetings = greetingCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      preferredGreeting = sortedGreetings.first.key;
    }

    final profile = StyleProfile(
      avgSentenceLength: avgSentenceLength,
      avgMessageLength: avgMsgLength,
      vocabularyRichness: vocabRichness,
      formalityScore: formality,
      topEmojis: topEmojis,
      preferredGreeting: preferredGreeting,
    );

    await saveProfile(profile);
    return profile;
  }

  Future<void> saveProfile(StyleProfile profile) async {
    final db = await _dbHelper.database;
    final map = profile.toMap();
    for (final entry in map.entries) {
      await db.insert(
        'user_profile',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<StyleProfile> getProfile() async {
    final db = await _dbHelper.database;
    final rows = await db.query('user_profile');
    final Map<String, String> map = {};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String;
    }
    return StyleProfile.fromMap(map);
  }
}
