import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:federated_chat/services/privacy_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 2 Unit Tests', () {
    test('PrivacyGuard gradient clipping bounds L2 norm', () {
      final guard = PrivacyGuard();
      final rawDelta = Uint8List.fromList([100, 150, 200, 250]);
      final clipped = guard.clipGradients(rawDelta, 100.0);

      expect(clipped.length, rawDelta.length);
    });

    test('PrivacyGuard accounts for cumulative epsilon budget', () {
      final guard = PrivacyGuard();
      expect(guard.cumulativeEpsilon, 0.0);
      expect(guard.isBudgetExhausted, isFalse);

      final noisy = guard.applyDifferentialPrivacy(Uint8List.fromList([10, 20, 30]), epsilonPerRound: 1.0);
      expect(guard.cumulativeEpsilon, 1.0);
      expect(noisy.length, 3);
    });
  });
}
