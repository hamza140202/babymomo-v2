import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'momo_ui/theme/momo_theme.dart';
import 'features/splash/momo_wink_splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BabymomoApp());
}

class BabymomoApp extends StatelessWidget {
  const BabymomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Babymomo',
      debugShowCheckedModeBanner: false,
      theme: MomoTheme.darkTheme,
      home: const MomoWinkSplashScreen(),
    );
  }
}
