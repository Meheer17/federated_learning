import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../app/constants.dart';
import 'adapter_manager.dart';
import 'crypto_service.dart';
import 'privacy_guard.dart';

class FederatedClient {
  final Dio _dio = Dio();
  final PrivacyGuard _privacyGuard = PrivacyGuard();
  final AdapterManager _adapterManager = AdapterManager();

  String? _deviceId;
  String get deviceId => _deviceId ??= const Uuid().v4();

  /// Check user opt-in consent before participating
  Future<bool> isConsentGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.flConsentKey) ?? false;
  }

  /// Register device anonymously with FL server
  Future<bool> registerDevice({String? serverUrl}) async {
    try {
      final url = '${serverUrl ?? AppConstants.defaultFlServerUrl}/devices/register';
      final response = await _dio.post(url, data: {
        'device_id': deviceId,
        'public_key': 'FEDCHAT_PUBKEY_$deviceId',
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Participate in an active FL round
  Future<bool> participateInRound({
    required String roundId,
    required Uint8List localAdapterWeights,
    required Uint8List baselineWeights,
    String? serverUrl,
  }) async {
    final consent = await isConsentGiven();
    if (!consent) {
      return false;
    }

    if (_privacyGuard.isBudgetExhausted) {
      return false;
    }

    try {
      // 1. Compute weight delta (local - baseline)
      final rawDelta = await _adapterManager.computeAdapterDelta(localAdapterWeights, baselineWeights);

      // 2. Apply Differential Privacy (L2 Clip + Gaussian Noise)
      final noisyDelta = _privacyGuard.applyDifferentialPrivacy(rawDelta);

      // 3. Encrypt noisy delta with server public key
      final encryptedBlob = CryptoService.encryptDelta(noisyDelta, 'SERVER_PUB_KEY_SECRET');

      // 4. Submit encrypted blob to FL server endpoint
      final baseUrl = serverUrl ?? AppConstants.defaultFlServerUrl;
      final response = await _dio.post(
        '$baseUrl/rounds/$roundId/submit',
        data: {
          'device_id': deviceId,
          'dataset_size': 50,
          'encrypted_blob': encryptedBlob.toList(),
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
