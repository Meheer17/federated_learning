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
  String? _serverPublicKey;

  String get deviceId => _deviceId ??= const Uuid().v4();
  String get serverPublicKey => _serverPublicKey ?? 'FEDCHAT_SERVER_PUBLIC_KEY_X25519_2026';

  /// Check user opt-in consent before participating
  Future<bool> isConsentGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.flConsentKey) ?? false;
  }

  /// Set user opt-in consent state
  Future<void> setConsent(bool optIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.flConsentKey, optIn);
  }

  /// Register device anonymously with FL server
  Future<bool> registerDevice({String? serverUrl}) async {
    try {
      final baseUrl = serverUrl ?? AppConstants.defaultFlServerUrl;
      final response = await _dio.post('$baseUrl/devices/register', data: {
        'device_id': deviceId,
        'public_key': 'FEDCHAT_PUBKEY_$deviceId',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['server_public_key'] != null) {
          _serverPublicKey = response.data['server_public_key'];
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get active FL round details
  Future<Map<String, dynamic>?> getCurrentRound({String? serverUrl}) async {
    try {
      final baseUrl = serverUrl ?? AppConstants.defaultFlServerUrl;
      final response = await _dio.get('$baseUrl/rounds/current');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
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
      final encryptedBlob = CryptoService.encryptDelta(noisyDelta, serverPublicKey);

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
