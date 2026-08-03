import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

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
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(conversationsProvider.notifier).deleteConversation(conv.id);
                  },
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
                    trailing: Text(
                      DateFormat.jm().format(conv.updatedAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
