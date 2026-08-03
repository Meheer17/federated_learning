import 'dart:math';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/constants.dart';
import 'crypto_service.dart';

class PrivacyGuard {
  static const String _prefKeyEpsilon = 'privacy_cumulative_epsilon';
  double _cumulativeEpsilon = 0.0;
  final double maxBudgetEpsilon = 10.0;

  PrivacyGuard() {
    _loadStoredBudget();
  }

  Future<void> _loadStoredBudget() async {
    final prefs = await SharedPreferences.getInstance();
    _cumulativeEpsilon = prefs.getDouble(_prefKeyEpsilon) ?? 0.0;
  }

  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKeyEpsilon, _cumulativeEpsilon);
  }

  double get cumulativeEpsilon => _cumulativeEpsilon;
  double get remainingBudget => max(0.0, maxBudgetEpsilon - _cumulativeEpsilon);
  bool get isBudgetExhausted => _cumulativeEpsilon >= maxBudgetEpsilon;

  /// Apply L2 gradient clipping to bound sensitivity
  Uint8List clipGradients(Uint8List deltaBytes, double clipNorm) {
    double sumSquares = 0.0;
    for (final b in deltaBytes) {
      sumSquares += b * b;
    }
    final l2Norm = sqrt(sumSquares);

    if (l2Norm <= clipNorm || l2Norm == 0) {
      return Uint8List.fromList(deltaBytes);
    }

    final scale = clipNorm / l2Norm;
    final clipped = Uint8List(deltaBytes.length);
    for (int i = 0; i < deltaBytes.length; i++) {
      clipped[i] = (deltaBytes[i] * scale).round().clamp(0, 255);
    }
    return clipped;
  }

  /// Inject calibrated Gaussian noise for Differential Privacy (DP)
  Uint8List applyDifferentialPrivacy(
    Uint8List deltaBytes, {
    double clipNorm = AppConstants.defaultDpClipNorm,
    double epsilonPerRound = AppConstants.defaultDpEpsilon,
  }) {
    if (isBudgetExhausted) {
      throw Exception("Privacy budget ($maxBudgetEpsilon epsilon) exhausted. Participation refused.");
    }

    // Clip gradients
    final clipped = clipGradients(deltaBytes, clipNorm);

    // Calculate noise multiplier sigma
    final sigma = clipNorm * sqrt(2 * log(1.25 / 1e-5)) / epsilonPerRound;
    final noise = CryptoService.generateGaussianNoise(clipped.length, sigma);

    final noisyDelta = Uint8List(clipped.length);
    for (int i = 0; i < clipped.length; i++) {
      final noisyVal = clipped[i] + noise[i].round();
      noisyDelta[i] = noisyVal.clamp(0, 255);
    }

    // Account for spent budget and persist
    _cumulativeEpsilon += epsilonPerRound;
    _saveBudget();

    return noisyDelta;
  }

  Future<void> resetPrivacyBudget() async {
    _cumulativeEpsilon = 0.0;
    await _saveBudget();
  }
}
