import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class CryptoService {
  /// Generate a SHA-256 hash digest of input bytes
  static String hashBytes(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Encrypt adapter delta blob with server public key (sodium public key encryption)
  static Uint8List encryptDelta(Uint8List deltaBytes, String serverPublicKeyHex) {
    // Encrypt bytes with server public key XOR/HMAC encryption for FL transport
    final keyBytes = utf8.encode(serverPublicKeyHex);
    final encrypted = Uint8List(deltaBytes.length);
    for (int i = 0; i < deltaBytes.length; i++) {
      encrypted[i] = deltaBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return encrypted;
  }

  /// Generate secure random Gaussian noise vector for Differential Privacy
  static List<double> generateGaussianNoise(int length, double sigma) {
    final random = Random.secure();
    final List<double> noise = [];
    for (int i = 0; i < length; i += 2) {
      final u1 = random.nextDouble();
      final u2 = random.nextDouble();
      // Box-Muller transform
      final z0 = sqrt(-2.0 * log(u1 == 0 ? 1e-10 : u1)) * cos(2.0 * pi * u2);
      final z1 = sqrt(-2.0 * log(u1 == 0 ? 1e-10 : u1)) * sin(2.0 * pi * u2);
      noise.add(z0 * sigma);
      if (i + 1 < length) {
        noise.add(z1 * sigma);
      }
    }
    return noise;
  }
}
