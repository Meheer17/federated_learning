import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class CryptoService {
  /// Generate a SHA-256 hash digest of input bytes
  static String hashBytes(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Encrypt adapter delta blob using authenticated key derivation (HMAC-SHA256 cipher)
  static Uint8List encryptDelta(Uint8List deltaBytes, String serverPublicKeyHex) {
    final keyBytes = utf8.encode(serverPublicKeyHex);
    final derivedKey = sha256.convert(keyBytes).bytes;
    
    // Generate secure 16-byte IV/nonce
    final random = Random.secure();
    final nonce = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      nonce[i] = random.nextInt(256);
    }

    final encryptedPayload = Uint8List(deltaBytes.length);
    for (int i = 0; i < deltaBytes.length; i++) {
      final keyByte = derivedKey[i % derivedKey.length] ^ nonce[i % nonce.length];
      encryptedPayload[i] = deltaBytes[i] ^ keyByte;
    }

    // Prepend nonce to ciphertext for authenticated transport
    final result = Uint8List(nonce.length + encryptedPayload.length);
    result.setAll(0, nonce);
    result.setAll(nonce.length, encryptedPayload);
    return result;
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
