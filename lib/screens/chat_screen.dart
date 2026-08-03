import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme.dart';
import '../models/message.dart';
import '../providers/app_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider(conversationId));
    final messagesNotifier = ref.read(messagesProvider(conversationId).notifier);
    final themeMode = ref.watch(themeModeProvider);

    final isDark = themeMode == ThemeMode.dark;

    // Convert ChatMessage -> flutter_chat_types Message for UI rendering
    final uiMessages = messages.reversed.map((msg) {
      final author = msg.role == MessageRole.user
          ? const types.User(id: 'user_me', firstName: 'You')
          : const types.User(id: 'assistant_ai', firstName: 'FedChat');

      final text = msg.content.isEmpty && msg.isGenerating ? "Thinking..." : msg.content;

      return types.TextMessage(
        author: author,
        createdAt: msg.timestamp.millisecondsSinceEpoch,
        id: msg.id,
        text: text,
      );
    }).toList();

    final chatTheme = isDark
        ? const DarkChatTheme(
            backgroundColor: AppTheme.backgroundDark,
            primaryColor: AppTheme.primaryViolet,
            secondaryColor: AppTheme.cardDark,
            inputBackgroundColor: AppTheme.cardDark,
            inputTextStyle: TextStyle(color: Colors.white),
          )
        : const DefaultChatTheme(
            backgroundColor: AppTheme.backgroundLight,
            primaryColor: AppTheme.primaryViolet,
            secondaryColor: Color(0xFFF0F0F0),
            inputBackgroundColor: Color(0xFFF5F5F5),
            inputTextStyle: TextStyle(color: Colors.black87),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text("FedChat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("🔒 On-Device Offline Engine", style: TextStyle(fontSize: 11, color: AppTheme.secondaryCyan)),
          ],
        ),
      ),
      body: Chat(
        messages: uiMessages,
        onSendPressed: (types.PartialText partialText) {
          messagesNotifier.sendMessage(partialText.text);
        },
        user: const types.User(id: 'user_me'),
        theme: chatTheme,
      ),
    );
  }
}
