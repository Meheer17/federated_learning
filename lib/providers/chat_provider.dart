import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/chat_repository.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/llm_service.dart';
import '../services/personalization_engine.dart';
import '../services/style_analyzer.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());
final llmServiceProvider = Provider<LlmService>((ref) => LlmService());
final styleAnalyzerProvider = Provider<StyleAnalyzer>((ref) => StyleAnalyzer());
final personalizationEngineProvider = Provider<PersonalizationEngine>((ref) => PersonalizationEngine());

final conversationsProvider = StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref) {
  return ConversationsNotifier(ref.watch(chatRepositoryProvider));
});

class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  final ChatRepository _repository;

  ConversationsNotifier(this._repository) : super([]) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = await _repository.getConversations();
  }

  Future<Conversation> createConversation({String? title}) async {
    final now = DateTime.now();
    final conversation = Conversation(
      id: const Uuid().v4(),
      title: title ?? 'New Conversation',
      createdAt: now,
      updatedAt: now,
    );
    await _repository.createConversation(conversation);
    await loadConversations();
    return conversation;
  }

  Future<void> deleteConversation(String id) async {
    await _repository.deleteConversation(id);
    await loadConversations();
  }

  Future<void> clearAllConversations() async {
    for (final conv in state) {
      await _repository.deleteConversation(conv.id);
    }
    await loadConversations();
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<ChatMessage>, String>((ref, conversationId) {
  return MessagesNotifier(
    ref.watch(chatRepositoryProvider),
    ref.watch(llmServiceProvider),
    ref.watch(styleAnalyzerProvider),
    conversationId,
  );
});

class MessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatRepository _repository;
  final LlmService _llmService;
  final StyleAnalyzer _styleAnalyzer;
  final String conversationId;

  MessagesNotifier(this._repository, this._llmService, this._styleAnalyzer, this.conversationId) : super([]) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = await _repository.getMessages(conversationId);
  }

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    // Save & add User Message
    await _repository.insertMessage(userMsg);
    state = [...state, userMsg];

    // Trigger background style analysis for personalization
    _styleAnalyzer.analyzeUserMessages(state);

    // Create assistant message placeholder
    final assistantMsgId = const Uuid().v4();
    final assistantMsg = ChatMessage(
      id: assistantMsgId,
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isGenerating: true,
    );

    state = [...state, assistantMsg];

    // Stream response tokens
    final tokenStream = _llmService.generateResponse(history: state);

    String fullContent = '';
    await for (final token in tokenStream) {
      fullContent += token;
      state = [
        for (final msg in state)
          if (msg.id == assistantMsgId)
            msg.copyWith(content: fullContent, isGenerating: true)
          else
            msg
      ];
    }

    // Finalize assistant message
    final finalAssistantMsg = ChatMessage(
      id: assistantMsgId,
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: fullContent,
      timestamp: DateTime.now(),
      isGenerating: false,
    );

    await _repository.insertMessage(finalAssistantMsg);
    state = [
      for (final msg in state)
        if (msg.id == assistantMsgId) finalAssistantMsg else msg
    ];
  }
}
