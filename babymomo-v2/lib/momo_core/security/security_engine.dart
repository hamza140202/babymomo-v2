import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import '../bridge/security_api.g.dart';

/// MOMO Core — Security Engine.
///
/// Handles database encryption key extraction via Android Keystore wrapping,
/// native coroutine SHA-256 integrity checks, and real-time hashing telemetry.
class SecurityEngine extends GetxService implements SecurityFlutterApi {
  final _hostApi = SecurityHostApi();

  /// Reactive map hosting file path to hashing progress percentage (0.0 to 1.0)
  final RxMap<String, double> hashProgress = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Register callback channel for background progress events from Kotlin
    SecurityFlutterApi.setUp(this);
  }

  @override
  void onHashProgress(String filePath, double progress) {
    hashProgress[filePath] = progress;
  }

  /// Get encryption key for Hive box encryption.
  /// Decodes a master-wrapped AES key retrieved dynamically from secure hardware.
  Future<List<int>> getEncryptionKey() async {
    try {
      final base64Key = await _hostApi.getOrCreateSecureKey();
      return base64.decode(base64Key);
    } catch (e) {
      // Enforce "Strict Secure Fail" policy: crash startup on KeyStore failure
      throw Exception("SecureStorageException: Cryptographic KeyStore extraction failed. App startup halted. Details: $e");
    }
  }

  /// Wipes all secure keys and local shared preferences for security reset.
  Future<void> wipeSecureStorage() async {
    try {
      await _hostApi.wipeSecureStorage();
      hashProgress.clear();
    } catch (e) {
      // Log or handle gracefully since this is a destructive reset command
    }
  }

  /// Validate model file integrity via native SHA-256.
  /// Offloads computation entirely to a background thread.
  Future<bool> validateModelHash(String filePath, String expectedHash) async {
    try {
      hashProgress[filePath] = 0.0;
      final request = NativeHashRequest(
        filePath: filePath,
        expectedHash: expectedHash,
      );
      final response = await _hostApi.computeAndVerifySHA256(request);
      
      if (response.success && response.match) {
        hashProgress[filePath] = 1.0;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

