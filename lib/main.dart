import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'momo_core/storage/storage_service.dart';
import 'momo_core/storage/hive_storage_impl.dart';
import 'momo_core/device/device_engine.dart';
import 'momo_core/security/security_engine.dart';
import 'app.dart';

/// BabyMomo — App Entry Point.
///
/// Initializes core services before rendering UI.
/// Order matters: Security → Storage → Device → UI.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for consistent mobile UX
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (cinematic dark)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Pre-register services synchronously so they are available immediately.
  // Async initializations are managed by SplashController in the background.
  Get.put<SecurityEngine>(SecurityEngine(), permanent: true);
  Get.put<StorageService>(HiveStorageImpl(), permanent: true);
  Get.put<DeviceEngine>(DeviceEngine(), permanent: true);

  runApp(const BabyMomoApp());
}

