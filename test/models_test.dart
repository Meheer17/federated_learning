import 'package:flutter_test/flutter_test.dart';
import 'package:federated_chat/models/conversation.dart';
import 'package:federated_chat/models/message.dart';
import 'package:federated_chat/models/user_profile.dart';

void main() {
  group('Data Models Tests', () {
    test('Conversation serialization and deserialization', () {
      final now = DateTime.now();
      final conv = Conversation(
        id: 'conv_123',
        title: 'Privacy Chat',
        createdAt: now,
        updatedAt: now,
      );

      final map = conv.toMap();
      expect(map['id'], 'conv_123');
      expect(map['title'], 'Privacy Chat');

      final reconstructed = Conversation.fromMap(map, lastMessage: 'Hey there');
      expect(reconstructed.id, conv.id);
      expect(reconstructed.lastMessageText, 'Hey there');
    });

    test('ChatMessage serialization and deserialization', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg_456',
        conversationId: 'conv_123',
        role: MessageRole.user,
        content: 'Is this stored locally?',
        timestamp: now,
      );

      final map = msg.toMap();
      expect(map['role'], 'user');
      expect(map['content'], 'Is this stored locally?');

      final reconstructed = ChatMessage.fromMap(map);
      expect(reconstructed.role, MessageRole.user);
      expect(reconstructed.content, msg.content);
    });

    test('StyleProfile default values and map conversion', () {
      final profile = StyleProfile(formalityScore: 0.8, topEmojis: ['🛡️', '🔒']);
      final map = profile.toMap();

      final reconstructed = StyleProfile.fromMap(map);
      expect(reconstructed.formalityScore, 0.8);
      expect(reconstructed.topEmojis, ['🛡️', '🔒']);
    });
  });
}
