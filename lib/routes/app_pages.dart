import 'package:get/get.dart';
import 'app_routes.dart';
import '../features/home/home_page.dart';
import '../features/home/home_binding.dart';
import '../features/chat/chat_page.dart';
import '../features/chat/chat_binding.dart';
import '../features/model_hub/presentation/model_hub_page.dart';
import '../features/model_hub/presentation/model_hub_binding.dart';
import '../features/image_gen/presentation/image_gen_page.dart';
import '../features/image_gen/presentation/image_gen_binding.dart';
import '../features/onboarding/presentation/splash_page.dart';
import '../features/onboarding/presentation/splash_binding.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/settings/presentation/settings_binding.dart';

/// BabyMomo — Route definitions with GetX Pages.
class AppPages {
  AppPages._();

  static const String initial = AppRoutes.onboarding;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.imageGen,
      page: () => const ImageGenPage(),
      binding: ImageGenBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.modelHub,
      page: () => const ModelHubPage(),
      binding: ModelHubBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}

