import 'package:flutter_test/flutter_test.dart';
import 'package:federated_chat/models/message.dart';
import 'package:federated_chat/models/user_profile.dart';
import 'package:federated_chat/services/prompt_builder.dart';

void main() {
  group('PromptBuilder Tests', () {
    test('builds ChatML prompt with system message and history', () {
      final messages = [
        ChatMessage(
          id: '1',
          conversationId: 'c1',
          role: MessageRole.user,
          content: 'Hello AI!',
          timestamp: DateTime.now(),
        ),
      ];

      final prompt = PromptBuilder.buildChatMLPrompt(history: messages);

      expect(prompt, contains('<|im_start|>system'));
      expect(prompt, contains('FedChat'));
      expect(prompt, contains('<|im_start|>user\nHello AI!\n<|im_end|>'));
      expect(prompt, contains('<|im_start|>assistant'));
    });

    test('injects style profile into system prompt', () {
      final profile = StyleProfile(preferredGreeting: 'Yo', formalityScore: 0.2);
      final prompt = PromptBuilder.buildChatMLPrompt(
        history: [],
        styleProfile: profile,
      );

      expect(prompt, contains("greeting like 'Yo'"));
      expect(prompt, contains("formality score of 0.2"));
    });
  });
}
