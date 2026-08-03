import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/data_comparison_chart.dart';
import '../widgets/privacy_budget_gauge.dart';

class PrivacyDashboardScreen extends ConsumerWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flConsent = ref.watch(flConsentProvider);
    final privacyGuard = ref.watch(privacyGuardProvider);
    final adapterManager = ref.watch(adapterManagerProvider);

    final currentEpsilon = privacyGuard.cumulativeEpsilon;
    final maxEpsilon = privacyGuard.maxBudgetEpsilon;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Dashboard"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Data Residency Guarantee Card
          Card(
            color: AppTheme.cardDark,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.secondaryCyan, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Zero Cloud Storage",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "100% of your chat history is stored locally in AES-256 SQLCipher encrypted storage.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Privacy Budget Gauge
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Differential Privacy Budget",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  PrivacyBudgetGauge(currentEpsilon: currentEpsilon, maxEpsilon: maxEpsilon),
                  const SizedBox(height: 12),
                  Text(
                    "Calibrated Gaussian Noise is added to weight deltas before transmission to guarantee ε-DP privacy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Data Comparison Chart
          const DataComparisonChart(localDataMb: 45.0, sharedDataMb: 1.2),
          const SizedBox(height: 20),

          // 4. Opt-In & Revoke Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Participate in Federated Learning"),
                    subtitle: const Text("Contribute encrypted model deltas during idle charging time."),
                    value: flConsent,
                    onChanged: (val) => ref.read(flConsentProvider.notifier).toggleConsent(val),
                  ),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Delete All Local FL Data & Revoke Consent"),
                      onPressed: () async {
                        ref.read(flConsentProvider.notifier).toggleConsent(false);
                        await adapterManager.deleteAdapter();
                        await privacyGuard.resetPrivacyBudget();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("All local FL adapter deltas deleted and DP budget reset.")),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
