import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'momo_ui/theme/momo_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'di/bindings.dart';

/// BabyMomo — Root Application Widget.
///
/// Configures GetMaterialApp with MOMO theme, routing, and global bindings.
class BabyMomoApp extends StatelessWidget {
  const BabyMomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BabyMomo',
      debugShowCheckedModeBanner: false,
      theme: MomoTheme.dark,
      darkTheme: MomoTheme.dark,
      themeMode: ThemeMode.dark,
      initialBinding: GlobalBindings(),
      initialRoute: AppRoutes.onboarding,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

