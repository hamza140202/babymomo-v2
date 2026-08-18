import 'package:get/get.dart';
import 'home_controller.dart';
import '../chat/chat_controller.dart';
import '../image_gen/presentation/image_gen_controller.dart';
import '../model_hub/presentation/model_hub_controller.dart';
import '../settings/presentation/settings_controller.dart';

/// BabyMomo — Home Binding.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ChatController>(() => ChatController());
    Get.lazyPut<ImageGenController>(() => ImageGenController());
    Get.lazyPut<ModelHubController>(() => ModelHubController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

