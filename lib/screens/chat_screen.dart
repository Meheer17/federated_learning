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

  void _confirmDeleteConversation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Conversation"),
        content: const Text("Are you sure you want to delete this conversation? All messages will be permanently removed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(conversationsProvider.notifier).deleteConversation(conversationId);
              Navigator.of(ctx).pop();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Conversation deleted")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: "Delete Conversation",
            onPressed: () => _confirmDeleteConversation(context, ref),
          ),
        ],
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

