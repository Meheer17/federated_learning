import '../models/message.dart';
import '../models/user_profile.dart';

class PromptBuilder {
  static String buildChatMLPrompt({
    required List<ChatMessage> history,
    StyleProfile? styleProfile,
    int maxContextMessages = 10,
  }) {
    final StringBuffer buffer = StringBuffer();

    // 1. System Prompt construction
    String systemPrompt = "You are FedChat, a privacy-first AI chat assistant running locally on the user's device. Be helpful, concise, and friendly.";
    if (styleProfile != null) {
      systemPrompt += " Adapt to the user's preferred communication style: greeting like '${styleProfile.preferredGreeting}', maintain a formality score of ${styleProfile.formalityScore.toStringAsFixed(1)}.";
    }

    buffer.writeln("<|im_start|>system");
    buffer.writeln(systemPrompt);
    buffer.writeln("<|im_end|>");

    // 2. Trim history to fit within sliding context window
    final trimmedHistory = history.length > maxContextMessages
        ? history.sublist(history.length - maxContextMessages)
        : history;

    // 3. Format message history into ChatML format
    for (final message in trimmedHistory) {
      final roleStr = message.role == MessageRole.user ? 'user' : 'assistant';
      buffer.writeln("<|im_start|>$roleStr");
      buffer.writeln(message.content);
      buffer.writeln("<|im_end|>");
    }

    // 4. Assistant response prompt prefix
    buffer.writeln("<|im_start|>assistant");

    return buffer.toString();
  }
}
