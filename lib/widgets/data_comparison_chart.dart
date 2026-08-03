import 'package:flutter/material.dart';
import '../app/theme.dart';

class DataComparisonChart extends StatelessWidget {
  final double localDataMb;
  final double sharedDataMb;

  const DataComparisonChart({
    super.key,
    this.localDataMb = 45.0,
    this.sharedDataMb = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    final maxMb = localDataMb * 1.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Data Residency Comparison",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              "Dramatically minimal data sharing via encrypted LoRA deltas",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildBarItem(
              label: "On-Device Encrypted Chats",
              sizeText: "${localDataMb.toStringAsFixed(1)} MB (100% Private)",
              color: AppTheme.primaryViolet,
              fraction: (localDataMb / maxMb).clamp(0.05, 1.0),
            ),
            const SizedBox(height: 16),
            _buildBarItem(
              label: "Shared LoRA Deltas (FL Opt-In)",
              sizeText: "${sharedDataMb.toStringAsFixed(1)} MB (Encrypted + DP Noise)",
              color: AppTheme.secondaryCyan,
              fraction: (sharedDataMb / maxMb).clamp(0.05, 1.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarItem({
    required String label,
    required String sizeText,
    required Color color,
    required double fraction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(sizeText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 12,
              width: constraints.maxWidth * fraction,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }
}
