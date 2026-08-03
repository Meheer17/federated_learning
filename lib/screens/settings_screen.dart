import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../models/model_info.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final flConsent = ref.watch(flConsentProvider);
    final modelInfoAsync = ref.watch(modelInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings & Privacy"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Local Model Status"),
          modelInfoAsync.when(
            data: (modelInfo) => _buildModelCard(context, ref, modelInfo),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text("Error: $err"),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Preferences"),
          SwitchListTile(
            title: const Text("Dark Theme"),
            subtitle: const Text("Toggle between sleek dark & light theme"),
            secondary: const Icon(Icons.brightness_4_outlined),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const Divider(),
          _buildSectionHeader("Federated Learning (FL)"),
          SwitchListTile(
            title: const Text("Opt-in to Federated Learning"),
            subtitle: const Text("Share encrypted & noisy model updates (~1-4 MB) to improve AI globally. Chats NEVER leave your phone."),
            secondary: const Icon(Icons.hub_outlined, color: AppTheme.secondaryCyan),
            value: flConsent,
            onChanged: (val) => ref.read(flConsentProvider.notifier).toggleConsent(val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("About & Privacy"),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Privacy Architecture"),
            subtitle: const Text("AES-256 SQLCipher DB • DP Noise • SecAgg"),
            onTap: () => context.push('/privacy'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("FedChat Version"),
            subtitle: Text("1.0.0+1 (Phase 1 Build)"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, WidgetRef ref, ModelInfo modelInfo) {
    final isReady = modelInfo.status == ModelStatus.ready;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, color: AppTheme.primaryViolet),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(modelInfo.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        isReady ? "Ready (~1.0 GB)" : "Not Downloaded",
                        style: TextStyle(
                          color: isReady ? Colors.greenAccent : Colors.amberAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isReady)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text("Download Model (HuggingFace)", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  ref.read(modelManagerProvider).downloadModel(
                    onProgress: (p) {},
                    onCompleted: () => ref.refresh(modelInfoProvider),
                    onError: (e) {},
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
