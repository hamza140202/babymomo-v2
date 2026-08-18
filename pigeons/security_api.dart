import 'package:pigeon/pigeon.dart';

/// Pigeon API — Security Bridge.
///
/// Type-safe bridge for secure hardware key storage via Android Keystore
/// and background coroutine-powered cryptographic file hashing.
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/momo_core/bridge/security_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/momoai/babymomo/pigeon/security/SecurityApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.momoai.babymomo.pigeon.security'),
))

/// Request parameters for native file integrity verification.
class NativeHashRequest {
  final String filePath;
  final String expectedHash;

  NativeHashRequest({
    required this.filePath,
    required this.expectedHash,
  });
}

/// Native file hash verification result.
class NativeHashResponse {
  final String hash;
  final bool match;
  final bool success;
  final String? errorMessage;

  NativeHashResponse({
    required this.hash,
    required this.match,
    required this.success,
    this.errorMessage,
  });
}

/// Flutter → Native: Security Host API calls.
@HostApi()
abstract class SecurityHostApi {
  /// Get or create the master AES-wrapped database encryption key from Android Keystore.
  @async
  String getOrCreateSecureKey();

  /// Wipes all secure keys and local shared preferences for security reset.
  @async
  void wipeSecureStorage();

  /// Compute the SHA-256 hash of a file on a background native thread.
  @async
  NativeHashResponse computeAndVerifySHA256(NativeHashRequest request);
}

/// Native → Flutter: Hashing progress callbacks.
@FlutterApi()
abstract class SecurityFlutterApi {
  /// Streamed progress callback for background file hashing.
  void onHashProgress(String filePath, double progress);
}
