import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Conversation conv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Chat"),
        content: Text("Are you sure you want to delete '${conv.title}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(conversationsProvider.notifier).deleteConversation(conv.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chat deleted")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Chats"),
        content: const Text("Are you sure you want to delete all conversations? All encrypted chat records will be removed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(conversationsProvider.notifier).clearAllConversations();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All chats cleared")),
              );
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.secondaryCyan]),
              ),
              child: const Icon(Icons.shield_outlined, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text("FedChat"),
          ],
        ),
        actions: [
          if (conversations.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'clear_all') {
                  _showClearAllConfirmation(context, ref);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text("Clear All Chats", style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: conversations.isEmpty
          ? _buildEmptyState(context, ref)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return Dismissible(
                  key: Key(conv.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    _showDeleteConfirmation(context, ref, conv);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryViolet.withOpacity(0.2),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryViolet),
                    ),
                    title: Text(
                      conv.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      conv.lastMessageText ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.jm().format(conv.updatedAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: "Delete Chat",
                          onPressed: () => _showDeleteConfirmation(context, ref, conv),
                        ),
                      ],
                    ),
                    onTap: () => context.push('/chat/${conv.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryViolet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final newConv = await ref.read(conversationsProvider.notifier).createConversation();
          if (context.mounted) {
            context.push('/chat/${newConv.id}');
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock_outlined, size: 80, color: AppTheme.primaryViolet.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              "Private On-Device Assistant",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              "Your conversations stay encrypted on your phone. Tap 'New Chat' to start talking!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

