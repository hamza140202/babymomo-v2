import 'package:get/get.dart';
import 'dart:async';
import '../../../momo_core/momo_core.dart';
import '../../../routes/app_routes.dart';


class SplashController extends GetxController {
  final initProgress = 0.0.obs;
  final statusText = "Waking up Momo...".obs;

  @override
  void onInit() {
    super.onInit();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final startTime = DateTime.now();

    try {
      // 1. Initialize Hive Storage
      statusText.value = "Unpacking brain memory...";
      initProgress.value = 0.2;
      final storage = Get.find<StorageService>() as HiveStorageImpl;
      await storage.init();

      // 2. Initialize Device Engine (native hardware profiling)
      statusText.value = "Calibrating synaptic nodes...";
      initProgress.value = 0.6;
      final deviceEngine = Get.find<DeviceEngine>();
      await deviceEngine.init();

      // 3. Finalizing setup
      statusText.value = "Ready to play! ✨";
      initProgress.value = 1.0;
    } catch (e) {
      statusText.value = "Synaptic glitch detected! Retrying...";
      // Safe fallback in case of native channel issue
    }

    // Enforce a minimum display duration of 2.5 seconds to build tycoon immersion
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(milliseconds: 2600) - elapsed;
    
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    // Transition smoothly with a fade effect to Home tab shell
    Get.offAllNamed(AppRoutes.home);
  }
}
