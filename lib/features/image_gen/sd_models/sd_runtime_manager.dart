import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

enum SdRuntimeStatus { notDownloaded, downloading, ready, loading, failed }

/// Manages the libmomoimagegen.so runtime library lifecycle.
/// The .so is downloaded dynamically to keep the base APK size small.
class SdRuntimeManager extends GetxController {
  static const _sdChannel = MethodChannel('com.momoai.babymomo/sd_inference');

  // UPDATE THIS URL TO YOUR REAL HOSTED URL (e.g. HuggingFace / GitHub Releases)
  static const String _runtimeDownloadUrl =
      'https://huggingface.co/datasets/Nick021402/mimoimagegen/resolve/main/libmomoimagegen.so?download=true';

  // Local development fallback for emulator to test offline run directly
  static const String _localDebugUrl = 'http://10.0.2.2:8080/libmomoimagegen.so';

  final Rx<SdRuntimeStatus> status = SdRuntimeStatus.notDownloaded.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString downloadSpeed = ''.obs;
  final RxBool isLoaded = false.obs;
  final RxnString errorMessage = RxnString();

  final _dio = Dio();

  @override
  void onInit() {
    super.onInit();
    _checkAndLoadRuntime();
  }

  /// Returns path where the .so is stored.
  Future<String> get _runtimePath async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/sd_runtime/libmomoimagegen.so';
  }

  Future<void> _checkAndLoadRuntime() async {
    final path = await _runtimePath;
    if (File(path).existsSync()) {
      await _loadRuntime(path);
    } else {
      // Auto-trigger download on first launch instead of waiting for user!
      await downloadRuntime();
    }
  }

  Future<void> _loadRuntime(String soPath) async {
    status.value = SdRuntimeStatus.loading;
    try {
      final result = await _sdChannel.invokeMethod<bool>('initRuntime', {'soPath': soPath});
      if (result == true) {
        isLoaded.value = true;
        status.value = SdRuntimeStatus.ready;
      } else {
        status.value = SdRuntimeStatus.failed;
        errorMessage.value = 'Runtime load returned false';
      }
    } catch (e) {
      status.value = SdRuntimeStatus.failed;
      errorMessage.value = e.toString();
    }
  }

  Future<void> downloadRuntime() async {
    if (status.value == SdRuntimeStatus.downloading) return;

    final path = await _runtimePath;
    final dir = Directory(File(path).parent.path);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    status.value = SdRuntimeStatus.downloading;
    downloadProgress.value = 0.0;
    errorMessage.value = null;

    try {
      String downloadUrl = _runtimeDownloadUrl;

      // Probe local host server on Android emulator
      try {
        final probeResponse = await _dio.get(
          _localDebugUrl,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Range': 'bytes=0-0'}, // request 1 byte to check server and file
            receiveTimeout: const Duration(seconds: 1),
            sendTimeout: const Duration(seconds: 1),
          ),
        );
        if (probeResponse.statusCode == 200 || probeResponse.statusCode == 206) {
          downloadUrl = _localDebugUrl;
          debugPrint("SdRuntimeManager: Local server found! Downloading from: $downloadUrl");
        }
      } catch (_) {
        debugPrint("SdRuntimeManager: Local server not reachable, using standard URL: $downloadUrl");
      }

      await _dio.download(
        downloadUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = received / total;
          }
        },
        options: Options(receiveTimeout: const Duration(minutes: 30)),
      );

      await _loadRuntime(path);
    } on DioException catch (e) {
      status.value = SdRuntimeStatus.failed;
      errorMessage.value = e.message ?? 'Download failed. Ensure URL is valid.';
      // Clean up partial file
      try { File(path).deleteSync(); } catch (_) {}
    } catch (e) {
      status.value = SdRuntimeStatus.failed;
      errorMessage.value = e.toString();
    }
  }

  Future<void> deleteRuntime() async {
    final path = await _runtimePath;
    try {
      File(path).deleteSync();
    } catch (_) {}
    isLoaded.value = false;
    status.value = SdRuntimeStatus.notDownloaded;
    downloadProgress.value = 0.0;
    await _sdChannel.invokeMethod('clearRuntime').catchError((_) {});
  }

  /// Human-readable size string for progress display
  String get progressLabel {
    final pct = (downloadProgress.value * 100).toInt();
    return '$pct% (~93 MB runtime)';
  }
}
